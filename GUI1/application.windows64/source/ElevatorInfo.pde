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
      .setMultiplier(-0.1)
      .setRange(- border, border);
    inputY = cp5.addNumberbox("inputY")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 170)
      .setSize(80, 40)
      .setMultiplier(-0.1)
      .setRange(0, border);
    inputZ = cp5.addNumberbox("inputZ")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 250)
      .setSize(80, 40)
      .setMultiplier(-0.1)
      .setRange(- border, border);
    setVisible(false);
  }
  void display() {
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
  void refresh() {
    if (selectedElevator != null) {
      inputX.setValue(selectedElevator.pos.x / scale);
      inputY.setValue(selectedElevator.pos.y / scale);
      inputZ.setValue(selectedElevator.pos.z / scale);
    }
  }

  boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight;
  }
}
// callback functions der Numberboxes
void inputX(int value) {
  if (selectedElevator != null) {
    selectedElevator.moveX(value * scale);
  }
}

void inputY(int value) {
  if (selectedElevator != null) {
    selectedElevator.moveY(value * scale);
  }
}

void inputZ(int value) {
  if (selectedElevator != null) {
    selectedElevator.moveZ(value * scale);
  }
}
