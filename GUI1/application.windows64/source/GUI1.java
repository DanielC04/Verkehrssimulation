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

public class GUI1 extends PApplet {

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
final int color1 = color(0, 255, 0), color2 = color(255, 0, 0);
final String fileName = "/data_input.json";
String sketchPath;
PFont font;
// sonstige Variablen
PImage tunnelTexture;
float upperBorder;
int tab;
Elevator selectedElevator = null;
Tunnel selectedTunnel = null;
CityCenter selectedCityCenter = null;

public void setup() {
  
  frameRate(25);
  textSize(32);
  font = createFont("Georgia", 24);
  textFont(font);
  fill(0);
  sketchPath = sketchPath();
  if (sketchPath().contains("application.windows")){
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

public void draw() {
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
public class CityCenter {
  final int radius = 40;
  LatheStock shape;
  Ellipsoid ball;
  PVector pos;
  float weight;

  CityCenter (PVector p, float w) {
    pos = p;
    weight = w;
    // Grafik der Objekte einrichten
    PVector[] v = new PVector[] {
      new PVector(0, 185), 
      new PVector(60, 180), 
      new PVector(100, 150), 
      new PVector(120, 100), 
      new PVector(60, 100), 
      new PVector(30, 50), 
      new PVector(0, 0), 
    };
    Path path = new BCurve3D(v, 15);
    LatheSurface surface = new LatheSurface(path, 20);

    shape = new LatheStock(surface);
    shape.rotateByX(PI);
    shape.drawMode(S3D.SOLID);
    shape.fill(color(255, 50, 50, 150));
    shape.stroke(color(255, 0, 0));
    shape.addPickHandler(this, "cityCenterPicked");

    ball = new Ellipsoid(radius, radius, radius, 20, 20);
    ball.drawMode(S3D.SOLID);
    ball.fill(color(50));
    ball.moveTo(pos.add(new PVector(0, -100, 0)));
    moveX(pos.x);
  }

  public void display() {
    ball.draw(getGraphics());
    shape.draw(getGraphics());
  }

  public void cityCenterPicked(Shape3D s, int partNo, int partFlag) {
    deselectAll();
    // select City Center
    shape.drawMode(S3D.SOLID | S3D.WIRE);
    selectedCityCenter = this;
    cityCenterInfo.setVisible(true);
    cityCenterInfo.cityCenterWeight.setValue(weight);
  }

  public void deselect() {
    shape.drawMode(S3D.SOLID);
    cityCenterInfo.setVisible(false);
  }

  public void moveX(float value) {
    pos.x = value;
    shape.moveTo(pos.x, 20, pos.z);
    ball.moveTo(pos.x, -100, pos.z);
  }
  public void moveZ(float value) {
    pos.z = value;
    shape.moveTo(pos.x, 20, pos.z);
    ball.moveTo(pos.x, -100, pos.z);
  }

  public void calculateP() {
    for (Elevator e : allElevators) {
      float d = dist(pos.x, pos.z, e.pos.x, e.pos.z);
      float newP = upperBorder * pow(2.71828f, -0.5f * d * d / weight / weight);   // Normalverteilung mit Erwartungswert 0; Vertikal so skaliert, dass maximaler Wert upperBorder ist
      if (tab == 1) {
        e.spawnRateIn += newP;
      } else {
        e.spawnRateOut += newP;
      }
    }
  }
  public void delete() {
    if (tab == 1) {
      allCityCentersIn.remove(this);
    } else {
      allCityCentersOut.remove(this);
    }
    cityCenterInfo.setVisible(false);
    appointP();
  }
}

public void appointP() {
  for (Elevator e : allElevators) {
    if (tab == 1 && allCityCentersIn.size() > 0) { 
      e.spawnRateIn = 0;
    } else if (tab == 2 && allCityCentersOut.size() > 0){ 
      e.spawnRateOut = 0;
    }
  }
  if (tab == 1) {
    for (CityCenter i : allCityCentersIn) {
      i.calculateP();
    }
  } else {
    for (CityCenter i : allCityCentersOut) {
      i.calculateP();
    }
  }
  for (Elevator e : allElevators) {
    e.setColors();
  }
}
class CityCenterInfo {
  final int boxHeight = 340, boxWidth = 300, drawPosX = 50, drawPosY = height/2 - boxHeight/2, graphicsPosX = width - 100, graphicsPosY = 200;
  Numberbox cityCenterInputX, cityCenterInputZ, cityCenterWeight, inputUpperBorder;
  PGraphics graphics, scaleGraphics;
  boolean isVisible;

  CityCenterInfo() {
    // Grafik mit grauer Box und Text erstellen
    graphics = createGraphics(boxWidth, boxHeight);
    graphics.beginDraw();
    graphics.background(color(200, 200));
    graphics.fill(0);
    graphics.textFont(createFont("", 32));
    graphics.text("City Center: ", 20, 40);
    graphics.textFont(createFont("", 28));
    graphics.text("Position: ", 40, 80);
    graphics.text("-> x", 100, 120);
    graphics.text("-> z", 100, 200);
    graphics.text("Reach", 40, 300);
    graphics.endDraw();
    
    // Grafik der Farbverteilung (rechte Seite des Programms) erstellen
    scaleGraphics = createGraphics(50, height - 250);
    scaleGraphics.beginDraw();
    for (int i = 0; i < height - 200; i ++) {
      scaleGraphics.stroke(lerpColor(color2, color1, i / PApplet.parseFloat(height - 100)));
      scaleGraphics.line(0, i, 50, i);
    }
    scaleGraphics.endDraw();
    
    // Numberboxes einrichten
    cityCenterInputX = cp5.addNumberbox("cityCenterInputX")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 90)
      .setSize(80, 40)
      .setMultiplier(-0.1f)
      .setRange(- border, border);
    cityCenterInputZ = cp5.addNumberbox("cityCenterInputZ")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 180)
      .setSize(80, 40)
      .setMultiplier(-0.1f)
      .setRange(- border, border);
    cityCenterWeight = cp5.addNumberbox("cityCenterWeight")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 270)
      .setSize(80, 40)
      .setRange(0, 2000)
      .setValue(150)
      .setMultiplier(-0.5f);
    inputUpperBorder = cp5.addNumberbox("upperBorder")
      .setLabel("")
      .setPosition(width - 100, 150)
      .setSize(50, 30)
      .setRange(0, 200)
      .setMultiplier(-0.1f)
      .setValue(upperBorder);

    setVisible(false);
  }
  
  public void display() {
    if (isVisible) {
      image(graphics, drawPosX, drawPosY);
    }
    image(scaleGraphics, graphicsPosX, graphicsPosY);    // Farbverteilungsskala immer anzeigen
  }
  
  public void setVisible(boolean b) {
    cityCenterInputX.setVisible(b);
    cityCenterInputZ.setVisible(b);
    cityCenterWeight.setVisible(b);
    isVisible = b;
    if (b) {
      // set values to numberboxes
      cityCenterInputX.setValue(selectedCityCenter.pos.x / scale);
      cityCenterInputZ.setValue(selectedCityCenter.pos.z / scale);
      defaultInfo.setVisible(false);
    }
  }

  public boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight || inputUpperBorder.isMouseOver() ;
  }
}
// callback functions der Numberboxes
public void cityCenterInputX(int value) {
  if (selectedCityCenter != null) {
    selectedCityCenter.moveX(value * scale);
  }
  appointP();
}

