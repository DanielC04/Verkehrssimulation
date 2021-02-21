/* //<>//
shortcuts:
 - TAB: GUI2 starten
 - E: neuen Fahrstuhl erstellen
 - C: neuen CityCenter erstellen
 - D: aktuell ausgewähltes Objekt löschen
 - A: alles löschen
 - S: Daten speichern
 - P: Pythonprogramm starten
 - SHIFT + einen zweiten Fahrstuhl anklicken: neuen Tunnel erstellen
 */
// benutzte Libraries
import shapes3d.*;
import shapes3d.contour.*;
import shapes3d.org.apache.commons.math.*;
import shapes3d.org.apache.commons.math.geometry.*;
import shapes3d.path.*;
import shapes3d.utils.*;
import java.io.*;
import java.util.*;
import peasy.*;
import controlP5.*;
import processing.opengl.*;

// Objekte deklarieren
PeasyCam cam;
ControlP5 cp5;
Button buttonIn, buttonOut;
Terrain myTerrain;
PopupText popup;
ElevatorInfo elevInfo;
TunnelInfo tunnelInfo;
DefaultInfo defaultInfo;
CityCenterInfo cityCenterInfo;
InfoArea infoArea;

// Listen mit Fahrstühlen, Tunneln und CityCenters; sowie deren Iterators
ArrayList<Elevator> allElevators = new ArrayList<Elevator>();
ArrayList<Tunnel> allTunnels = new ArrayList<Tunnel>();
ArrayList<CityCenter> allCityCentersIn = new ArrayList<CityCenter>();
ArrayList<CityCenter> allCityCentersOut = new ArrayList<CityCenter>();
Iterator<Elevator> elevatorIterator;
Iterator<Tunnel> tunnelIterator;
Iterator<CityCenter> cityCenterIteratorIn, cityCenterIteratorOut;

// Einstellungen der GUI
final int scale = 20;                                                          // ungefähr 20 pixel sind 1 meter -> alle Distanzen müssen um 20 gestreckt werden
final int border = 500 * scale;                                                // die Größe des generierten Terrains und die maximalen Eingabewerte in den Numberboxes
final color color1 = color(0, 255, 0), color2 = color(255, 0, 0);
final String fileName = "/data_input.json";
final boolean isExe = false;         // muss beim Export der .exe true sein, damit die Paths richtig sind
String sketchPath;
PFont font;
int windowWidth, windowHeight;    // um resizing vom Fenster zu erkennen

// sonstige Variablen
PImage tunnelTexture;
float upperBorder;
int tab;
Elevator selectedElevator = null;
Tunnel selectedTunnel = null;
CityCenter selectedCityCenter = null;

void setup() {  
  size(1920, 1080, P3D);
  frameRate(25);
  textSize(32);
  font = createFont("Georgia", 24);
  textFont(font);
  fill(0);
  sketchPath = sketchPath();
  if (isExe){
    sketchPath = new File(sketchPath).getParentFile().getAbsolutePath();
  }
  tunnelTexture = loadImage(sketchPath  + "/tunnelTexture.png");
  // Objekte für Benutzerein- und -ausgaben einrichten -> siehe tab UI
  setupControlElements();
  //Objekte initiieren
  cam = new PeasyCam(this, 1800);
  cam.setSuppressRollRotationMode();
  myTerrain = new Terrain();
  popup = new PopupText();
  cityCenterInfo = new CityCenterInfo();
  elevInfo = new ElevatorInfo();
  tunnelInfo = new TunnelInfo();
  defaultInfo = new DefaultInfo();
  infoArea = new InfoArea();
  // Elevators, Tunnel und andere Daten laden
  loadData();
  // Tab wechseln, um spawnRateIn und spawnRateOut der Elevators zu berechnen und die Farben der Elevators zu setzen
  out();
  in();
}
// window risize erkennen
void checkForWindowResize() {
  if (windowWidth != width || windowHeight != height) {
    // Sketch window has resized
    windowWidth = width;
    windowHeight = height;
    // Easycam neu einrichten, weil sonst die Kamera nicht mit neuer Fenstergröße klar kommt
    cam.reset(1800);
    println("window resized");
  }
}

void draw() {
  checkForWindowResize();
  background(255);
   //draw elevators
  for (elevatorIterator = allElevators.iterator(); elevatorIterator.hasNext(); ) {
    elevatorIterator.next().display();
  }
  // draw tunnels
  for (tunnelIterator = allTunnels.iterator(); tunnelIterator.hasNext(); ) {
    tunnelIterator.next().display();
  }
  if (tab == 1) {
    for (cityCenterIteratorIn = allCityCentersIn.iterator(); cityCenterIteratorIn.hasNext(); ) {
      cityCenterIteratorIn.next().display();
    }
  } else {
    for (cityCenterIteratorOut = allCityCentersOut.iterator(); cityCenterIteratorOut.hasNext(); ) {
      cityCenterIteratorOut.next().display();
    }
  }
  myTerrain.display();
  drawControlls();
}
