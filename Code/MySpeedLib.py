import numpy
import sys

def _stop_dist_p(car):
    # Bremsweg, wenn das Auto im nächsten Frame noch beschleunigt:
    return (car.speed+car.network.dt*car.network.max_acc)**2/(2*car.network.max_deacc)+car.network.dt*(car.speed+car.network.dt*car.network.max_acc)

def _stop_dist_m(car):
    # Bremsweg, wenn das Auto sofort bremst:
    return (car.speed)**2/(2*car.network.max_deacc)

class One_car_priority_intersection:
    # Bei diesem Algorithmus halten alle Autos außer dem ersten aus der Warteschlange an Kreuzungen vollständig an.
    # Die Reihenfolge der Warteschlange wird jedes mal wenn das vorderste Auto die Kreuzung überquert anhand des Merkmals s die Warteschlange neu berechnet.
    def _initialize_vertex(self, vertex):
        vertex.closed = False

    def _initialize_edge(self, edge):
        pass

    def _enter_edge(self, car):
        # setze das Auto an das Ende der Warteschlange:
        car.prio = len(car.next_vertex.intersection_queue)
        car.next_vertex.intersection_queue.append([get_heap_key(car), next(car.network.c), car])

    def _get_acceleration(self, car):
        stop_dist = _stop_dist_p(car)
        car_tunnel_index = car.edge.tunnel.index(car)
        # Kann das Auto vor der Kreuzung bei maximaler Bremsung nicht halten?
        if stop_dist >= car.edge_progress-car.network.safety_dist:
            # Ist das Auto das erste in der Warteschlange der Kreuzung?
            if not car.prio:
                # Ist die Kreuzung aktuell offen?
                if not car.next_vertex.closed:
                    # Befindet sich das Auto gerade im Fahrstuhl vor dem Ziel?
                    if car.path_progress in [len(car.path)-1, len(car.path)-2]:
                        return 1
                    else:
                        # Kann das Auto bei Vollbremsung vor der übernächsten Kreuzung nicht halten?
                        if stop_dist >= car.edge_progress + car.next_edge.length - car.network.safety_dist:
                            return -1
                        # Ist der nächste Tunnel auf dem Weg des Autos leer?
                        elif not car.next_edge.tunnel:
                            return 1
                        # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto des nächsten Tunnels vollbremst?
                        elif stop_dist-car.edge_progress >= _stop_dist_m(car.next_edge.tunnel[-1])+car.next_edge.length-car.next_edge.tunnel[-1].edge_progress-car.network.safety_dist:
                            return -1
                        else:
                            return 1
                else:
                    return -1
            else:
                return -1
        else:
            # Ist das Auto das erste im Tunnel?
            if not car_tunnel_index:
                return 1
            else:
                # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto vor ihm vollbremst?
                if car.edge_progress-stop_dist <= car.edge.tunnel[car_tunnel_index-1].edge_progress-_stop_dist_m(car.edge.tunnel[car_tunnel_index-1])+car.network.safety_dist:
                    return -1
                # Hält das Auto aktuell den Sicherheitsabstand ein?
                elif car.edge_progress <= car.edge.tunnel[car_tunnel_index-1].edge_progress + car.network.safety_dist:
                    return -1
                elif car.path_progress not in [len(car.path)-2, len(car.path)-1] and len(car.next_edge.tunnel) != 0 and car.edge_progress-stop_dist+car.next_edge.length <= car.next_edge.tunnel[-1].edge_progress-_stop_dist_m(car.next_edge.tunnel[-1])+car.network.safety_dist:
                    return -1
                else:
                    return 1

    def _get_heap_key(self, car):
        # Diese Funktion gibt das Warteschlangenkriterium des Autos zurück.
        return car.edge_progress

    def _leave_edge(self, car):
        # sortiere die Warteschlange der Kreuzung neu und setze dann die Prioritäten jedes Autos:
        for x in car.next_vertex.intersection_queue:
            x[0] = self._get_heap_key(x[2])
        car.next_vertex.intersection_queue.sort()
        for i, x in enumerate(car.next_vertex.intersection_queue):
            car = x[2]
            car.prio = i
        car.edge.closed = car.network.sim_time + car.network.intersection_width/(car.speed+3)
        car.edge.network.closed_vertices.append(car.edge)
        

