// helping class to display text for a defined amount of time (showTime)
class PopupText {
  ArrayList<String> texts = new ArrayList<String>();
  float time;
  float showTime = 1.5;

  public PopupText() {
  }
  void drawPopup() {
    if (texts.size() > 0) {
      if (time < showTime) {
        text(texts.get(0), width/2 - texts.get(0).length() * 5, height - 50);
        time += 0.04;
      } else {
        texts.remove(0);
        time = 0;
      }
    }
  }
  // add a Text to display; only if text isn't already on waiting list
  void addText(String text) {
    if (! texts.contains(text)) {
      texts.add(text);
    }
  }
}
// setup aller IO-Elemente
void setupControlElements() {
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

void drawControlls() {
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

void keyPressed() {
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
void mouseClicked() {
  // Falls Maus nichts angeklickt hat: aktuell ausgewähltes Objekt deselect()
  Picked picked = Shape3D.pick(this, getGraphics(), mouseX, mouseY);
  if (picked == null && ! isMouseOverControl()) {
    deselectAll();
  }
}

void mousePressed() {
  // Kamerabewegung abstellen, falls eines der IO-Objekte angeklickt ist
  if (isMouseOverControl()) {
    cam.setActive(false);
  }
}

void mouseReleased() {
  // Kamerabewegung wieder erlauben
  if (! cam.isActive() && ! infoArea.isVisible) {
    cam.setActive(true);
  }
}

// return whether mouse is over any control element
boolean isMouseOverControl() {
  return elevInfo.isMouseOver() || tunnelInfo.isMouseOver() || cityCenterInfo.isMouseOver() || defaultInfo.isMouseOver() || buttonIn.isMouseOver() || buttonOut.isMouseOver();
}

// callback function von Button "in"
void in () {
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
void out () {
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
void deselectAll() {
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
void addElevator() {
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
void addCityCenter() {
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
void delete() {
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
void deleteAll() {
  allElevators.clear();
  allTunnels.clear();
  allCityCentersIn.clear();
  allCityCentersOut.clear();
}

// pythonScript starten, keyevent von P
void runPython() {
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

void runOtherGUI() {
  try {
    launch(new File(sketchPath).getParentFile().getAbsolutePath() + "/GUI2.lnk");
    popup.addText("Starting GUI2...");
  } 
  catch(Exception e) {
    println(e);
    popup.addText("Error! GUI2 not started!");
  }
}

boolean elevatorOverlapsOther(Elevator e) {
  for (Elevator i : allElevators) {
    if (e != i && abs(e.pos.x - i.pos.x) <= 40 && abs(e.pos.z - i.pos.z) <= 100) {
      return true;
    }
  }
  return false;
}
boolean cityCenterOverlapsOther(CityCenter c1) {
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
boolean existsTunnel(Elevator e1, Elevator e2) {
  for (Tunnel i : allTunnels) {
    if ((i.elev1 == e1 && i.elev2 == e2)) {
      return true;
    }
  }
  return false;
}

int idOfElevator(Elevator e) {
  for (int i = 0; i < allElevators.size(); i ++) {
    if (allElevators.get(i) == e) {
      return i;
    }
  }
  return 0;
}