public void cityCenterInputZ(int value) {
  if (selectedCityCenter != null) {
    selectedCityCenter.moveZ(value * scale);
  }
  appointP();
}

public void cityCenterWeight(int value) {
  if (selectedCityCenter != null){
    selectedCityCenter.weight = value;
    appointP();
  }
}

public void upperBorder(int value) {
  upperBorder = value;
  appointP();
}
class DefaultInfo {
  final int boxHeight = 620, boxWidth = 400, drawPosX = 50, drawPosY = height/2 - boxHeight/2;
  Numberbox inputA, inputDeA, inputSafetyDist, inputSimDur, inputElevatorV;
  Textfield pathAlg, speedAlg;
  PGraphics graphics;
  boolean isVisible = true;

  DefaultInfo() {
    // Grafik mit grauer Box und Text erstellen
    graphics = createGraphics(boxWidth, boxHeight);
    graphics.beginDraw();
    graphics.background(color(200, 200));
    graphics.fill(0);
    graphics.textFont(createFont("", 28));
    graphics.text("Settings: ", 20, 40);
    graphics.textFont(createFont("", 24));
    graphics.text("max acceleration", 40, 80);
    graphics.text("max deacceleration", 40, 160);
    graphics.text("Safety distance", 40, 240);
    graphics.text("Simulation duration", 40, 320);
    graphics.text("Max Elevator speed", 40, 400);
    graphics.text("Path algorithm", 40, 480);
    graphics.text("Speed algorithm", 40, 560);
    graphics.endDraw();
    //setup Numberboxes
    inputA = cp5.addNumberbox("inputA")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 50)
      .setSize(80, 40)
      .setMultiplier(-0.01f)
      .setRange(0, 8);
    inputDeA = cp5.addNumberbox("inputDeA")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 130)
      .setSize(80, 40)
      .setMultiplier(-0.01f)
      .setRange(0, 8);
    inputSafetyDist = cp5.addNumberbox("inputSafetyDist")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 210)
      .setSize(80, 40)
      .setMultiplier(-0.01f)
      .setRange(0, 8);
    inputSimDur = cp5.addNumberbox("inputSimDur")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 290)
      .setSize(80, 40)
      .setMultiplier(-0.3f)
      .setRange(0, 1000);
    inputElevatorV = cp5.addNumberbox("elevatorInputV")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 370)
      .setSize(80, 40)
      .setRange(0, 25)
      .setMultiplier(-0.05f);
    // Textfelder setup
    pathAlg = cp5.addTextfield("pathAlg")
      .setLabel("")
      .setPosition(drawPosX + 60, drawPosY + 490)
      .setFont(createFont("", 24))
      .setSize(300, 26);
    speedAlg = cp5.addTextfield("speedAlg")
      .setLabel("")
      .setPosition(drawPosX + 60, drawPosY + 570)
      .setFont(createFont("", 24))
      .setSize(300, 26);
  }
  public void display() {
    if (isVisible) {
      image(graphics, drawPosX, drawPosY);
    }
  }
  
  public void setVisible(boolean b) {
    isVisible = b;
    if (pathAlg != null) {
      pathAlg.setVisible(b);
      speedAlg.setVisible(b);
      inputA.setVisible(b);
      inputDeA.setVisible(b);
      inputSafetyDist.setVisible(b);
      inputSimDur.setVisible(b);
      inputElevatorV.setVisible(b);
    }
  }

  public boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight;
  }
}
public class Elevator {
  Box elev;
  ArrayList<Tunnel> tunnels = new ArrayList<Tunnel>();
  PVector pos;
  int id, spawnRateIn, spawnRateOut;
  float vmax;

