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
      .setMultiplier(-0.2);
    setVisible(false);
  }
  void display() {
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
  void refresh() {
    if (selectedTunnel != null) {
      tunnelInputV.setValue(selectedTunnel.vmax);
    }
  }

  boolean isMouseOver() {
    return isVisible && mouseX > drawPosX && mouseX < drawPosX + boxWidth && mouseY > drawPosY && mouseY < drawPosY + boxHeight;
  }
}
// callback function
void tunnelInputV(int value) {
  if (selectedTunnel != null) {
    selectedTunnel.vmax = value;
  }
}