class Two_car_priority:
    # Bei diesem Algorithmus halten alle Autos hinter dem zweiten aus der Warteschlange an Kreuzungen vollständig an.
    # Das zweite berechnet wann das erste die Kreuzung spätestens überquert und beschleunigt anhand dieser Berechnung schon bevor das erste die Kreuzung überquert hat.
    # Die Reihenfolge der Warteschlange wird jedes mal wenn das vorderste Auto die Kreuzung überquert anhand des Merkmals s neu berechnet.
    # Dabei wird der bisher zweite in jedem Fall zum ersten in der Warteschlange.
    def _initialize_vertex(self, vertex):
        pass

    def _initialize_edge(self, edge):
        pass

    def _enter_edge(self, car):
        # setze das Auto an das Ende der Warteschlange:
        car.prio = len(car.next_vertex.intersection_queue)
        car.next_vertex.intersection_queue.append([get_heap_key(car), next(car.network.c), car])

    def _predict_intersection_speed_first(self, car):
        # Diese Funktion berechnet die minimale Geschwindigkeit, die das erste Auto der Warteschlange haben wird, wenn es an der Kreuzung vorbei ist und eine Entfernung von safety_dist zur Kreuzung hat:
        first_car = car.next_vertex.intersection_queue[0][2]
        # Ist das erste Auto der Warteschlange im Tunnel vor dem Zielfahrstuhl oder im Zielfahrstuhl?
        if first_car.path_progress in [len(first_car.path)-2, len(first_car.path)-1]:
            v_at_intersection = float("inf")
        else:
            # Ist der nächste Tunnel auf dem Weg des Autos leer?
            if not first_car.next_edge.tunnel:
                # maximale Geschwindigkeit bei der man mit Vollbremsung ab dem nächsten Punkt dem übernächsten Punkt nicht näher als safety_dist kommt:
                v_at_intersection = (2*car.network.max_deacc*(first_car.next_edge.length-car.network.safety_dist))**0.5
            else:
                # Entfernung der Kreuzung zum letzten Auto des nächsten Tunnels, falls es vollbremst:
                next_car_dist = first_car.next_edge.length-first_car.next_edge.tunnel[-1].edge_progress+_stop_dist_m(first_car.next_edge.tunnel[-1])
                # Ist diese Entfernung kleiner oder gleich dem Mindestabstand des Verkehrssystems?
                if next_car_dist <= car.network.safety_dist:
                    v_at_intersection = 0
                else:
                    v_at_intersection = (2*car.network.max_deacc*(next_car_dist-car.network.safety_dist))**0.5
        v_at_intersection = max(0, v_at_intersection)
        v_at_intersection = min(first_car.edge.max_speed, v_at_intersection)
        return v_at_intersection

    def _predict_intersection_time_first(self, car, v_target):
        # Dieses Programm gibt t bzw. T zurück. t ist der Zeitpunkt an dem das erste Auto der Warteschlange frühestens die Kreuzung erreicht und T ist der Zeitpunkt an dem die Kreuzung wieder öffnet.
        # Für diese Berechnung erhält sie das betrachtete Auto und die Mindestgeschwindigkeit, die das erste Auto an der Kreuzung haben wird.
        first_car = car.next_vertex.intersection_queue[0][2]
        if v_target > 0:
            # Ist v_target schneller als die aktuelle Geschwindigkeit des ersten Autos?
            if v_target >= first_car.speed:
                # Wird das erste Auto v_target vor der Kreuzung erreichen, wenn es voll beschleunigt?
                if (v_target**2 - first_car.speed**2)/(2*car.network.max_acc) < first_car.edge_progress:
                    v_real = v_target
                    t = ((v_target-first_car.speed)**2+2*car.network.max_acc*first_car.edge_progress)/(2*car.network.max_acc*v_target)
                else:
                    v_real = (first_car.speed**2+2*car.network.max_acc*first_car.edge_progress)**0.5
                    t = (v_real-first_car.speed)/car.network.max_acc
            else:
                # Wird das erste Auto v_target vor der Kreuzung erreichen, wenn es vollbremst?
                if (first_car.speed**2 - v_target**2)/(2*car.network.max_deacc) < first_car.edge_progress:
                    v_real = v_target
                    t = (-(first_car.speed-v_target)**2+2*car.network.max_acc*first_car.edge_progress)/(2*car.network.max_acc*v_target)
                else:
                    v_real = (first_car.speed**2-2*car.network.max_deacc*first_car.edge_progress)**0.5
                    t = (first_car.speed-v_real)/car.network.max_deacc
            return v_real, t
        else:
            return 0, float("inf")

    def _get_acceleration(self, car):
        stop_dist = _stop_dist_p(car)
        car_tunnel_index = car.edge.tunnel.index(car)
        # Kann das Auto vor der Kreuzung bei maximaler Bremsung nicht halten?
        if stop_dist >= car.edge_progress-car.network.safety_dist:
            # Ist das Auto das erste in der Warteschlange der Kreuzung?
            if not car.prio:
                # Befindet sich das Auto gerade im Fahrstuhl vor dem Ziel?
                if car.path_progress in [len(car.path)-1, len(car.path)-2]:
                    return 1
                else:
                    # Kann das Auto bei Vollbremsung vor der übernächsten Kreuzung nicht halten?
                    if stop_dist >= car.edge_progress + car.next_edge.length - car.network.safety_dist:
                        return -1
                    # Ist der nächste Tunnel auf dem Weg des Autos leer?
                    elif not car.next_edge.tunnel:
                        return 1
                    # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto des nächsten Tunnels vollbremst?
                    elif stop_dist-car.edge_progress >= _stop_dist_m(car.next_edge.tunnel[-1])+car.next_edge.length-car.next_edge.tunnel[-1].edge_progress-car.network.safety_dist:
                        return -1
                    else:
                        return 1
            # Ist das Auto das zweite der Warteschlange?
            elif car.prio == 1:
                first_car = car.next_vertex.intersection_queue[0][2]
                if car.edge == first_car.edge:
                    # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto vor ihm vollbremst?
                    if car.edge_progress-stop_dist <= first_car.edge_progress-_stop_dist_m(first_car)+car.network.safety_dist:
                        return -1
                    else:
                        return 1
                if car.path_progress not in [len(car.path)-2, len(car.path)-1]:
                    # Kann das Auto bei Vollbremsung vor der übernächsten Kreuzung nicht halten?
                    if stop_dist >= car.edge_progress + car.next_edge.length - car.network.safety_dist:
                        return -1
                # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto des nächsten Tunnels vollbremst?
                if car.next_edge != None and len(car.next_edge.tunnel) != 0 and stop_dist-car.edge_progress >= _stop_dist_m(car.next_edge.tunnel[-1])+car.next_edge.length-car.next_edge.tunnel[-1].edge_progress-car.network.safety_dist:
                    return -1
                v_target = self._predict_intersection_speed_first(car)
                v_r, t = self._predict_intersection_time_first(car, v_target)
                if car.next_edge != None and car.next_edge == first_car.next_edge and len(car.next_edge.tunnel):
                    next_car = car.next_edge.tunnel[-1]
                    if v_r**2/(2*car.network.max_deacc) >= car.next_edge.length - next_car.edge_progress+_stop_dist_m(next_car) - car.network.safety_dist:
                        if stop_dist - car.edge_progress >= v_r**2/(2*car.network.max_deacc):
                            return -1
                    if first_car.edge.elevator == True:
                        return -1
                if v_r == 0:
                    return -1
                elif ((2*car.network.max_acc*car.edge_progress+car.speed**2)**0.5-car.speed)/car.network.max_acc >= t+car.network.intersection_width/v_r:
                    return 1
                else:
                    return -1
            else:
                return -1
        else:
            # Ist das Auto das erste im Tunnel?
            if not car_tunnel_index:
                return 1
            else:
                # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto vor ihm vollbremst?
                if car.edge_progress-stop_dist <= car.edge.tunnel[car_tunnel_index-1].edge_progress-_stop_dist_m(car.edge.tunnel[car_tunnel_index-1])+car.network.safety_dist:
                    return -1
                # Hält das Auto aktuell den Sicherheitsabstand ein?
                elif car.edge_progress <= car.edge.tunnel[car_tunnel_index-1].edge_progress + car.network.safety_dist:
                    return -1
                elif car.path_progress not in [len(car.path)-2, len(car.path)-1] and len(car.next_edge.tunnel) != 0 and car.edge_progress-stop_dist+car.next_edge.length <= car.next_edge.tunnel[-1].edge_progress-_stop_dist_m(car.next_edge.tunnel[-1])+car.network.safety_dist:
                    return -1
                else:
                    return 1

    def _get_heap_key(self, car):
        # Diese Funktion gibt das Warteschlangenkriterium des Autos zurück.
        if car.prio == 1:
            return 0
        else:
            return car.edge_progress

    def _leave_edge(self, car):
        # sortiere die Warteschlange der Kreuzung neu und setze dann die Prioritäten jedes Autos:
        for x in car.next_vertex.intersection_queue:
            x[0] = self._get_heap_key(x[2])
        car.next_vertex.intersection_queue.sort()
        for i, x in enumerate(car.next_vertex.intersection_queue):
            car = x[2]
            car.prio = i