  public Elevator(PVector p, float v) {
    pos = p;
    vmax = v;
    setupBox();
  }
  public void display() { 
    elev.draw(getGraphics());
  }

  public void setupBox() {
    elev = new Box(40, pos.y, 100);
    elev.moveTo(pos.x, pos.y/2, pos.z);
    elev.drawMode(S3D.SOLID | S3D.WIRE);
    elev.addPickHandler(this, "elevatorPicked");
    elev.strokeWeight(4);
    elev.stroke(0);
    setColors();
  }

  public void deselect() {
    elev.stroke(0xff000000);
    selectedElevator = null;
  }

  public void elevatorPicked(Shape3D shape, int partNo, int partFlag) {
    if (selectedElevator != null && keyPressed && key == CODED && keyCode == SHIFT) {
      // neuen Tunnel erstellen, falls vor diesem ein anderer Fahrstuhl ausgewählt war und SHIFT gedrückt wird
      if (! existsTunnel(selectedElevator, this) && this != selectedElevator) {
        allTunnels.add(new Tunnel(selectedElevator, this, 40));
        allTunnels.get(allTunnels.size() - 1).tunnelPicked(null, 0, 0);            // erstellten Tunnel direkt auswählen
      } else {
        popup.addText("Please select another Elevator!");                          // Es wird versucht, einen Tunnel mit zweimal demselben Elevator zu erstellt
      }
    } else {
      // Elevator auswählen
      deselectAll();
      elev.stroke(color(255, 0, 0));
      selectedElevator = this;
      elevInfo.setVisible(true);
    }
  }
  
  public void moveX(int newX) {
    pos.x = newX;
    elev.moveTo(pos.x, pos.y/2, pos.z);
    refreshPositionTunnels();
    appointP();
  }
  public void moveY(int newY) {
    pos.y = newY;
    elev.pickable(false);
    setupBox();                                // Es gibt kein Funktion, um die Maße einer Box zu ändern -> wird die Tiefe eines Elevators geändert, muss eine neue Box erstellt werden
    elev.stroke(color(255, 0, 0));
    refreshPositionTunnels();
  }
  public void moveZ(int newZ) {
    pos.z = newZ;
    elev.moveTo(pos.x, pos.y/2, pos.z);
    refreshPositionTunnels();
    appointP();
  }
  // Position aller mit diesem Fahrstuhl verbunden Tunnel anpassen
  public void refreshPositionTunnels() {
    for (Tunnel i : tunnels) {
      i.tunnel.pickable(false);
      i.setupGraphics();
    }
  }
  // Farben des Fahrstuhls anhand der SpawnRate anpassen
  public void setColors() {
    if (tab == 1) {
      elev.fill(lerpColor(color1, color2, spawnRateIn / cityCenterInfo.inputUpperBorder.getValue()));
    } else {
      elev.fill(lerpColor(color1, color2, spawnRateOut / cityCenterInfo.inputUpperBorder.getValue()));
    }
  }
  // Fahrstuhl und alle verbundenen Tunnel löschen
  public void delete() {
    allElevators.remove(this);
    for (Tunnel i : tunnels) {
      i.delete();
    }
    elevInfo.setVisible(false);
  }
}
class ElevatorInfo {
  final int boxHeight = 460, boxWidth = 300, drawPosX = 50, drawPosY = height/2 - boxHeight/2;
  Numberbox inputX, inputY, inputZ, elevatorInputV;
  PGraphics graphics;
  boolean isVisible;

