# unsere eigenen Python Module:
# Diese Module dienen als Schnittstellen zu Benutzern, die eigene Algorithmen implementieren wollen:
import MyPathLib
import MySpeedLib
# Funktionen dieser Module haben wir ausgelagert, sodass innerhalb des Hauptprogramms nur Verkehrssystemspezifische Objekte definiert werden:
import MyEvalLib
import MyJsonLib

# weitere Module:
import random
import json
import time
import itertools
import numpy

# Systemmodule:
import pathlib
import traceback
import sys


# Alle Variablen des folgenden Programms werden mit ihrem Wert in der dazugehörigen SI-Einheit gespeichert.

program_time0 = time.time()


class Network:
    def __init__(self):
        self.GUI2_car_count = 0
        # initiiere alle Variablen, die zur Weitergabe der JSON der Simulation benötigt werden:
        MyJsonLib.init_json_vars_network(self)
        # initiiere alle Variablen, die zur Auswertung der Simulation benötigt werden:
        MyEvalLib.init_eval_vars_network(self)
        # zentraler Speicherort aller aktuell fahrenden Autos:
        self.cars = []
        # Die Daten aus der JSON der GUI 1 werden hier importiert:
        with open(GUI1_json, 'r') as f:
            self.input = json.load(f)
            # Anzahl der Kanten im Netzwerk (zur Vergabe des Keys für Kanten), Liste aller Kreuzungen, Liste aller geschlossenen Kreuzungen:
            self.edge_count = 0
            self.vertices = []
            self.closed_vertices = []
            # Breite von Kreuzungen des Netzwerks und die Länge eines Frames der Simulation:
            self.intersection_width = 8
            self.dt = 0.04
            # Einlesung von Be-/Entschleunigung der Autos, die Geschwindigkeit der Fahrstühle, der Mindestabstand zweier Autos, die Simulationslänge, der gewählte Weg-/Geschwindigkeitsalgorithmus:
            self.max_acc = round(self.input["maxAcc"], 2)
            self.max_deacc = round(self.input["maxDeacc"], 2)
            self.elevator_speed = round(self.input["elevatorSpeed"], 2)
            self.safety_dist = round(self.input["safetyDist"], 2)
            self.sim_duration = round(self.input["simDuration"], 2)
            self.path_algorithm = self.input["pathAlg"]
            self.speed_algorithm = self.input["speedAlg"]
            # Hier wird der später genutze Wegalgorithmus gesetzt:
            MyPathLib.set_algorithm(self.path_algorithm)
            # Hier wird der später genutzte Geschwindigkeitsalgorithmus gesetzt:
            MySpeedLib.set_algorithm(self.speed_algorithm)
            # Die Anzahl der Kreuzungen und eine (bisher leere) Liste, die für jeden Punkt speichert, wie hoch die Wahrscheinlichkeit ist, dass ein gespawntes Auto zu ihm Fährt.
            self.intersection_count = len(self.input['Elevators'])
            self.target_probabilities = []
            for vertex_info in self.input['Elevators']:
                Vertex(self, (vertex_info['x'], vertex_info['z'], vertex_info['y']))
                self.target_probabilities += [vertex_info["spawnRateOut"]]
            # Elemente von target_probabilities werden mit einem Faktor multipliziert ~> Summe = 1
            self.target_probabilities_sum = numpy.sum(self.target_probabilities)
            for i in range(len(self.target_probabilities)):
                self.target_probabilities[i] /= self.target_probabilities_sum
            # Tunnel werden initiiert:
            for edge in self.input['Tunnels']:
                Edge(self, self.vertices[edge['elev1']], self.vertices[edge['elev2']], speed = edge['vmax'])
            # Fahrstühle werden mit ihrer Spawnrate initiiert:
            for vertex in self.vertices[:self.intersection_count]:
                vertex.add_elevator(self.input['Elevators'][vertex.key]["spawnRateIn"])
        # GUI2 überprüft permanent den Status von "Error".
        # Falls "Error" != "loading" wird sie ausgeführt.
        MyJsonLib.dump_error(GUI2_json, "loading")
        # teste, ob der gerichtete Verkehrsgraph stark zusammenhängend ist:
        if MyPathLib.test_connectivity(self) == False:
            MyJsonLib.dump_error(GUI2_json, "Das gegebene Verkehrsnetzwerk ist nicht stark zusammenhängend.")
            sys.exit()
        for vertex in self.vertices:
            MySpeedLib.initialize_vertex(vertex)
        # wird in jeder Warteschlange des Programmes genutzt, sodass es zu keinen comparison errors kommt:
        self.c = itertools.count()
        
    # Funktion zum spawnen von neuen Autos
    def spawn_cars(self):
        # spawnt an jedem Punkt des Netzwerks ein neues Auto mit Wahrscheinlichkeit source_density*dt/60
        for source in self.vertices:
            if random.random() <= source.source_density*self.dt/60:
                # mittels numpy.random.choice(list, p = weight_list) wird eine gewichtete Zufahlszahl zurückgegeben
                target_key = numpy.random.choice([i for i in range(len(self.target_probabilities))], p = self.target_probabilities)
                if source.key != target_key + self.intersection_count:
                    # Löschung der Autos mit Ziel = source
                    Car(self, source, self.vertices[target_key+self.intersection_count])

    # Funktion zum bewegen aller aktiven Autos
    def move_cars(self):
        # es wird zunächst durch alle Punkte durchgelooped, sodass sich die vorderen Autos der Warteschlange zuerst bewegen:
        for vertex in self.vertices:
            for car_l in vertex.intersection_queue:
                car = car_l[2]
                car.loop()

    # Funktion zur Wiederöffnung geschlossener Punkte
    def continue_vertices(self):
        # durchlaufe alle geschlossenen Punkte:
        for vertex in self.closed_vertices:
            # öffne alle Punkte, deren vertex_closed Zeit <= der aktuellen Simulationszeit ist:
            if vertex.closed <= self.sim_time:
                vertex.closed = False
                self.closed_vertices.remove(vertex)

    # Funktion zur Simulation eines Frames
    def loop(self):
        # Wiederöffnung der Punkte, Spawnen/Bewegung von Autos:
        self.continue_vertices()
        self.spawn_cars()
        self.move_cars()

    # Funktion zum laufen einer Simulation
    def run_sim(self):
        self.sim_time = 0
        # simuliere Autos im Verkehrsnetzwerk bis die Simulationszeit erreicht wird:
        while self.sim_time <= self.sim_duration:
            self.sim_time += self.dt
            self.loop()
        # abrufen und speichern der gesamten Daten aller noch aktiven Autos
        for car in self.cars:
            if car.GUI2_data["key"] != None:
                MyJsonLib.fetch_json_car(self, car)
                MyEvalLib.fetch_eval_car_all(self, car)
        # erstelle Grafik zur Auswertung der Animation, speichere JSON Daten des Netzwerks in data_exchange.json
        MyEvalLib.evaluate_sim(self, GUI2_png)
        MyEvalLib.print_evaluations(self)
        MyJsonLib.dump_sim(self, GUI2_json)
        