class Two_car_advanced_heap:
    # Bei diesem Algorithmus halten alle Autos hinter dem zweiten aus der Warteschlange an Kreuzungen vollständig an.
    # Das zweite berechnet wann das erste die Kreuzung spätestens überquert und beschleunigt anhand dieser Berechnung schon bevor das erste die Kreuzung überquert hat.
    # Die Reihenfolge der Warteschlange wird jedes mal wenn das vorderste Auto die Kreuzung überquert anhand des Merkmals s neu berechnet.
    # Dabei wird der bisher zweite in jedem Fall zum ersten in der Warteschlange.
    def _initialize_vertex(self, vertex):
        pass

    def _initialize_edge(self, edge):
        pass

    def _enter_edge(self, car):
        # setze das Auto an das Ende der Warteschlange:
        car.prio = len(car.next_vertex.intersection_queue)
        car.next_vertex.intersection_queue.append([get_heap_key(car), next(car.network.c), car])

    def _predict_intersection_speed_first(self, car):
        # Diese Funktion berechnet die minimale Geschwindigkeit, die das erste Auto der Warteschlange haben wird, wenn es an der Kreuzung vorbei ist und eine Entfernung von safety_dist zur Kreuzung hat:
        first_car = car.next_vertex.intersection_queue[0][2]
        # Ist das erste Auto der Warteschlange im Tunnel vor dem Zielfahrstuhl oder im Zielfahrstuhl?
        if first_car.path_progress in [len(first_car.path)-2, len(first_car.path)-1]:
            v_at_intersection = float("inf")
        else:
            # Ist der nächste Tunnel auf dem Weg des Autos leer?
            if not first_car.next_edge.tunnel:
                # maximale Geschwindigkeit bei der man mit Vollbremsung ab dem nächsten Punkt dem übernächsten Punkt nicht näher als safety_dist kommt:
                v_at_intersection = (2*car.network.max_deacc*(first_car.next_edge.length-car.network.safety_dist))**0.5
            else:
                # Entfernung der Kreuzung zum letzten Auto des nächsten Tunnels, falls es vollbremst:
                next_car_dist = first_car.next_edge.length-first_car.next_edge.tunnel[-1].edge_progress+_stop_dist_m(first_car.next_edge.tunnel[-1])
                # Ist diese Entfernung kleiner oder gleich dem Mindestabstand des Verkehrssystems?
                if next_car_dist <= car.network.safety_dist:
                    v_at_intersection = 0
                else:
                    v_at_intersection = (2*car.network.max_deacc*(next_car_dist-car.network.safety_dist))**0.5
        v_at_intersection = max(0, v_at_intersection)
        v_at_intersection = min(first_car.edge.max_speed, v_at_intersection)
        return v_at_intersection

    def _predict_intersection_time_first(self, car, v_target):
        # Dieses Programm gibt t bzw. T zurück. t ist der Zeitpunkt an dem das erste Auto der Warteschlange frühestens die Kreuzung erreicht und T ist der Zeitpunkt an dem die Kreuzung wieder öffnet.
        # Für diese Berechnung erhält sie das betrachtete Auto und die Mindestgeschwindigkeit, die das erste Auto an der Kreuzung haben wird.
        first_car = car.next_vertex.intersection_queue[0][2]
        if v_target > 0:
            # Ist v_target schneller als die aktuelle Geschwindigkeit des ersten Autos?
            if v_target >= first_car.speed:
                # Wird das erste Auto v_target vor der Kreuzung erreichen, wenn es voll beschleunigt?
                if (v_target**2 - first_car.speed**2)/(2*car.network.max_acc) < first_car.edge_progress:
                    v_real = v_target
                    t = ((v_target-first_car.speed)**2+2*car.network.max_acc*first_car.edge_progress)/(2*car.network.max_acc*v_target)
                else:
                    v_real = (first_car.speed**2+2*car.network.max_acc*first_car.edge_progress)**0.5
                    t = (v_real-first_car.speed)/car.network.max_acc
            else:
                # Wird das erste Auto v_target vor der Kreuzung erreichen, wenn es vollbremst?
                if (first_car.speed**2 - v_target**2)/(2*car.network.max_deacc) < first_car.edge_progress:
                    v_real = v_target
                    t = (-(first_car.speed-v_target)**2+2*car.network.max_acc*first_car.edge_progress)/(2*car.network.max_acc*v_target)
                else:
                    v_real = (first_car.speed**2-2*car.network.max_deacc*first_car.edge_progress)**0.5
                    t = (first_car.speed-v_real)/car.network.max_deacc
            return v_real, t
        else:
            return 0, float("inf")

    def _get_acceleration(self, car):
        stop_dist = _stop_dist_p(car)
        car_tunnel_index = car.edge.tunnel.index(car)
        # Kann das Auto vor der Kreuzung bei maximaler Bremsung nicht halten?
        if stop_dist >= car.edge_progress-car.network.safety_dist:
            # Ist das Auto das erste in der Warteschlange der Kreuzung?
            if not car.prio:
                # Befindet sich das Auto gerade im Fahrstuhl vor dem Ziel?
                if car.path_progress in [len(car.path)-1, len(car.path)-2]:
                    return 1
                else:
                    # Kann das Auto bei Vollbremsung vor der übernächsten Kreuzung nicht halten?
                    if stop_dist >= car.edge_progress + car.next_edge.length - car.network.safety_dist:
                        return -1
                    # Ist der nächste Tunnel auf dem Weg des Autos leer?
                    elif not car.next_edge.tunnel:
                        return 1
                    # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto des nächsten Tunnels vollbremst?
                    elif stop_dist-car.edge_progress >= _stop_dist_m(car.next_edge.tunnel[-1])+car.next_edge.length-car.next_edge.tunnel[-1].edge_progress-car.network.safety_dist:
                        return -1
                    else:
                        return 1
            # Ist das Auto das zweite der Warteschlange?
            elif car.prio == 1:
                first_car = car.next_vertex.intersection_queue[0][2]
                if car.edge == first_car.edge:
                    # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto vor ihm vollbremst?
                    if car.edge_progress-stop_dist <= first_car.edge_progress-_stop_dist_m(first_car)+car.network.safety_dist:
                        return -1
                    else:
                        return 1
                if car.path_progress not in [len(car.path)-2, len(car.path)-1]:
                    # Kann das Auto bei Vollbremsung vor der übernächsten Kreuzung nicht halten?
                    if stop_dist >= car.edge_progress + car.next_edge.length - car.network.safety_dist:
                        return -1
                # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto des nächsten Tunnels vollbremst?
                if car.next_edge != None and len(car.next_edge.tunnel) != 0 and stop_dist-car.edge_progress >= _stop_dist_m(car.next_edge.tunnel[-1])+car.next_edge.length-car.next_edge.tunnel[-1].edge_progress-car.network.safety_dist:
                    return -1
                v_target = self._predict_intersection_speed_first(car)
                v_r, t = self._predict_intersection_time_first(car, v_target)
                if car.next_edge != None and car.next_edge == first_car.next_edge and len(car.next_edge.tunnel):
                    next_car = car.next_edge.tunnel[-1]
                    if v_r**2/(2*car.network.max_deacc) >= car.next_edge.length - next_car.edge_progress+_stop_dist_m(next_car) - car.network.safety_dist:
                        if stop_dist - car.edge_progress >= v_r**2/(2*car.network.max_deacc):
                            return -1
                    if first_car.edge.elevator == True:
                        return -1
                if v_r == 0:
                    return -1
                elif ((2*car.network.max_acc*car.edge_progress+car.speed**2)**0.5-car.speed)/car.network.max_acc >= t+car.network.intersection_width/v_r:
                    return 1
                else:
                    return -1
            else:
                if not car.speed:
                    car.wait_time += car.network.dt
                return -1
        else:
            # Ist das Auto das erste im Tunnel?
            if not car_tunnel_index:
                return 1
            else:
                # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto vor ihm vollbremst?
                if car.edge_progress-stop_dist <= car.edge.tunnel[car_tunnel_index-1].edge_progress-_stop_dist_m(car.edge.tunnel[car_tunnel_index-1])+car.network.safety_dist:
                    return -1
                # Hält das Auto aktuell den Sicherheitsabstand ein?
                elif car.edge_progress <= car.edge.tunnel[car_tunnel_index-1].edge_progress + car.network.safety_dist:
                    return -1
                elif car.path_progress not in [len(car.path)-2, len(car.path)-1] and len(car.next_edge.tunnel) != 0 and car.edge_progress-stop_dist+car.next_edge.length <= car.next_edge.tunnel[-1].edge_progress-_stop_dist_m(car.next_edge.tunnel[-1])+car.network.safety_dist:
                    return -1
                else:
                    return 1

    def _get_heap_key(self, car):
        # Diese Funktion gibt das Warteschlangenkriterium des Autos zurück.
        # Es wird dabei beachtet, ob das Auto schon lange wartet, ob die nächste Straße des Autos schon voll ist, wie viele Autos an der übernächsten Kreuzung des Autos stehen und wie weit das Auto von der nächsten Kreuzung entfernt ist.
        if car.prio == 1:
            return 0
        elif car.path_progress in [len(car.path)-1, len(car.path)-2]:
            return car.edge_progress/(1 + numpy.heaviside(car.wait_time-15, 0))
        else:
            return (car.edge_progress + 1000*numpy.heaviside(car.next_edge.car_capacity-len(car.next_edge.tunnel)-1, 0) + 100*numpy.heaviside(len(car.next_edge.target.intersection_queue)-10, 0))/(1 + numpy.heaviside(car.wait_time-15, 0))
    
    def _leave_edge(self, car):
        # sortiere die Warteschlange der Kreuzung neu und setze dann die Prioritäten jedes Autos:
        for x in car.next_vertex.intersection_queue:
            x[0] = self._get_heap_key(x[2])
        car.next_vertex.intersection_queue.sort()
        for i, x in enumerate(car.next_vertex.intersection_queue):
            car = x[2]
            car.prio = i
        if len(car.next_vertex.intersection_queue) >= 2:
            first = car.next_vertex.intersection_queue[0][2]
            second = car.next_vertex.intersection_queue[1][2]
            if not(first.edge.tunnel.index(first) == 0):
                for i, x in enumerate(car.next_vertex.intersection_queue[1:]):
                    car = x[2]
                    if car.edge.tunnel.index(car) == 0:
                        first.prio, car.prio = car.prio, first.prio
                        break 
            if not(second.edge.tunnel.index(second) == 0 or second.edge.tunnel.index(second) == 1 and first.edge == second.edge):
                for i, x in enumerate(car.next_vertex.intersection_queue[2:]):
                    car = x[2]
                    if car.edge.tunnel.index(car) == 0 or car.edge.tunnel.index(car) == 1 and first.edge == car.edge:
                        second.prio, car.prio = car.prio, second.prio
                        break