  ElevatorInfo() {
    graphics = createGraphics(boxWidth, boxHeight);
    graphics.beginDraw();
    graphics.background(color(200, 200));
    graphics.fill(0);
    graphics.textFont(createFont("", 28));
    graphics.text("Elevator: ", 20, 40);
    graphics.textFont(createFont("", 24));
    graphics.text("Position: ", 25, 80);
    graphics.text("-> x", 100, 120);
    graphics.text("-> y", 100, 200);
    graphics.text("-> z", 100, 280);
    graphics.text("Spawn rate in", 25, 360);
    graphics.text("Spawn rate out", 25, 440);
    graphics.endDraw();

    inputX = cp5.addNumberbox("inputX")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 90)
      .setSize(80, 40)
      .setMultiplier(-0.1f)
      .setRange(- border, border);
    inputY = cp5.addNumberbox("inputY")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 170)
      .setSize(80, 40)
      .setMultiplier(-0.1f)
      .setRange(0, border);
    inputZ = cp5.addNumberbox("inputZ")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 250)
      .setSize(80, 40)
      .setMultiplier(-0.1f)
      .setRange(- border, border);
    setVisible(false);
  }
  public void display() {
    if (isVisible) {
      image(graphics, drawPosX, drawPosY);
      text(selectedElevator.spawnRateIn, drawPosX + 230, drawPosY + 360);
      text(selectedElevator.spawnRateOut, drawPosX + 230, drawPosY + 440);
    }
  }

  public void setVisible(boolean bool) {
    if (bool) {
      defaultInfo.setVisible(false);
    }
    inputX.setVisible(bool);
    inputY.setVisible(bool);
    inputZ.setVisible(bool);
    isVisible = bool;
    refresh();
  }
  // Daten der Numberboxes neu laden
  public void refresh() {
    if (selectedElevator != null) {
      inputX.setValue(selectedElevator.pos.x / scale);
      inputY.setValue(selectedElevator.pos.y / scale);
      inputZ.setValue(selectedElevator.pos.z / scale);
    }
  }

  public boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight;
  }
}
// callback functions der Numberboxes
public void inputX(int value) {
  if (selectedElevator != null) {
    selectedElevator.moveX(value * scale);
  }
}

public void inputY(int value) {
  if (selectedElevator != null) {
    selectedElevator.moveY(value * scale);
  }
}

public void inputZ(int value) {
  if (selectedElevator != null) {
    selectedElevator.moveZ(value * scale);
  }
}
public class InfoArea {
  boolean isVisible = false;
  Textarea shortcuts, pythonHelp;
  InfoArea() {
    shortcuts = cp5.addTextarea("shortcuts")
      .setSize(1300, 300)
      .setPosition(500, 750)
      .setColor(0)
      .setFont(font)
      .setLineHeight(28)
      .setColorBackground(color(220, 225))
      .setColorForeground(color(230, 225))
      .setText("Shortcuts:\n"
      + "- TAB: GUI2 starten \n"
      + "- E: neuen Fahrstuhl erstellen \n"
      + "- C: neuen CityCenter erstellen \n"
      + "- D: aktuell ausgewähltes Objekt löschen \n"
      + "- A: alle Objekte löschen \n"
      + "- S: Daten speichern \n"
      + "- P: Pythonprogramm starten \n"
      + "- SHIFT + einen zweiten Fahrstuhl anklicken: neuen Tunnel erstellen \n"
      + "- Doppelklick mit Maus: Kameraposition zurück setzen");

    pythonHelp = cp5.addTextarea("pythonHelp")
      .setSize(1300, 600)
      .setPosition(500, 100)
      .setColor(0)
      .setFont(font)
      .setLineHeight(28)
      .setColorBackground(color(220, 225))
      .setColorForeground(color(230, 255));
    try {
      String [] text = loadStrings(sketchPath + "/infoText.txt");
      assert text != null;
      for (int i = 0; i < text.length; i ++) {
        pythonHelp.append(text[i]);
        pythonHelp.append("\n");
      }
    } catch(Error e) {
      pythonHelp.setText("Fehler beim Laden des Hilfetextes!");
    }

    PImage [] imgs = {loadImage(sketchPath + "/helpButton.png"), loadImage(sketchPath + "/helpButton.png"), loadImage(sketchPath + "/helpButton.png")};
    cp5.addButton("help")
      .setPosition(width - 100, 75)
      .setImages(imgs)
      .updateSize();

    setVisible(false);
  }

  public void setVisible(boolean b) {
    isVisible = b;
    shortcuts.setVisible(b);
    pythonHelp.setVisible(b);
    cam.setActive(!b);
    defaultInfo.setVisible(!b);
  }