# Dies ist die Klasse für Punkte im Verkehrsnetzwerksgraphen also den Kreuzungen.
class Vertex:
    # Hier wird die Kreuzung initiiert.
    def __init__(self, network, pos, source_density = 0):
        self.key = len(network.vertices)
        self.network = network
        self.pos = pos
        self.source_density = source_density
        
        self.network.vertices.append(self)
        # Warteschlange, in der während der Simulation alle Autos, die zur Kreuzung hinfahren gespeichert werden.
        self.intersection_queue = []
        # Dictionaries zur Speicherung der Kanten, die zum Punkt hin- bzw. von ihm wegführen. (Key: edge.key)
        self.pred_edges = {}
        self.succ_edges = {}
    
    # Diese Funktion fügt einen Fahrstuhl zu diesem Punkt zum Verkehrsnetzwerk hinzu.
    def add_elevator(self, source_density):
        x, y, _ = self.pos
        self.elevator_exit = Vertex(self.network, (x, y, 0), source_density)
        Edge(self.network, self, self.elevator_exit, elevator = True)
        Edge(self.network, self.elevator_exit, self, elevator = True)
        

# Dies ist die Klasse für Kanten im Verkehrsnetzwerksgraphen also den Tunneln und Fahrstühlen.
class Edge:
    # Hier wird der Tunnel/Farhstuh initiiert.
    def __init__(self, network, source, target, speed = 0, elevator = False):
        # Genau dann wenn die elevator Variable true ist, wird die Kante als Fahrstuhl erstellt.
        self.key = network.edge_count
        self.network = network
        self.source = source
        self.target = target
        if elevator == False:
            self.max_speed = speed
        else:
            self.max_speed = self.network.elevator_speed
        # Fahrstuhl? Länge der Kante
        self.elevator = elevator
        self.length = numpy.linalg.norm(numpy.array(self.source.pos)-numpy.array(self.target.pos))
        self.car_capacity = self.length//self.network.safety_dist
        # fügt sich selbst zu ein-/ausgehenden Kanten des Starts/Ziel hinzu und inkrementiere die Anzahl der Kanten:
        target.pred_edges[source] = self
        source.succ_edges[target] = self
        self.network.edge_count += 1
        # Hier werden während der Simulation alle Autos, die aktuell in diesem Tunnel sind gespeichert:
        self.tunnel = []
        # Um sicher zu stellen, dass in jedem Tunnel mindestens zwei Autos gleichzeitig stehen zu können, wird dieser Test gemacht:
        if self.elevator == False and self.length <= 2*self.network.safety_dist:
            with open(GUI2_json, 'w') as f:
                error = {"Error": "Aus Sicherheitsgründen muss jeder Tunnel länger als 2*Safety distance sein."}
                json.dump(error, f)
            sys.exit()
        MySpeedLib.initialize_edge(self)


