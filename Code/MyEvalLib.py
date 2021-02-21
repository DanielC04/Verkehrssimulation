import matplotlib.pyplot as plt
import numpy
import pathlib


def init_eval_vars_network(network):
    # Hier werden alle Daten zur späteren Auswertung des Programms gespeichert.
    # Zähler für Anzahl ge-/despawnter Autos, die gesamte Fahrzeit ge-/despawnter Autos, die gesamte Weglänge ge-/despawnter Autos:
    network.car_count_spawned = 0
    network.car_count_arrived = 0
    network.drive_time_arrived = {}
    network.drive_time_all = {}
    network.path_length_arrived = {}
    network.path_length_all = {}
    
# Funktion zum abrufen und speichern der Auswertungsdaten eines Autos
def fetch_eval_car_all(network, car):
    car.drive_time = network.sim_time-car.spawn_time
    # Die Werte von eben gespawnten Autos werden nicht in die Datenanalyse aufgenommen.
    if car.drive_time >= 5:
        network.drive_time_all[car.key] = car.drive_time
        car.path_length = -car.edge_progress
        for i, pred_vertex in enumerate(car.path[:car.path_progress]):
            car.path_length += pred_vertex.succ_edges[car.path[i+1]].length
        network.path_length_all[car.key] = car.path_length

# Funktion zum abrufen und speichern der Auswertungsdaten eines angekommenen Autos
def fetch_eval_car_arrived(network, car):
    car.drive_time = network.sim_time-car.spawn_time
    network.drive_time_arrived[car.key] = car.drive_time
    car.path_length = 0
    for i, pred_vertex in enumerate(car.path[:-1]):
        car.path_length += pred_vertex.succ_edges[car.path[i+1]].length
    network.path_length_arrived[car.key] = car.path_length

def evaluate_sim(network, target_file):
    # erstelle eine matplotlib Figur mit einem Full HD Seitenverhältnis:
    plt.figure(num=None, figsize=(19.2, 10.8), dpi=80, facecolor='w', edgecolor='k')

    # erstelle den oberen plot:
    plt.subplot(2, 1, 1)

    avg_time_all = numpy.sum(list(network.drive_time_all.values()))/len(network.drive_time_all)
    avg_dist_all = numpy.sum(list(network.path_length_all.values()))/len(network.path_length_all)

    # erstelle die Überschrift mit car_count_spawned, car_count_arrived:
    plt.title('Es wurden ' + str(network.car_count_spawned) + ' Autos erstellt. Davon haben ' + str(network.car_count_arrived) + ' haben ihr Ziel erreicht. \n \n Fahrzeit-Fahrstrecke-Diagramm der Autos (Werte für angekommene Autos in Klammern und blau)')
    
    # erstelle ein t-s-Diagramm unverbundener Punkte:
    for key in network.drive_time_all:
        if key not in network.drive_time_arrived:
            plt.plot(network.drive_time_all[key], network.path_length_all[key], '.', color = 'r')

    avg_time_arrived = numpy.sum(list(network.drive_time_arrived.values()))/len(network.drive_time_arrived)
    avg_dist_arrived = numpy.sum(list(network.path_length_arrived.values()))/len(network.path_length_arrived)
    plt.xlabel('t in s → ø =' + str(round(avg_time_all)) + ' (' + str(round(avg_time_arrived)) + ') s')
    plt.ylabel('s in m → ø =' + str(round(avg_dist_all)) + ' (' + str(round(avg_dist_arrived)) + ') m')
    for key in network.drive_time_arrived:
        plt.plot(network.drive_time_arrived[key], network.path_length_arrived[key], '.', color = 'b')


    #erstelle den unteren plot
    plt.subplot(2, 1, 2)

    
    plt.title('Verteilung der Durchschnittsgeschwindigkeiten der Autos (Werte für angekommene Autos in Klammern und blau)')
    # Wir haben uns entschieden, die Durchschnittsgeschwindigkeiten über s_g/t_g zu berechen.
    avg_speed_all = numpy.sum([network.path_length_all[key]/network.drive_time_all[key] for key in network.drive_time_all])/len(network.drive_time_all)
    avg_speed_arrived = numpy.sum([network.path_length_arrived[key]/network.drive_time_arrived[key] for key in network.drive_time_arrived])/len(network.drive_time_arrived)
    #erstelle ein v-bar-diagramm
    plt.xlabel('v in m/s → ø =' + str(round(avg_speed_all, 1)) + ' (' + str(round(avg_speed_arrived, 1)) + ') m/s' )
    plt.ylabel('Anzahl')

    # bar_width ist die Breite der Intervalle in denen v eingeteilt wird
    bar_width = 1
    # zunächst werden alle Autos betrachtet:
    network.speed_distribution_all = {}
    # brechne das höchste Intervall, in dem es mindestens eine Geschwindigkeit gibt:
    key_max = int(max([bar_width*round(network.path_length_all[key]/network.drive_time_all[key]/bar_width) for key in network.drive_time_all]))
    # erstelle ein rotes bar-diagram der Geschwindigkeiten aller Autos:
    for key in range(0, key_max+bar_width, bar_width):
        network.speed_distribution_all[key] = 0
    for key in network.drive_time_all:
        network.speed_distribution_all[bar_width*round(network.path_length_all[key]/network.drive_time_all[key]/bar_width)] += 1
    for key, amount in network.speed_distribution_all.items():
        plt.bar(key, amount, color = 'r')
    
    #jetzt werden angekommene Autos betrachtet:
    network.speed_distribution_arrived = {}
    # brechne das höchste Intervall, in dem es mindestens eine Geschwindigkeit gibt:
    key_max = int(max([bar_width*round(network.path_length_arrived[key]/network.drive_time_arrived[key]/bar_width) for key in network.drive_time_arrived]))
    # erstelle ein blaues bar-diagram der Geschwindigkeiten angekommener Autos:
    for key in range(0, key_max+bar_width, bar_width):
        network.speed_distribution_arrived[key] = 0
    for key in network.drive_time_arrived:
        network.speed_distribution_arrived[bar_width*round(network.path_length_arrived[key]/network.drive_time_arrived[key]/bar_width)] += 1
    for key, amount in network.speed_distribution_arrived.items():
        plt.bar(key, amount, color = 'b')

    # speichere die Grafik im Ordner der GUI2:
    plt.savefig(target_file)

def print_evaluations(network):
    print("car count spawned:", network.car_count_spawned)
    print("car count arrived:", network.car_count_arrived)