  public boolean isMouseOver() {
    return isVisible && (shortcuts.isMouseOver() || pythonHelp.isMouseOver());
  }
}
public void help() {
  infoArea.setVisible(! infoArea.isVisible);
}
public void loadData() {
  try {
    JSONObject data = loadJSONObject(sketchPath + fileName);
    // input general settings
    defaultInfo.inputA.setValue(data.getFloat("maxAcc"));
    defaultInfo.inputDeA.setValue(data.getFloat("maxDeacc"));
    defaultInfo.inputSafetyDist.setValue(data.getFloat("safetyDist"));
    defaultInfo.inputSimDur.setValue(data.getFloat("simDuration"));
    defaultInfo.inputElevatorV.setValue(data.getFloat("elevatorSpeed"));
    defaultInfo.pathAlg.setText(data.getString("pathAlg"));
    defaultInfo.speedAlg.setText(data.getString("speedAlg"));

    // input CityCenter
    JSONArray cityCenterIn = data.getJSONObject("CityCenter").getJSONArray("In");
    for (int i = 0; i < cityCenterIn.size(); i ++) {
      JSONObject cc = cityCenterIn.getJSONObject(i);
      PVector pos = new PVector(cc.getFloat("x") * scale, 0, cc.getFloat("z") * scale);
      allCityCentersIn.add(new CityCenter(pos, cc.getFloat("weight")));
    }
    JSONArray cityCenterOut = data.getJSONObject("CityCenter").getJSONArray("Out");
    for (int i = 0; i < cityCenterOut.size(); i ++) {
      JSONObject cc = cityCenterOut.getJSONObject(i);
      PVector pos = new PVector(cc.getFloat("x") * scale, 0, cc.getFloat("z") * scale);
      allCityCentersOut.add(new CityCenter(pos, cc.getFloat("weight")));
    }
    cityCenterInfo.inputUpperBorder.setValue(data.getJSONObject("CityCenter").getFloat("upperBorder"));

    // load Nodes
    JSONArray nodes = data.getJSONArray("Elevators");
    for (int i = 0; i < nodes.size(); i ++) {
      JSONObject node = nodes.getJSONObject(i);
      allElevators.add(new Elevator(new PVector(node.getFloat("x") * scale, node.getFloat("y") * scale, node.getFloat("z") * scale), node.getFloat("vmax")));
    }

    // load tunnels
    JSONArray tunnels = data.getJSONArray("Tunnels");
    for (int i = 0; i < tunnels.size(); i ++) {
      JSONObject tunnel = tunnels.getJSONObject(i);
      Elevator e1 = allElevators.get(tunnel.getInt("elev1"));
      Elevator e2 = allElevators.get(tunnel.getInt("elev2"));
      allTunnels.add(new Tunnel(e1, e2, tunnel.getFloat("vmax")));
    }
    popup.addText("Loaded Objects successfully");
  } 
  catch(Exception e) {
    popup.addText("Error while loading Objects!");
    println(e);
  }
}

public void saveData() {
  try {
    JSONObject data = loadJSONObject(sketchPath + fileName);
    // save general Settings
    data.setFloat("maxAcc", defaultInfo.inputA.getValue());
    data.setFloat("maxDeacc", defaultInfo.inputDeA.getValue());
    data.setFloat("safetyDist", defaultInfo.inputSafetyDist.getValue());
    data.setFloat("simDuration", defaultInfo.inputSimDur.getValue());
    data.setFloat("elevatorSpeed", defaultInfo.inputElevatorV.getValue());
    data.setString("pathAlg", defaultInfo.pathAlg.getText());
    data.setString("speedAlg", defaultInfo.speedAlg.getText());
    // save CityCenter
    JSONObject CityCenters = new JSONObject();
    // stuff for tab 1 -> incoming traffic
    JSONArray in = new JSONArray();
    for (int j = 0; j < allCityCentersIn.size(); j ++) {
      CityCenter i = allCityCentersIn.get(j);
      JSONObject cc = new JSONObject();
      cc.setFloat("x", i.pos.x / scale);
      cc.setFloat("z", i.pos.z / scale);
      cc.setFloat("weight", i.weight);
      in.setJSONObject(j, cc);
    }
    CityCenters.setJSONArray("In", in);
    // stuff for tab 2 -> outgoing traffic
    JSONArray out = new JSONArray();
    for (int j = 0; j < allCityCentersOut.size(); j ++) {
      CityCenter i = allCityCentersOut.get(j);
      JSONObject cc = new JSONObject();
      cc.setFloat("x", i.pos.x / scale);
      cc.setFloat("z", i.pos.z / scale);
      cc.setFloat("weight", i.weight);
      out.setJSONObject(j, cc);
    }
    CityCenters.setFloat("upperBorder", upperBorder);
    CityCenters.setJSONArray("Out", out);  

    // save Elevators
    JSONArray elevators = new JSONArray();
    for (Elevator e : allElevators) {
      if (elevatorOverlapsOther(e)){
        popup.addText("An elevator overlaps another!");
        throw new IllegalArgumentException("Elevator overlap");
      }
      JSONObject elevator = new JSONObject();
      elevator.setFloat("x", e.pos.x / scale);
      elevator.setFloat("y", e.pos.y / scale);
      elevator.setFloat("z", e.pos.z / scale);
      elevator.setFloat("spawnRateIn", e.spawnRateIn);
      elevator.setFloat("spawnRateOut", e.spawnRateOut);
      elevator.setFloat("vmax", e.vmax);
      elevators.setJSONObject(elevators.size(), elevator);
    }

    // save Tunnels
    JSONArray tunnels = new JSONArray();
    for (Tunnel t : allTunnels) {
      JSONObject tunnel = new JSONObject();
      tunnel.setInt("elev1", idOfElevator(t.elev1));
      tunnel.setInt("elev2", idOfElevator(t.elev2));
      tunnel.setFloat("vmax", t.vmax);

      tunnels.setJSONObject(tunnels.size(), tunnel);
    }

    // set jsonobjects and write them into file 
    data.setJSONObject("CityCenter", CityCenters);
    data.setJSONArray("Elevators", elevators);
    data.setJSONArray("Tunnels", tunnels);

    saveJSONObject(data, sketchPath + fileName);

    popup.addText("Saved Data");
  } 
  catch (Exception e) {
    popup.addText("Problem while saving data");
    println(e);
  }
}
class Terrain {
  final int dim = border / 10, scl = 20, heightOfHills = 50;
  final float offset = 0.05f, drawOffset = - dim * scl / 2;
  ArrayList<PShape> terrainSlices = new ArrayList<PShape>();

