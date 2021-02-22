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
      scaleGraphics.stroke(lerpColor(color2, color1, i / float(height - 100)));
      scaleGraphics.line(0, i, 50, i);
    }
    scaleGraphics.endDraw();
    
    // Numberboxes einrichten
    cityCenterInputX = cp5.addNumberbox("cityCenterInputX")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 90)
      .setSize(80, 40)
      .setMultiplier(-0.1)
      .setRange(- border, border);
    cityCenterInputZ = cp5.addNumberbox("cityCenterInputZ")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 180)
      .setSize(80, 40)
      .setMultiplier(-0.1)
      .setRange(- border, border);
    cityCenterWeight = cp5.addNumberbox("cityCenterWeight")
      .setLabel("")
      .setPosition(drawPosX + 190, drawPosY + 270)
      .setSize(80, 40)
      .setRange(0, 2000)
      .setValue(150)
      .setMultiplier(-0.5);
    inputUpperBorder = cp5.addNumberbox("upperBorder")
      .setLabel("")
      .setPosition(width - 100, 150)
      .setSize(50, 30)
      .setRange(0, 200)
      .setMultiplier(-0.1)
      .setValue(upperBorder);

    setVisible(false);
  }
  
  void display() {
    if (isVisible) {
      image(graphics, drawPosX, drawPosY);
    }
    image(scaleGraphics, graphicsPosX, graphicsPosY);    // Farbverteilungsskala immer anzeigen
  }
  
  void setVisible(boolean b) {
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

  boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight || inputUpperBorder.isMouseOver() ;
  }
}
// callback functions der Numberboxes
void cityCenterInputX(int value) {
  if (selectedCityCenter != null) {
    selectedCityCenter.moveX(value * scale);
  }
  appointP();
}

void cityCenterInputZ(int value) {
  if (selectedCityCenter != null) {
    selectedCityCenter.moveZ(value * scale);
  }
  appointP();
}

void cityCenterWeight(int value) {
  if (selectedCityCenter != null){
    selectedCityCenter.weight = value;
    appointP();
  }
}

void upperBorder(int value) {
  upperBorder = value;
  appointP();
}