class Car:
    # definiert durch Verkehrsnetzwerk, Spawnpunkt, Zielpunkt:
    def __init__(self, network, source, target):
        self.can_start = False
        # Key des Autos:
        self.key = network.car_count_spawned
        # Verkehrssystem:
        self.network = network
        # Messung des Spawnzeitpunktes:
        self.spawn_time = self.network.sim_time
        # Hinzufügung zur Liste aktiver Autos:
        self.network.cars.append(self)
        # Inkrementierung der Anzahl gespawnter Autos:
        self.network.car_count_spawned += 1
        # Berechnung des Weges des Autos in der Form [Objekt(1. Punkt), Objekt(2. Punkt), ..., Objekt(Ziel)]:
        self.path = MyPathLib.find_path(network, source, target)
        # Anzahl erreichter Kreuzungen aus dem Weg:
        self.path_progress = 1
        # Endpunkt der aktuellen Kante:
        self.next_vertex = self.path[1]
        # aktuelle Kante:
        self.edge = source.succ_edges[self.next_vertex]
        # nächste Kante auf dem Weg:
        self.next_edge = self.next_vertex.succ_edges[self.path[2]]
        # Entfernung Auto <-> nächste Ecke in m:
        self.edge_progress = self.edge.length
        # Liste aller Autos auf der aktuellen Kante:
        self.edge.tunnel.append(self)
        # Platz in der Warteschlange:
        self.prio = len(self.next_vertex.intersection_queue)
        # Wenn das Auto an eine Kreuzung steht, zählt diese Variable, wie lange das Auto schon wartet:
        self.wait_time = 0
        # setze Auto auf Warteschlange aller Autos auf Kanten, welche zur next_vertex hinführen:
        self.next_vertex.intersection_queue.append([MySpeedLib.get_heap_key(self), next(self.network.c), self])
        # Geschwindigkeit des Autos
        self.speed = 0
        # 1 <=> Auto beschleunigt, -1 <=> Auto bremst
        self.acceleration = -1
        self.last_refresh = self.spawn_time
        # Jedes Auto wird mit diesen 3 Eigenschaften später in einer JSON-Datei gespeichert.
        # Dessen Daten werden in der GUI ausgelesen. 
        self.GUI2_data = {"key": None, "spawnTime": None, "route": [vertex.key for vertex in self.path[1:-1]], "checkpoints": [], "accel":[]}

    # Funktion zum setzen der Geschwindigkeit des Autos in diesem Frame
    def set_speed(self):
        # ermittle, ob das Auto be-/entschleuingt:
        self.new_acceleration = MySpeedLib.get_acceleration(self)
        # falls sich die Beschleunigung in diesem Frame ändert, speichere dies in der JSON data des Autos:
        if self.acceleration != self.new_acceleration:
            self.GUI2_data['accel'].append(round(self.network.sim_time,4))
        self.acceleration = self.new_acceleration
        # setze die Geschwindigkeit im nächsten Frame:
        if self.acceleration == 1:
            self.speed = min(self.edge.max_speed, round(self.speed+self.network.max_acc*self.network.dt, 4))
        else:
            self.speed = max(0, round(self.speed-self.network.max_deacc*self.network.dt, 4))

    # Funktion zum bewegen des Autos
    def move(self):
        if self.edge_progress <= self.network.dt*self.speed:
            self.transfer()
        else:
            self.edge_progress -= self.network.dt*self.speed

    # Funktion zum Datenmanagement an Kreuzungen
    def transfer(self):
        self.leave_edge()
        if self.path_progress == len(self.path)-1:
            self.arrive()
        else:
            self.enter_edge()
    
    # Funktion zum verlassen des aktuellen Tunnels
    def leave_edge(self):
        # entferne das Auto aus der Warteschlange der Kreuzung:
        for i, car_l in enumerate(self.next_vertex.intersection_queue):
            if car_l[2] == self:
                del self.next_vertex.intersection_queue[i]
        # entferne das Auto aus seinem aktuellen Tunnel:
        self.edge.tunnel.remove(self)
        # sortiere die Warteschlange der aktuellen Kreuzung:
        MySpeedLib.leave_edge(self)

    # Funktion zum befahren eines neuen Tunnels
    def enter_edge(self):
        # die Geschwindigeit wird beim betreten/verlassen eines Tunnels nicht beibehalten:
        if self.path_progress in [1, len(self.path)-2]:
            self.speed = 0
        # inkrementiere den Wegfortschritt:
        self.path_progress += 1
        # setze neue nächste Krezung, aktuelle Kante, nächste Kante:
        self.next_vertex = self.path[self.path_progress]
        self.edge = self.path[self.path_progress-1].succ_edges[self.next_vertex]
        if self.path_progress == len(self.path)-1:
            self.next_edge = None
        else:
            self.next_edge = self.next_vertex.succ_edges[self.path[self.path_progress+1]]
        # setze den Kantenfortschritt auf deren Länge:
        self.edge_progress = self.edge.length
        # füge das Auto seinem Tunnel hinzu:
        self.edge.tunnel.append(self)
        # füge das Auto der neuen Warteschlange mit seinem neuen heap_key hinzu:
        MySpeedLib.enter_edge(self)

    # Funktion zum ankommen eines Autos
    def arrive(self):
        # inkrementiere die Anzahl angekommener Autos:
        self.network.car_count_arrived += 1
        # füge die Daten des Autos den entsprechenden Auswertungselementen hinzu:
        MyJsonLib.fetch_json_car(self.network, self)
        MyEvalLib.fetch_eval_car_all(self.network, self)
        MyEvalLib.fetch_eval_car_arrived(self.network, self)
        # entferne das Auto aus der Autoliste:
        self.network.cars.remove(self)
        # lösche das Auto
        del self
    
    # Funktion zum setzten eines Checkpoints in der JSON data des Autos
    def checkpoint(self):
        self.GUI2_data["checkpoints"].append([round(self.network.sim_time, 4), self.path_progress - 1, (self.edge.length-self.edge_progress)/self.edge.length, self.speed, self.acceleration])
    
    # Funktion zur Simulation des Autos für einen Frame
    def loop(self):
        if self.can_start == False and (not self.edge.tunnel or self.edge.length != self.edge.tunnel[self.edge.tunnel.index(self)-1]):
            self.can_start = True
            self.GUI2_data["spawnTime"] = self.network.sim_time
            self.GUI2_data["key"] = self.network.GUI2_car_count
            self.network.GUI2_car_count += 1
        else:
            self.set_speed()
            self.move()
            self.refresh_rate = (self.speed+0.001)/2
            if self.network.sim_time >= self.last_refresh + 1/self.refresh_rate:
                self.checkpoint()
                self.last_refresh = self.network.sim_time


try:
    GUI1_json = pathlib.Path(__file__).parent.parent / 'GUI1' / 'data_input.json'
    GUI2_json = pathlib.Path(__file__).parent.parent / 'GUI2' / 'data_exchange.json'
    GUI2_png = pathlib.Path(__file__).parent.parent / 'GUI2' / 'evaluation.png'
    Net = Network()
    Net.run_sim()
except:
    error = traceback.format_exc()
    MyJsonLib.dump_error(GUI2_json, error)
    print(error)

print('\n---------------------------------------------')
print('--- program duration:', time.time()-program_time0, ' ---')
print('---------------------------------------------\n')