  public Terrain() {
    float zoff = 0;
    for (int z = 0; z < dim - 1; z ++) {
      float xoff = 0;
      PShape terrainSlice = createShape();
      terrainSlice.beginShape(TRIANGLE_STRIP);
      terrainSlice.noStroke();
      for (int x = 0; x < dim; x ++) {
        terrainSlice.fill(random(25), map(noise(xoff, zoff), 0, 1, 255, 0), random(25), 200);
        float y = map(noise(xoff, zoff), 0, 1, -heightOfHills, heightOfHills);
        terrainSlice.vertex(x * scl + drawOffset, y, z * scl + drawOffset);
        y = map(noise(xoff, zoff + offset), 0, 1, -heightOfHills, heightOfHills);
        terrainSlice.vertex(x * scl + drawOffset, y, (z + 1) * scl + drawOffset);
        xoff += offset;
      }
      zoff += offset;
      terrainSlice.endShape();
      terrainSlices.add(terrainSlice);
    }
  }

  public void display() {
    for (PShape s : terrainSlices) {
      shape(s);
    }
  }
}
public class Tunnel {
  final int diameter = 20;
  Elevator elev1, elev2;
  Path path;
  Oval base;
  Tube tunnel;
  boolean isLowerTunnel = false;
  float len, vmax;

  public Tunnel(Elevator e1, Elevator e2, float v) {
    elev1 = e1;
    e1.tunnels.add(this);
    elev2 = e2;
    e2.tunnels.add(this);
    vmax = v;
    if (existsTunnel(elev2, elev1)){
      isLowerTunnel = true;
    }
    base = new Oval(diameter, 20);
    setupGraphics();
  }

  public void setupGraphics() {
    len = elev1.pos.dist(elev2.pos) / scale;
    PVector pos1 = elev1.pos.copy(), pos2 = elev2.pos.copy();
    if (isLowerTunnel){
      pos1.add(0, 40, 0);
      pos2.add(0, 40, 0);
    }
    path = new Linear(pos1, pos2, 1);
    tunnel = new Tube(path, base);
    tunnel.drawMode(S3D.TEXTURE);
    tunnel.texture(tunnelTexture, S3D.BODY).uv(0, this.len * scale/40, 0, 6, S3D.BODY);
    tunnel.visible(false, S3D.END0 | S3D.END1);
    tunnel.stroke(color(255, 0, 0));
    tunnel.addPickHandler(this, "tunnelPicked");
  }

  public void display() {
    tunnel.draw(getGraphics());
  }

  public void select() {
    tunnel.drawMode(S3D.TEXTURE | S3D.WIRE);
    selectedTunnel = this;
    tunnelInfo.setVisible(true);
  }

  public void deselect() {
    tunnel.drawMode(S3D.TEXTURE);
    selectedTunnel = null;
  }

  public void tunnelPicked(Shape3D shape, int partNo, int partFlag) {
    deselectAll();
    select();
  }

  public void delete() {
    allTunnels.remove(this);
    tunnelInfo.setVisible(false);
  }
}
class TunnelInfo {
  final int boxHeight = 200, boxWidth = 300, drawPosX = 50, drawPosY = height/2 - boxHeight/2;
  Numberbox tunnelInputV;
  PGraphics graphics;
  boolean isVisible;
 