class Traffic_light:
    # Bei diesem Algorithmus halten alle Autos hinter dem zweiten aus der Warteschlange an Kreuzungen vollständig an.
    # Das zweite berechnet wann das erste die Kreuzung spätestens überquert und beschleunigt anhand dieser Berechnung schon bevor das erste die Kreuzung überquert hat.
    # Die Reihenfolge der Warteschlange wird jedes mal wenn das vorderste Auto die Kreuzung überquert anhand des Merkmals s neu berechnet.
    # Dabei wird der bisher zweite in jedem Fall zum ersten in der Warteschlange.
    def _initialize_vertex(self, vertex):
        vertex.traffic_light_duration = 0
        vertex.pred_edge_list = []
        for _, edge in vertex.pred_edges.items():
            vertex.pred_edge_list.append(edge)
        vertex.counter = 0
        vertex.traffic_light_time = 0

    def _initialize_edge(self, edge):
        edge.closed = True
        edge.traffic_light_duration = 0


    def _enter_edge(self, car):
        if not car.next_vertex.intersection_queue:
            car.edge.closed = False
        # setze das Auto an das Ende der Warteschlange:
        car.prio = len(car.next_vertex.intersection_queue)
        car.next_vertex.intersection_queue.append([get_heap_key(car), next(car.network.c), car])

    def _predict_intersection_speed_first(self, car):
        # Diese Funktion berechnet die minimale Geschwindigkeit, die das erste Auto der Warteschlange haben wird, wenn es an der Kreuzung vorbei ist und eine Entfernung von safety_dist zur Kreuzung hat:
        first_car = car.next_vertex.intersection_queue[0][2]
        # Ist das erste Auto der Warteschlange im Tunnel vor dem Zielfahrstuhl oder im Zielfahrstuhl?
        if first_car.path_progress in [len(first_car.path)-2, len(first_car.path)-1]:
            v_at_intersection = float("inf")
        else:
            # Ist der nächste Tunnel auf dem Weg des Autos leer?
            if not first_car.next_edge.tunnel:
                # maximale Geschwindigkeit bei der man mit Vollbremsung ab dem nächsten Punkt dem übernächsten Punkt nicht näher als safety_dist kommt:
                v_at_intersection = (2*car.network.max_deacc*(first_car.next_edge.length-car.network.safety_dist))**0.5
            else:
                # Entfernung der Kreuzung zum letzten Auto des nächsten Tunnels, falls es vollbremst:
                next_car_dist = first_car.next_edge.length-first_car.next_edge.tunnel[-1].edge_progress+_stop_dist_m(first_car.next_edge.tunnel[-1])
                # Ist diese Entfernung kleiner oder gleich dem Mindestabstand des Verkehrssystems?
                if next_car_dist <= car.network.safety_dist:
                    v_at_intersection = 0
                else:
                    v_at_intersection = (2*car.network.max_deacc*(next_car_dist-car.network.safety_dist))**0.5
        v_at_intersection = max(0, v_at_intersection)
        v_at_intersection = min(first_car.edge.max_speed, v_at_intersection)
        return v_at_intersection

    def _predict_intersection_time_first(self, car, v_target):
        # Dieses Programm gibt t bzw. T zurück. t ist der Zeitpunkt an dem das erste Auto der Warteschlange frühestens die Kreuzung erreicht und T ist der Zeitpunkt an dem die Kreuzung wieder öffnet.
        # Für diese Berechnung erhält sie das betrachtete Auto und die Mindestgeschwindigkeit, die das erste Auto an der Kreuzung haben wird.
        first_car = car.next_vertex.intersection_queue[0][2]
        if v_target > 0:
            # Ist v_target schneller als die aktuelle Geschwindigkeit des ersten Autos?
            if v_target >= first_car.speed:
                # Wird das erste Auto v_target vor der Kreuzung erreichen, wenn es voll beschleunigt?
                if (v_target**2 - first_car.speed**2)/(2*car.network.max_acc) < first_car.edge_progress:
                    v_real = v_target
                    t = ((v_target-first_car.speed)**2+2*car.network.max_acc*first_car.edge_progress)/(2*car.network.max_acc*v_target)
                else:
                    v_real = (first_car.speed**2+2*car.network.max_acc*first_car.edge_progress)**0.5
                    t = (v_real-first_car.speed)/car.network.max_acc
            else:
                # Wird das erste Auto v_target vor der Kreuzung erreichen, wenn es vollbremst?
                if (first_car.speed**2 - v_target**2)/(2*car.network.max_deacc) < first_car.edge_progress:
                    v_real = v_target
                    t = (-(first_car.speed-v_target)**2+2*car.network.max_acc*first_car.edge_progress)/(2*car.network.max_acc*v_target)
                else:
                    v_real = (first_car.speed**2-2*car.network.max_deacc*first_car.edge_progress)**0.5
                    t = (first_car.speed-v_real)/car.network.max_deacc
            return v_real, t
        else:
            return 0, float("inf")

    def _get_acceleration(self, car):
        stop_dist = _stop_dist_p(car)
        car_tunnel_index = car.edge.tunnel.index(car)
        # Kann das Auto vor der Kreuzung bei maximaler Bremsung nicht halten?
        if stop_dist >= car.edge_progress-car.network.safety_dist:
            # Ist das Auto das erste in der Warteschlange der Kreuzung?
            if not car.prio:
                # Befindet sich das Auto gerade im Fahrstuhl vor dem Ziel?
                if car.path_progress in [len(car.path)-1, len(car.path)-2]:
                    return 1
                else:
                    # Kann das Auto bei Vollbremsung vor der übernächsten Kreuzung nicht halten?
                    if stop_dist >= car.edge_progress + car.next_edge.length - car.network.safety_dist:
                        return -1
                    # Ist der nächste Tunnel auf dem Weg des Autos leer?
                    elif not car.next_edge.tunnel:
                        return 1
                    # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto des nächsten Tunnels vollbremst?
                    elif stop_dist-car.edge_progress >= _stop_dist_m(car.next_edge.tunnel[-1])+car.next_edge.length-car.next_edge.tunnel[-1].edge_progress-car.network.safety_dist:
                        return -1
                    else:
                        return 1
            # Ist das Auto das zweite der Warteschlange?
            elif car.prio == 1:
                first_car = car.next_vertex.intersection_queue[0][2]
                if car.edge == first_car.edge:
                    # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto vor ihm vollbremst?
                    if car.edge_progress-stop_dist <= first_car.edge_progress-_stop_dist_m(first_car)+car.network.safety_dist:
                        return -1
                    else:
                        return 1
                if car.path_progress not in [len(car.path)-2, len(car.path)-1]:
                    # Kann das Auto bei Vollbremsung vor der übernächsten Kreuzung nicht halten?
                    if stop_dist >= car.edge_progress + car.next_edge.length - car.network.safety_dist:
                        return -1
                # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto des nächsten Tunnels vollbremst?
                if car.next_edge != None and len(car.next_edge.tunnel) != 0 and stop_dist-car.edge_progress >= _stop_dist_m(car.next_edge.tunnel[-1])+car.next_edge.length-car.next_edge.tunnel[-1].edge_progress-car.network.safety_dist:
                    return -1
                v_target = self._predict_intersection_speed_first(car)
                v_r, t = self._predict_intersection_time_first(car, v_target)
                if car.next_edge != None and car.next_edge == first_car.next_edge and len(car.next_edge.tunnel):
                    next_car = car.next_edge.tunnel[-1]
                    if v_r**2/(2*car.network.max_deacc) >= car.next_edge.length - next_car.edge_progress+_stop_dist_m(next_car) - car.network.safety_dist:
                        if stop_dist - car.edge_progress >= v_r**2/(2*car.network.max_deacc):
                            return -1
                    if first_car.edge.elevator == True:
                        return -1
                if v_r == 0:
                    return -1
                elif ((2*car.network.max_acc*car.edge_progress+car.speed**2)**0.5-car.speed)/car.network.max_acc >= t+car.network.intersection_width/v_r:
                    return 1
                else:
                    return -1
            else:
                return -1
        else:
            # Ist das Auto das erste im Tunnel?
            if not car_tunnel_index:
                return 1
            else:
                # Könnte das Auto den Sicherheitsabstand nicht einhalten, wenn das letzte Auto vor ihm vollbremst?
                if car.edge_progress-stop_dist <= car.edge.tunnel[car_tunnel_index-1].edge_progress-_stop_dist_m(car.edge.tunnel[car_tunnel_index-1])+car.network.safety_dist:
                    return -1
                # Hält das Auto aktuell den Sicherheitsabstand ein?
                elif car.edge_progress <= car.edge.tunnel[car_tunnel_index-1].edge_progress + car.network.safety_dist:
                    return -1
                elif car.path_progress not in [len(car.path)-2, len(car.path)-1] and len(car.next_edge.tunnel) != 0 and car.edge_progress-stop_dist+car.next_edge.length <= car.next_edge.tunnel[-1].edge_progress-_stop_dist_m(car.next_edge.tunnel[-1])+car.network.safety_dist:
                    return -1
                else:
                    return 1

    def _get_heap_key(self, car):
        # Diese Funktion gibt das Warteschlangenkriterium des Autos zurück.
        if car.prio == 1:
            return 0
        elif car.edge.closed == False:
            return car.edge_progress
        else:
            return car.edge_progress + 1000

    def _leave_edge(self, car):
        # sortiere die Warteschlange der Kreuzung neu und setze dann die Prioritäten jedes Autos:
        for _, edge in car.next_vertex.pred_edges.items():
            edge.traffic_light_duration = len(edge.tunnel)
        if car.next_vertex.traffic_light_time >= car.next_vertex.traffic_light_duration:
            car.next_vertex.counter += 1
            while len(car.next_vertex.pred_edge_list[car.next_vertex.counter%len(car.next_vertex.pred_edge_list)].tunnel) == 0 and car.next_vertex.pred_edge_list[car.next_vertex.counter%len(car.next_vertex.pred_edge_list)] != car.edge:
                car.next_vertex.counter += 1
            car.next_vertex.traffic_light_time = 0
            car.edge.closed = True
            new_opened = car.next_vertex.pred_edge_list[car.next_vertex.counter%len(car.next_vertex.pred_edge_list)]
            if len(new_opened.tunnel) != 0:
                new_opened.closed = False
            car.next_vertex.traffic_light_duration = new_opened.traffic_light_duration
        else:
            car.next_vertex.traffic_light_time += 1

        for x in car.next_vertex.intersection_queue:
            x[0] = self._get_heap_key(x[2])
        car.next_vertex.intersection_queue.sort()
        for i, x in enumerate(car.next_vertex.intersection_queue):
            car = x[2]
            car.prio = i

