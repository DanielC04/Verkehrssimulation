/* //<>// //<>//
 shortcuts:
 Leertaste: Simulation pausieren/fortsetzen
 TAB: GUI1 starten
 R: Simulation neu starten
 S: Simulation stoppen
 H: Toggle Sichtbarkeit der Konsole und der Infoboxen über den Autos
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
ControlP5 cp5;
PeasyCam cam;
LoadingScreen loadingScreen;
Println console;
Textarea consoleArea;
Terrain myTerrain;
Timer timer;
InfoArea infoArea;
JSONObject data;

// Listen mit Fahrstühlen, Tunneln und Autos
ArrayList<Elevator> allElevators = new ArrayList<Elevator>();
ArrayList<Tunnel> allTunnels = new ArrayList<Tunnel>();
ArrayList<Car> allCars = new ArrayList<Car>();
ArrayList<Car> carsToDestroy = new ArrayList<Car>();

// Einstellungen der GUI
final int scale = 20;                              // ungefähr 20 pixel sind 1 meter -> alle Distanzen müssen um 20 gestreckt werden
final int terrainBorder = 500 * scale;             // die Größe des generierten Terrains und die maximalen Eingabewerte in den Numberboxes
final String fileName = "/data_exchange.json";
String sketchPath;
float dt = 0.04, simDuration;
PImage endscreen, tunnelTexture;
float maxAcc, maxDeacc, elevSpeed = 0;
String error;
PFont font;

// in Programm benutzte Flags
boolean pause = false;                            // true, wenn Programm pausiert
boolean signsVisible = true;                     // Konsole und Schilder über Autos werden nur angezeigt wenn signsVisible == true
boolean isLoading = true;

void setup() {
  fullScreen(P3D);
  sketchPath = sketchPath();
  if (sketchPath().contains("application.windows")) {
    sketchPath = new File(sketchPath).getParentFile().getAbsolutePath();
  }
  PImage splashScreen = loadImage(sketchPath + "/splashScreen.PNG");
  image(splashScreen, 0, 0, width, height);
  frameRate(1/dt);
  textSize(24);
  textAlign(CENTER);
  fill(0);
  font = createFont("Georgia", 24);
  //Objekte initiieren
  cam = new PeasyCam(this, 0, 0, 0, 2000);
  cam.setSuppressRollRotationMode();
  loadingScreen = new LoadingScreen();
  myTerrain = new Terrain();
  timer = new Timer();
  // Objekte für Benutzerein- und -ausgaben einrichten -> siehe tab UI
  setupControlElements();
  thread("updateData");
}

void draw() {
  background(255);
  // loading Screen anzeigen
  if (isLoading && error != null) {
    loadingScreen.display();
  } else if (simDuration >= timer.time) {    // Objekte müssen nicht mehr gezeichnet werden, wenn der Endscreen angezeigt wird
    // draw all Objects
    if (pause) {
      for (Car i : allCars) {
        i.display();
      }
    } else {
      timer.increment();
      for (Car i : allCars) {
        i.display();
        i.moveCar();
      }
    }
    for (Elevator i : allElevators) {
      i.display();
    }
    for (Tunnel i : allTunnels) {
      i.display();
    }

    myTerrain.display();
    drawControlls();
  }
  // endscreen anzeigen
  else {
    hint(DISABLE_DEPTH_TEST);
    cam.beginHUD();
    image(endscreen, 0, 0, width, height);
    cam.endHUD();
    hint(ENABLE_DEPTH_TEST);
  }
  // alle Autos, die in diesem Frame zerstört werden sollen jetzt zerstören (werden sie während des Zeichnens von anderen Autos in allCars zerstört, kommt es zu ConcurrentModificationExceptions)
  if (carsToDestroy.size() > 0) {
    for (Car i : carsToDestroy) {
      i.destroyCar();
    }
    carsToDestroy.clear();
  }
}

// Thread zum Laden der großen Datenmengen im Hintergrund
void updateData() {
  while (true) {
    try {
      data = loadJSONObject(sketchPath + fileName);
      error = data.getString("Error");
      if (! error.equals("null")) {
        isLoading = true;
        cam.reset();
        cam.setActive(false);
      } else if (isLoading == true && error.equals("null")) {      // Error-String in JSON-Datei hat von loading auf etwas anderes gewechselt
        reset();
        endscreen = loadImage(sketchPath + "/evaluation.png");
      }
    }
    catch(Exception e) {
      error = e.getMessage();
      println(e);
    }
    delay(1000);
  }
}