  TunnelInfo() {
    graphics = createGraphics(boxWidth, boxHeight);
    graphics.beginDraw();
    graphics.background(color(200, 200));
    graphics.fill(0);
    graphics.textFont(createFont("", 28));
    graphics.text("Tunnel: ", 20, 40);
    graphics.textFont(createFont("", 24));
    graphics.text("Length", 40, 160);
    graphics.text("v", 40, 80);
    graphics.textFont(createFont("", 18));
    graphics.text("max", 52, 84);
    graphics.endDraw();

    tunnelInputV = cp5.addNumberbox("tunnelInputV")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 50)
      .setSize(80, 40)
      .setRange(0, 60)
      .setMultiplier(-0.2f);
    setVisible(false);
  }
  public void display() {
    if (isVisible) {
      image(graphics, drawPosX, drawPosY);
      text(selectedTunnel.len, drawPosX + 180, drawPosY + 160);
    }
  }

  public void setVisible(boolean bool) {
    if (bool){
      defaultInfo.setVisible(false);
    }
    tunnelInputV.setVisible(bool);
    isVisible = bool;
    refresh();
  }
  // Wert der Maximalgeschwindigkeit des aktuellen Tunnels an Numberbox
  public void refresh() {
    if (selectedTunnel != null) {
      tunnelInputV.setValue(selectedTunnel.vmax);
    }
  }

  public boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight;
  }
}
// callback function
public void tunnelInputV(int value) {
  if (selectedTunnel != null) {
    selectedTunnel.vmax = value;
  }
}
// helping class to display text for a defined amount of time (showTime)
class PopupText {
  ArrayList<String> texts = new ArrayList<String>();
  float time;
  float showTime = 1.5f;

  public PopupText() {
  }
  public void drawPopup() {
    if (texts.size() > 0) {
      if (time < showTime) {
        text(texts.get(0), width/2 - texts.get(0).length() * 5, height - 50);
        time += 0.04f;
      } else {
        texts.remove(0);
        time = 0;
      }
    }
  }
  // add a Text to display; only if text isn't already on waiting list
  public void addText(String text) {
    if (! texts.contains(text)) {
      texts.add(text);
    }
  }
}
// setup aller IO-Elemente
public void setupControlElements() {
  cp5 = new ControlP5(this);
  // cp5 soll Controller nicht automatisch zeichnen; stattdessen: drawControlls() -> Numberboxes, ... werden nicht in die 3D-Scene gemalt, sondern sind relativ zur Kamera statisch
  cp5.setAutoDraw(false);
  // setup buttons der tabs
  buttonIn = cp5.addButton("in")
    .setSize(width/2, 50)
    .setPosition(0, 0);
  buttonOut = cp5.addButton("out")
    .setSize(width/2, 50)
    .setPosition(width/2, 0);
}

public void drawControlls() {
    // alle Dinge zeichnen, die unabhängig von Kamerabewegungen sein sollen
    hint(DISABLE_DEPTH_TEST);
    cam.beginHUD();
    elevInfo.display();
    tunnelInfo.display();
    cityCenterInfo.display();
    defaultInfo.display();
    cp5.draw();
    popup.drawPopup();
    cam.endHUD();
    hint(ENABLE_DEPTH_TEST);
}

public void keyPressed() {
  if (! defaultInfo.pathAlg.isInside() && ! defaultInfo.speedAlg.isInside()) {
    switch(key) {
    case 'e' : 
      addElevator(); 
      break;
    case 'c' : 
      addCityCenter(); 
      break;
    case 'd' : 
      delete(); 
      break;
    case 'a' : 
      deleteAll(); 
      break;
    case 's' : 
      saveData(); 
      break;
    case 'p' : 
      runPython(); 
      break;
    default:
      break;
    }
    if (keyCode==TAB) {
      runOtherGUI();
    }
  }
}
public void mouseClicked() {
  // Falls Maus nichts angeklickt hat: aktuell ausgewähltes Objekt deselect()
  Picked picked = Shape3D.pick(this, getGraphics(), mouseX, mouseY);
  if (picked == null && ! isMouseOverControl()) {
    deselectAll();
  }
}

public void mousePressed() {
  // Kamerabewegung abstellen, falls eines der IO-Objekte angeklickt ist
  if (isMouseOverControl()) {
    cam.setActive(false);
  }
}

public void mouseReleased() {
  // Kamerabewegung wieder erlauben
  if (! cam.isActive() && ! infoArea.isVisible) {
    cam.setActive(true);
  }
}

// return whether mouse is over any control element
public boolean isMouseOverControl() {
  return elevInfo.isMouseOver() || tunnelInfo.isMouseOver() || cityCenterInfo.isMouseOver() || defaultInfo.isMouseOver() || buttonIn.isMouseOver() || buttonOut.isMouseOver();
}

// callback function von Button "in"
public void in () {
  tab = 1;
  if (selectedCityCenter != null) {
    selectedCityCenter.deselect();
  }
  // Farben der Tab-Buttons ändern
  buttonIn.setColorBackground(color(0, 116, 217));
  buttonIn.setColorForeground(color(0, 116, 217));
  buttonIn.setColorActive(color(0, 116, 217));
  buttonOut.setColorBackground(color(0, 45, 90));
  buttonOut.setColorForeground(color(0, 45, 90));
  buttonOut.setColorActive(color(0, 45, 90));
  // spawnRate neu zuweisen und Farben der Elevators erneuern
  appointP();
}
// callback function von button "out"
public void out () {
  tab = 2;
  if (selectedCityCenter != null) {
    selectedCityCenter.deselect();
  }
  // Farben der Tab-Buttons ändern
  buttonOut.setColorBackground(color(0, 116, 217));
  buttonOut.setColorForeground(color(0, 116, 217));
  buttonOut.setColorActive(color(0, 116, 217));
  buttonIn.setColorBackground(color(0, 45, 90));
  buttonIn.setColorForeground(color(0, 45, 90));
  buttonIn.setColorActive(color(0, 45, 90));
  // spawnRate neu zuweisen und Farben der Elevators erneuern
  appointP();
}

