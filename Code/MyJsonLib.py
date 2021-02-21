import json
import pathlib


# Funktion, welche einen Fehler in die JSON einträgt
def dump_error(file, error):
    with open(file, 'w') as f:
        # Fehler wird an GUI2 weitergegeben:
        error = {"Error": error}
        json.dump(error, f, indent = 4)

# Funktion zum initiieren der Variablen, welche an die JSON der GUI2 weitergegeben werden
def init_json_vars_network(network):
    network.GUI2_data_car = []

# Funktion zum abrufen und speichern der JSON Information eines Autos
def fetch_json_car(network, car):
    network.GUI2_data_car.append(car.GUI2_data)

# Funktion zum abrufen und speichern der gesamten JSON Information des Netzwerks in data_exchange.json
def dump_sim(network, file):
    network.output = network.input
    network.output["Cars"] = network.GUI2_data_car
    # setze Error auf "null" ~> GUI2 wird gestartet, da Error != "loading"
    network.output["Error"] = "null"
    with open(file, 'w') as f:
        json.dump(network.output, f, indent=4)