algorithm = None

def set_algorithm(algorithm_name):
    # Mit dieser Funktion kann ein Geschwindigkeitsalgorithmus für das Verkehrsnetzwerk gewählt werden.
    global algorithm
    if algorithm_name == "one car priority":
        algorithm = One_car_priority_intersection()
    elif algorithm_name == "two car priority":
        algorithm = Two_car_priority()
    elif algorithm_name == "two car advanced heap":
        algorithm = Two_car_advanced_heap()
    elif algorithm_name == "traffic light":
        algorithm = Traffic_light()
    else:
        sys.exit()

def initialize_vertex(vertex):
    algorithm._initialize_vertex(vertex)

def initialize_edge(edge):
    algorithm._initialize_edge(edge)

def enter_edge(car):
    algorithm._enter_edge(car)

def leave_edge(car):
    # Diese Funktion sortiert die Warteschlange der nächsten Kreuzung von car.
    algorithm._leave_edge(car)

def get_acceleration(car):
    # Diese Funktion gibt die Beschleunigungsausgabe des gewählten Algorithmus aus.
    return algorithm._get_acceleration(car)

def get_heap_key(car):
    # Diese Funktion gibt die Warteschlangenkriteriumsausgabe des gewählten Algorithmus zurück.
    return algorithm._get_heap_key(car)