// ----------------
// helping funtions
// ----------------

// deselect das aktuell ausgewählte Objekt
public void deselectAll() {
  if (selectedTunnel != null) {
    selectedTunnel.deselect();
  } else if (selectedElevator != null) {
    selectedElevator.deselect();
  } else if (selectedCityCenter != null) {
    selectedCityCenter.deselect();
  }
  tunnelInfo.setVisible(false);
  elevInfo.setVisible(false);
  cityCenterInfo.setVisible(false);
  defaultInfo.setVisible(true);
}

// neuen Elevator erstellen; keyEvent von E
public void addElevator() {
  PVector pos = new PVector(0, 5 * scale, 0);
  Elevator e = new Elevator(pos, 25);
  while (elevatorOverlapsOther(e)) {
    pos.add(0, 0, 60);
    e = new Elevator(pos, 25);
  }
  allElevators.add(e);
  appointP();
  if (selectedElevator != null) {
    selectedElevator.deselect();
  }
  allElevators.get(allElevators.size() - 1).elevatorPicked(null, 0, 0);
  selectedElevator = allElevators.get(allElevators.size() - 1);
}

// neuen CityCenter erstellen; keyEvent von C
public void addCityCenter() {
  PVector pos = new PVector(0, 0, 0);
  CityCenter newCityCenter = new CityCenter(pos, 150);
  while (cityCenterOverlapsOther(newCityCenter)) {
    pos.x += 150;
    newCityCenter = new CityCenter(pos, 150);
  }
  newCityCenter.cityCenterPicked(null, 0, 0);
  if (tab == 1) {
    allCityCentersIn.add(newCityCenter);
  } else {
    allCityCentersOut.add(newCityCenter);
  }
  appointP();
}

// ausgewähltes Objekt löschen; keyEvent von D
public void delete() {
  if (selectedElevator != null) {
    selectedElevator.delete();
    popup.addText("Deleted Elevator successfully");
  } else if (selectedTunnel != null) {
    selectedTunnel.delete();
    popup.addText("Deleted Tunnel successfully");
  } else if (selectedCityCenter != null) {
    selectedCityCenter.delete();
    popup.addText("Deleted CityCenter successfully");
  }
}

// alles löschen; keyevent von A
public void deleteAll() {
  allElevators.clear();
  allTunnels.clear();
  allCityCentersIn.clear();
  allCityCentersOut.clear();
}

// pythonScript starten, keyevent von P
public void runPython() {
  saveData();
  try {
    String[] cmd = {"python", new File(sketchPath).getParentFile().getAbsolutePath() + "/Code/Main.py"};
    exec(cmd);
    popup.addText("Started Python sketch");
  } 
  catch(Exception e) {
    popup.addText("Error! Python sketch not started!");
    println(e);
  }
}

public void runOtherGUI() {
  try {
    launch(new File(sketchPath).getParentFile().getAbsolutePath() + "/GUI2.lnk");
    popup.addText("Starting GUI2...");
  } 
  catch(Exception e) {
    println(e);
    popup.addText("Error! GUI2 not started!");
  }
}

public boolean elevatorOverlapsOther(Elevator e) {
  for (Elevator i : allElevators) {
    if (e != i && abs(e.pos.x - i.pos.x) <= 40 && abs(e.pos.z - i.pos.z) <= 100) {
      return true;
    }
  }
  return false;
}
public boolean cityCenterOverlapsOther(CityCenter c1) {
  if (tab == 1) {
    for (CityCenter c2 : allCityCentersIn) {
      if (c1 != c2 && dist(c1.pos.x, c1.pos.z, c2.pos.x, c2.pos.z) <= 150) {
        return true;
      }
    }
  } else {
    for (CityCenter c2 : allCityCentersOut) {
      if (c1 != c2 && dist(c1.pos.x, c1.pos.z, c2.pos.x, c2.pos.z) <= 150) {
        return true;
      }
    }
  }
  return false;
}

// gibt zurück, ob Tunnel von Elevator e1 zu e2 bereits existiert
public boolean existsTunnel(Elevator e1, Elevator e2) {
  for (Tunnel i : allTunnels) {
    if ((i.elev1 == e1 && i.elev2 == e2)) {
      return true;
    }
  }
  return false;
}

public int idOfElevator(Elevator e) {
  for (int i = 0; i < allElevators.size(); i ++) {
    if (allElevators.get(i) == e) {
      return i;
    }
  }
  return 0;
}
  public void settings() {  fullScreen(P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GUI1" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
