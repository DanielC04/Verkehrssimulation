void setupControlElements() { //<>// //<>// //<>//
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
void drawControlls() {
  hint(DISABLE_DEPTH_TEST);
  cam.beginHUD();
  cp5.draw();
  text(timer.getStr(), width - 150, 50);
  cam.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

void pause() {
  pause = !pause;
  if (pause) {
    println("Pause");
  } else {
    println("Resume");
  }
}

// keyboard shortcuts
void keyPressed() {
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

void mousePressed() {
  // disable cameras movement, if mouse is over control element
  if (consoleArea.isMouseOver()) {
    cam.setActive(false);
  }
}

void mouseReleased() {
  // enable camera movement again
  if (! cam.isActive()) {
    cam.setActive(true);
  }
}

void reset() {
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

void stopSimulation() {
  timer.time = simDuration + .1;
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
Tunnel getTunnelByPosition(PVector p1, PVector p2) {
  for (Tunnel i : allTunnels) {
    if (i.pos1 == p1 && i.pos2 == p2) {
      return i;
    }
  }
  return null;
}

// gibt Fahrstuhl an Punkt p zurück
Elevator getElevatorByPosition(PVector p) {
  for (Elevator i : allElevators) {
    if (i.pos1 == p) {
      return i;
    }
  }
  return null;
}

boolean existsTunnel(PVector p1, PVector p2) {
  for (Tunnel i : allTunnels) {
    if (i.pos1 == p1 && i.pos2 == p2) { 
      return true;
    }
  } 
  return false;
}
