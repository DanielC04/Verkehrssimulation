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
      .setMultiplier(-0.01)
      .setRange(0, 8);
    inputDeA = cp5.addNumberbox("inputDeA")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 130)
      .setSize(80, 40)
      .setMultiplier(-0.01)
      .setRange(0, 8);
    inputSafetyDist = cp5.addNumberbox("inputSafetyDist")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 210)
      .setSize(80, 40)
      .setMultiplier(-0.01)
      .setRange(0, 8);
    inputSimDur = cp5.addNumberbox("inputSimDur")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 290)
      .setSize(80, 40)
      .setMultiplier(-0.3)
      .setRange(0, 1000);
    inputElevatorV = cp5.addNumberbox("elevatorInputV")
      .setLabel("")
      .setPosition(drawPosX + boxWidth - 120, drawPosY + 370)
      .setSize(80, 40)
      .setRange(0, 25)
      .setMultiplier(-0.05);
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
  void display() {
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

  boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight;
  }
}
