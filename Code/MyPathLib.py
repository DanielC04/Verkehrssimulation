import sys
from heapq import heappush, heappop
import itertools
import numpy

# Funktion zum testen, ob das Verkersnetzwerk stark zusammenhänd ist, mittels Kosajarus Algorithmus:
def test_connectivity(network):
    # Funktion, welche alle Punkte auf forward_visited setzt, die von vertex aus erreichbar sind:
    def visit_forward(vertex):
        if vertex.forward_visited == False:
            vertex.forward_visited = True
            for succ_vertex in vertex.succ_edges:
                visit_forward(succ_vertex)

    # Funktion, welche alle Punkte auf backward_visited setzt, von denen aus vertex erreichbar ist:
    def visit_backward(vertex):
        if vertex.backward_visited == False:
            vertex.backward_visited = True
            for pred_vertex in vertex.pred_edges:
                visit_backward(pred_vertex)

    # setze alle Punkte auf unentdeckt:
    for vertex in network.vertices:
        vertex.forward_visited = False
        vertex.backward_visited = False
    # setze alle Punkte, die man von dem gewählten Punkt erreichen kann auf "forward_visited"
    visit_forward(network.vertices[0])
    # setze alle Punkte, von denen man den gewählten Punkt erreichen kann auf "backward_visited"
    visit_backward(network.vertices[0])
    # gebe False zurück, falls ein Punkt nicht for- und backward_visited ist:
    for vertex in network.vertices:
        if vertex.forward_visited == False or vertex.backward_visited == False:
            return False
    # gebe sonst True zurück
    return True


# Da die drei vorprogrammierten Algorithmen abgesehen von ihren Gewichten identisch sind, ist nur der erste vollständig kommentiert.
# Wir haben anstatt des a* Algorithmus den Djikstra Algorithmus gewählt, da die Wegalgorithmen von jedem Auto nur ein Mal aufgerufen werden und deren Laufzeit deswegen zu vernachlässigen ist.
# Daher wäre es ein unnötiger Aufwand monotone Heuristiken für die späteren Algorithmen zu entwickeln.

class Find_shortest_path:
    def _find_path(self, network, source, target):
        # Variable zur eindeutigen Lexikographischen Ordnung der queue Elemente ohne den Vergleich von Objekten des types Vertex:
        c = itertools.count()
        # Warteschlange anhand des Gewichts des Weges (bei diesem Algorithmus ist weight = length)
        queue = [(0, next(c), source, 0)]
        for vertex in network.vertices:
            vertex.parent = None
            vertex.cost = None
        # Es werden so lange Wege gesucht, wie es Elemente gibt, die enqueued aber noch nicht explored wurden:
        while queue:
            # entnehme das erste Element der Warteschlange:
            cost, _, current_vertex, parent = heappop(queue)
            # Wurde der Punkt bereits erkundet?
            if current_vertex.parent != None:
                # Ist der Punkt der Startpunkt?
                continue
            # füge current_vertex mit key parent explored hinzu:
            current_vertex.parent = parent
            # falls man das Ziel entnommen hat, gebe den Weg des Autos mittels backtracking über explored zurück:
            if current_vertex == target:
                path = []
                while current_vertex != 0:
                    path.append(current_vertex)
                    current_vertex = current_vertex.parent
                path.reverse()
                return path
            # laufe durch alle Kanten, die aus current_vertex rausgehen:
            for _, succ_edge in current_vertex.succ_edges.items():
                # Endpunkt der Kante:
                succ_vertex = succ_edge.target
                # Länge des Weges über current_vertex zu succ_vertex:
                succ_cost = cost + succ_edge.length
                # Wurde schon ein kürzerer Weg zu succ_vertex gefunden?
                if succ_vertex.cost != None and succ_vertex.cost <= succ_cost:
                    continue
                succ_vertex.cost = succ_cost
                heappush(queue, (succ_cost, next(c), succ_vertex, current_vertex))
        # Da der Graph am Anfang auf starken Zusammenhang getestet wird, wird definitiv ein Weg zurückgegeben bis queue leer ist.


class Find_fastest_path:
    def _find_path(self, network, source, target):
        c = itertools.count()
        queue = [(0, next(c), source, 0)]
        for vertex in network.vertices:
            vertex.parent = None
            vertex.cost = None
        while queue:
            cost, _, current_vertex, parent = heappop(queue)
            if current_vertex.parent != None:
                continue
            current_vertex.parent = parent
            if current_vertex == target:
                path = []
                current_vertex = parent
                while current_vertex != 0:
                    path.append(current_vertex)
                    current_vertex = current_vertex.parent
                path.reverse()
                return path
            for _, succ_edge in current_vertex.succ_edges.items():
                succ_vertex = succ_edge.target
                succ_cost = cost + succ_edge.length/succ_edge.max_speed
                if succ_vertex.cost != None and succ_vertex.cost <= succ_cost:
                    continue
                succ_vertex.cost = succ_cost
                heappush(queue, (succ_cost, next(c), succ_vertex, current_vertex))


class Find_current_fast_path:
    def _find_path(self, network, source, target):
        c = itertools.count()
        queue = [(0, next(c), source, 0)]
        for vertex in network.vertices:
            vertex.parent = None
            vertex.cost = None
        while queue:
            cost, _, current_vertex, parent = heappop(queue)
            if current_vertex.parent != None:
                continue
            current_vertex.parent = parent
            if current_vertex == target:
                path = []
                current_vertex = parent
                while current_vertex != 0:
                    path.append(current_vertex)
                    current_vertex = current_vertex.parent
                path.reverse()
                return path
            for _, succ_edge in current_vertex.succ_edges.items():
                succ_vertex = succ_edge.target
                succ_cost = cost + succ_edge.length/succ_edge.max_speed+1000*numpy.heaviside(succ_edge.car_capacity-len(succ_edge.tunnel)-2, 0) + 100*numpy.heaviside(len(succ_edge.target.intersection_queue)-7, 0)
                if succ_vertex.cost != None and succ_vertex.cost <= succ_cost:
                    continue
                succ_vertex.cost = succ_cost
                heappush(queue, (succ_cost, next(c), succ_vertex, current_vertex))

algorithm = None

def set_algorithm(algorithm_name):
    # Mit dieser Funktion kann ein Wegalgorithmus für das Verkehrsnetzwerk gewählt werden.
    global algorithm
    if algorithm_name == "shortest path":
        algorithm = Find_shortest_path()
    elif algorithm_name == "fastest path":
        algorithm = Find_shortest_path()
    elif algorithm_name == "current fast path":
        algorithm = Find_current_fast_path()
    else:
        sys.exit()

def find_path(network, source, target):
    return algorithm._find_path(network, source, target)