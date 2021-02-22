import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

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

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class GUI2 extends PApplet {

/* //<>//
 shortcuts:
 Leertaste: Simulation pausieren/fortsetzen
 TAB: GUI1 starten
 R: Simulation neu starten
 S: Simulation stoppen
 H: Toggle Sichtbarkeit der Konsole und der Infoboxen über den Autos
 */
// benutzte Libraries






 
 




// Objekte deklarieren
ControlP5 cp5;
PeasyCam cam;
LoadingScreen loadingScreen;
Println console;
Textarea consoleArea;
Terrain myTerrain;
Timer timer;
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
float dt = 0.04f, simDuration;
PImage endscreen, tunnelTexture;
float maxAcc, maxDeacc, elevSpeed = 0;
String error;

// in Programm benutzte Flags
boolean pause = false;                            // true, wenn Programm pausiert
boolean signsVisible = true;                     // Konsole und Schilder über Autos werden nur angezeigt wenn signsVisible == true
boolean isLoading = true;

public void setup() {
  
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

public void draw() {
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
public void updateData() {
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

public class Car {
  PShape car, backgroundSign;
  PVector pos, dsVector = new PVector();
  Street tunnel;
  int indexRoute = 0, indexA = 0, indexCheckpoints = 0, id, a = -1;
  private float v = 0, deltaPosOnStreet, posOnStreet = 0.f;
  float [] acc;
  float [][] checkpoints;
  ArrayList<Street> route;

  public Car(ArrayList<Street> r, int i, float [] a, float[][] c) {
    car = loadShape(sketchPath + "/Car.obj");
    car.scale(18);
    car.translate(0, -12, 0);
    car.rotate(PI, 0, 0, 1);
    acc = a;
    checkpoints = c;

    backgroundSign = createShape(RECT, -100, -36, 180, 100);
    backgroundSign.setFill(color(240, 200));
    route = r;
    id = i;

    reset();

    println("~ ");
    println("~ ---" + timer.getStr() + "---");
    println("~ Car spawned: ");
    println("~    id: " + id);
  }  

  public void reset() {
    tunnel = route.get(0);
    indexRoute = 0;
    posOnStreet = 0.f;
    pos = tunnel.pos2.copy();
    setVelocity(v);
  }

  public void display() {
    pushMatrix();
    if (tunnel.isLowerTunnel) {
      translate(0, 40, 0);
    }
    translate(pos.x, pos.y, pos.z);
    // draw car
    shape(car);
    if (signsVisible) {
      // draw Sign
      pushMatrix();
      rotate(tunnel.angleY, 0, 1, 0);
      translate(0, -100, 0);
      text("id: " + id + "\nspeed: " + (int) v, 0, 0);
      translate(20, 0, -1);
      shape(backgroundSign);
      popMatrix();
    }
    popMatrix();
  }

  public void switchRoad() {
    // Rotationen der vorherigen Straße rückgängig machen
    car.rotate(- tunnel.angleX, tunnel.rotationAxis.x, tunnel.rotationAxis.y, tunnel.rotationAxis.z);
    car.rotate(- tunnel.angleY, 0, 1, 0);
    indexRoute ++;
    if (indexRoute == 1 || indexRoute == route.size() - 1) {                       // v auf 0 setzen, falls man Auto Fahrstuhl kommt
      v = 0;
    }
    if (indexRoute < route.size()) {            // sonst nächsten Tunnel der Route auswählen
      tunnel = route.get(indexRoute);
    } else {                                    // Auto ist am Ende der Route
      carsToDestroy.add(this);
    }
    posOnStreet = 0.f;
    pos = tunnel.pos1.copy();
    setVelocity(v);
    // Auto genau wie Tunnel drehen
    car.rotate(tunnel.angleY, 0, 1, 0);
    car.rotate(tunnel.angleX, tunnel.rotationAxis.x, tunnel.rotationAxis.y, tunnel.rotationAxis.z);
  }

  public void moveCar() {
    updateAcc(timer.time);
    if (a == 1) {                            // beschleunigen bzw. abbremsen
      if (v != min(tunnel.vmax, v + maxAcc * dt)) {
        setVelocity(min(tunnel.vmax, v + maxAcc * dt));
      }
    } else if (a == -1) {
      if (v != max(0, v - maxDeacc * dt)) {
        setVelocity(max(0, v - maxDeacc * dt));
      }
    }
    if (posOnStreet+deltaPosOnStreet < 1) {                    // wenn Auto auf Straße ist: um dsVector auf Straße weiterbewegen
      pos.add(dsVector);
      posOnStreet += deltaPosOnStreet;
    } else {                                    // Straße wechseln, falss posOnStreet >= 1
      switchRoad();
    }
    checkCheckpoint(timer.time);
  }

  public void setVelocity(float newVel) {
    v = newVel;
    deltaPosOnStreet = (v * dt * scale)/tunnel.len;
    if (indexRoute == 0) {    // keine Unterscheidung von herauffahrenden und runterführenden Elevators
      PVector.mult(tunnel.movementVector, - deltaPosOnStreet, dsVector);     // -> bei einem der beiden (hier runterfahrend) muss der dsVector mit -1 multipliziert werden, damit das Auto sich nach unten bewegt
    } else {
      PVector.mult(tunnel.movementVector, deltaPosOnStreet, dsVector);
    }
  }
  // testet, ob Auto Beschleunigung ändern muss
  public void updateAcc(float t) {
    if (acc.length > indexA && t >= acc[indexA]) {
      a *= -1;
      indexA ++;
    }
  }

  public void checkCheckpoint(float t) {
    if (checkpoints.length > indexCheckpoints && t >= checkpoints[indexCheckpoints][0]) {
      posOnStreet = checkpoints[indexCheckpoints][2];
      if (a != checkpoints[indexCheckpoints][4]) {
        a*= -1;
        indexA ++;
      }
      if (indexRoute != checkpoints[indexCheckpoints][1]) {
        indexRoute = PApplet.parseInt(checkpoints[indexCheckpoints][1]) - 1;
        switchRoad();
      }
      if (indexRoute == 0) {
        pos = tunnel.pos2.copy();
        pos.sub(tunnel.movementVector.copy().setMag(posOnStreet * tunnel.len));
      } else {
        pos = tunnel.pos1.copy();
        pos.add(tunnel.movementVector.copy().setMag(posOnStreet * tunnel.len));
      }
      setVelocity(checkpoints[indexCheckpoints][3]);
      indexCheckpoints ++;
    }
  }
  // Auto zerstören
  private void destroyCar() {
    println("~");
    println("~ ---" + timer.getStr() + "---");
    println("~ Car despawned: ");
    println("~    id: " + id);
    allCars.remove(this);
  }
}
// Edge enthält alle Informationen, die ein Auto braucht, um auf ihr zu fahren
class Street {
  boolean isLowerTunnel = false;
  PVector pos1, pos2, movementVector, rotationAxis;
  float len, angleX, angleY, vmax;

  public Street(PVector p1, PVector p2, float v) {
    pos1 = p1;
    pos2 = p2;
    vmax = v;
    movementVector = PVector.sub(pos2, pos1);
    len = movementVector.mag();
    // calculate rotationAxis and -angle
    angleY = new PVector(movementVector.z, movementVector.x).heading();
    angleX = asin(movementVector.y/movementVector.mag());
    rotationAxis = movementVector.cross(new PVector(0, 1, 0));
  }
}

class Tunnel extends Street {
  // car always drives from node1 to node2
  Path path;
  Oval base;
  Tube tunnel;
  int diameter = 20;

  public Tunnel(PVector p1, PVector p2, float v) {
    super(p1, p2, v);
    path = new Linear(pos1, pos2, 1);
    base = new Oval(diameter, 20);
    while (tunnel == null) {
      try {
        tunnel = new Tube(path, base);
        tunnel
          .use(S3D.BODY)
          .texture(tunnelTexture, S3D.BODY)
          .uv(0, this.len/40, 0, 6, S3D.BODY)
          .drawMode(S3D.TEXTURE)
          .use(S3D.END0 | S3D.END1)
          .visible(false);
      }
      catch (Exception i) {
        tunnel = null;
        pos1.x ++;
        path = new Linear(pos1, pos2, 1);
      }
    }    
    if (existsTunnel(pos2, pos1)) {
      isLowerTunnel = true;
    }
  }
  public void display() {
    if (isLowerTunnel) {
      pushMatrix();
      translate(0, 40, 0);
      tunnel.draw(getGraphics());
      popMatrix();
    } else {
      tunnel.draw(getGraphics());
    }
  }
}

public class Elevator extends Street {
  PShape elev;

  public Elevator(PVector p, float vmax) {
    super(p, new PVector(p.x, 0, p.z), vmax);
    angleX = 0.f;
    angleY = 0.f;
    elev = createShape(BOX, 40, len, 100);
    elev.setFill(false);
    elev.setStroke(color(0));
    elev.setStrokeWeight(4);
    elev.translate(pos1.x, len/2, pos1.z);
  }
  public void display() {
    shape (elev);
  }
}
public void loadObjects() {
  JSONObject data = loadJSONObject(sketchPath + fileName);
  // allgemeine Einstellungen laden
  simDuration = data.getFloat("simDuration");
  simDuration -= simDuration % 25/12.f; // simDurationTime leicht runden -> sicherstellen, dass Vor- und Zurückspulen bis zum Ende möglich ist 
  maxAcc = data.getFloat("maxAcc");
  maxDeacc = data.getFloat("maxDeacc");
  elevSpeed = data.getFloat("elevatorSpeed");
  // Fahrstühle laden
  JSONArray elevators = data.getJSONArray("Elevators");
  for (int i = 0; i < elevators.size(); i ++) {
    JSONObject elevator = elevators.getJSONObject(i);
    allElevators.add(new Elevator(new PVector(elevator.getInt("x") * scale, elevator.getInt("y") * scale, elevator.getInt("z") * scale), elevSpeed));
  }
  // Tunnel laden
  JSONArray tunnels = data.getJSONArray("Tunnels");
  for (int i = 0; i < tunnels.size(); i ++) {
    JSONObject tunnel = tunnels.getJSONObject(i);
    PVector pos1 = allElevators.get(tunnel.getInt("elev1")).pos1;
    PVector pos2 = allElevators.get(tunnel.getInt("elev2")).pos1;
    allTunnels.add(new Tunnel(pos1, pos2, tunnel.getFloat("vmax")));
  }
  // spawnTime der Autos laden und in Liste timer.spawnTimes[] speichern
  float[] spawnTimes = new float[data.getJSONArray("Cars").getJSONObject(data.getJSONArray("Cars").size() - 1).getInt("key") + 1];
  for (int i = 0; i < data.getJSONArray("Cars").size(); i ++) {
    JSONObject car =  data.getJSONArray("Cars").getJSONObject(i);
    spawnTimes[car.getInt("key")] = car.getFloat("spawnTime");
  }

  timer.spawnTimes = spawnTimes;

  //console.clear();
  // 
  if (! data.getString("Error").equals("null")) {
    println(data.getString("Error"));
    throw new IllegalArgumentException(data.getString("Error"));
  }
  println("-----------------------------");
  println("---Simulation-started---");
  println("-----------------------------");
  println("Benutzter Path Algorithmus: " + data.getString("pathAlg"));
  println("Benutzter Speed Algorithmus: " + data.getString("speedAlg"));
}

// Auto mit id key spawnen
public void spawnCar(int key) {
  try{
  JSONArray cars = loadJSONObject(sketchPath + fileName).getJSONArray("Cars");
  for (int i = 0; i < cars.size(); i ++) {
    if (cars.getJSONObject(i).getInt("key") == key) {
      JSONObject car = cars.getJSONObject(i);
      // die Route (Liste von Fahrstuhl ids) in eine Liste von Edges umwandeln
      int[] indexRoute = car.getJSONArray("route").getIntArray();
      ArrayList<Street> route = new ArrayList<Street>();
      for (int j = 0; j < indexRoute.length - 1; j ++) {
        route.add(getTunnelByPosition(allElevators.get(indexRoute[j]).pos1, allElevators.get(indexRoute[j + 1]).pos1));
      }
      // Fahrstühle zur Route hinzufügen
      route.add(0, getElevatorByPosition(route.get(0).pos1));
      route.add(getElevatorByPosition(route.get(route.size() - 1).pos2));
      // checkpoint liste erstellen
      JSONArray checkpoints = car.getJSONArray("checkpoints");
      float[][] c = new float[checkpoints.size()][4];
      for (int j = 0; j < c.length; j ++){
        c[j] = checkpoints.getJSONArray(j).getFloatArray();
      }
      allCars.add (new Car (route, key, car.getJSONArray("accel").getFloatArray(), c));
    }
  }
  } catch(Exception e){
    println(e);
  }
}
class LoadingScreen {
  final int countCars = 10, radius = 300;
  PShape [] cars = new PShape[countCars];
  PVector [] rotationAxis = new PVector[countCars];
  float rotationZ = 0.f;

  LoadingScreen() {
    for (int i = 0; i < countCars; i ++) {
      float angle = i * TWO_PI / countCars;
      rotationAxis[i] = new PVector(radius * sin(angle), radius * cos(angle), 0);
      cars[i] = loadShape(sketchPath + "/Car.obj");
      cars[i].scale(25);
      cars[i].translate(0, -16, 0);
      cars[i].rotate(HALF_PI, 1, 0, 0);
      cars[i].rotate(- angle, 0, 0, 1);
      cars[i].translate(rotationAxis[i].x, rotationAxis[i].y, rotationAxis[i].z);
    }
  }

  public void display() {
    if (! error.equals("loading")) {    // show Error-message
      hint(DISABLE_DEPTH_TEST);
      cam.beginHUD();
      text(error, width/2, 100);
      cam.endHUD();
      hint(ENABLE_DEPTH_TEST);
    } else {
      hint(DISABLE_DEPTH_TEST);
      cam.beginHUD();
      text("Python Script is running...", width/2, 50);
      cam.endHUD();
      hint(ENABLE_DEPTH_TEST);
      rotate(rotationZ, 0, 0, 1);
      rotationZ += 0.05f;
      for (int i = 0; i < countCars; i ++) {
        pushMatrix();
        translate(0, 0, 100 * noise(rotationZ + i/5.f));
        cars[i].rotate(0.05f, rotationAxis[i].x, rotationAxis[i].y, rotationAxis[i].z);
        shape(cars[i]);
        popMatrix();
      }
    }
  }
}
class Terrain {
  ArrayList<PShape> terrainSlices = new ArrayList<PShape>();
  PShape terrainShape;
  int dim = terrainBorder / 10, scl = 20, heightOfHills = 50;
  float offset = 0.05f, drawOffset = - dim * scl / 2;

  public Terrain() {
    float zoff = 0;
    for (int z = 0; z < dim - 1; z ++) {
      float xoff = 0;
      terrainShape = createShape();
      terrainShape.beginShape(TRIANGLE_STRIP);
      terrainShape.noStroke();
      for (int x = 0; x < dim; x ++) {
        terrainShape.fill(random(25), map(noise(xoff, zoff), 0, 1, 255, 0), random(25), 100);
        float y = map(noise(xoff, zoff), 0, 1, -heightOfHills, heightOfHills);
        terrainShape.vertex(x * scl + drawOffset, y, z * scl + drawOffset);
        y = map(noise(xoff, zoff + offset), 0, 1, -heightOfHills, heightOfHills);
        terrainShape.vertex(x * scl + drawOffset, y, (z + 1) * scl + drawOffset);
        xoff += offset;
      }
      zoff += offset;
      terrainShape.endShape();
      terrainSlices.add(terrainShape);
    }
  }

  public void display() {
    for (PShape s : terrainSlices) {
      shape(s);
    }
  }
}
class Timer { //<>//
  float time  ;
  float[] spawnTimes = new float[0];
  int spawnTimeIndex = 0;

  Timer() {
    reset();
  }
  public void increment() {
    time += dt;
    while (spawnTimes.length > spawnTimeIndex && time >= spawnTimes[spawnTimeIndex]) {
      spawnCar(spawnTimeIndex);
      spawnTimeIndex ++;
    }
    if (time >= simDuration && dt != 0) {
      stopSimulation();
    }
  }
  public void reset() {
    dt = 0.04f;
    time = -dt + 0.001f;
    spawnTimeIndex = 0;
  }
  public void stop() {
    dt = 0.f;
  }
  public String getStr() {
    int h = PApplet.parseInt(time / 3600.f);
    int min = PApplet.parseInt(time / 60.f);
    int sec = PApplet.parseInt(time % 60);
    String result = "";
    if (h > 0) {
      result += h + ':';
    }
    if (sec < 10) {
      result += min + ":0" + sec;
    } else {
      result += min + ":" + sec;
    }
    return result;
  }
}
public void setupControlElements() { //<>// //<>//
  cp5 = new ControlP5(this);
  // Textfeld der Konsole
  consoleArea = cp5.addTextarea("txt")
    .setPosition(100, 150)
    .setSize(240, height - 300)
    .setFont(createFont("", 14))
    .setLineHeight(18)
    .setColor(color(0))
    .setColorBackground(color(200, 220))
  .setVisible(true);  
  
  console = cp5.addConsole(consoleArea);
  cp5.setAutoDraw(false);
  // benutzte Bilder laden
  tunnelTexture = loadImage(sketchPath + "/tunnelTexture.png");
}

// Function, um alle Dinge zu zeichnen, die nicht in der 3D-Scene sind, sondern zur Benutzerinteraktion genutzt werden
public void drawControlls() {
  hint(DISABLE_DEPTH_TEST);
  cam.beginHUD();
  cp5.draw();
  text(timer.getStr(), width - 150, 50);
  cam.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

public void pause() {
  pause = !pause;
  if (pause) {
    println("Pause");
  } else {
    println("Resume");
  }
}

// keyboard shortcuts
public void keyPressed() {
  switch(key) {
  case ' ' : 
    pause(); 
    break;
  case 'r' :  
    reset();
    break;
  case 's' :
    stopSimulation();
    break;
  case 'h' :
    consoleArea.setVisible(! signsVisible);
    signsVisible = ! signsVisible;
    break;
  default:
    break;
  }
}

public void mousePressed() {
  // disable cameras movement, if mouse is over control element
  if (consoleArea.isMouseOver()) {
    cam.setActive(false);
  }
}

public void mouseReleased() {
  // enable camera movement again
  if (! cam.isActive()) {
    cam.setActive(true);
  }
}

public void reset() {
  allCars.clear();
  allElevators.clear();
  allTunnels.clear();
  loadObjects();
  timer.reset();
  cam.setActive(true);
  console.clear();
  isLoading = false;
  pause = false;
  println("~ -----------------------------");
  println("~ ---Simulation-started---");
  println("~ -----------------------------");
}

public void stopSimulation() {
  timer.time = simDuration + .1f;
  timer.stop();
  println("~");
  println("--- Simulation stopped after " + timer.getStr() + " ---");
}

public Car getCarById(int id) {
  for (Car i : allCars) {
    if (i.id == id) {
      return i;
    }
  }
  return null;
}

// gibt den Tunnel zurück, der von Punkt p1 zu p2 verläuft
public Tunnel getTunnelByPosition(PVector p1, PVector p2) {
  for (Tunnel i : allTunnels) {
    if (i.pos1 == p1 && i.pos2 == p2) {
      return i;
    }
  }
  return null;
}

// gibt Fahrstuhl an Punkt p zurück
public Elevator getElevatorByPosition(PVector p) {
  for (Elevator i : allElevators) {
    if (i.pos1 == p) {
      return i;
    }
  }
  return null;
}

public boolean existsTunnel(PVector p1, PVector p2) {
  for (Tunnel i : allTunnels) {
    if (i.pos1 == p1 && i.pos2 == p2) { 
      return true;
    }
  } 
  return false;
}
  public void settings() {  fullScreen(P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GUI2" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
