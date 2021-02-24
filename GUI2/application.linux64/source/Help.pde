public class InfoArea {
  boolean isVisible = false;
  Textarea shortcuts;
  InfoArea() {
    shortcuts = cp5.addTextarea("shortcuts")
      .setSize(width - 600, height - 200)
      .setPosition(400, 100)
      .setFont(font)
      .setColor(0)
      .setLineHeight(28)
      .setColorBackground(color(220, 225))
      .setColorForeground(color(230, 225))
      .setText("Shortcuts:\n"
      + "- ESC: Programm schließen \n"
      + "- Space: Simulation pausieren bzw. fortsetzen \n"
      + "- R: Simulation zurücksetzen \n"
      + "- D: Details (Seitenpanel und Beschriftung der Autos) ein-/ausblenden \n"
      + "- S: Simulation stoppen und Auswertung anzeigen \n"
      + "- Doppelklick mit Maus: Kameraposition zurück setzen");

    PImage [] imgs = {loadImage(sketchPath + "/helpButton.png"), loadImage(sketchPath + "/helpButton.png"), loadImage(sketchPath + "/helpButton.png")};
    cp5.addButton("help")
      .setPosition(width - 75, 25)
      .setImages(imgs)
      .updateSize();

    setVisible(false);
  }

  void setVisible(boolean b) {
    isVisible = b;
    shortcuts.setVisible(b);
    cam.setActive(!b);
  }

  boolean isMouseOver() {
    return isVisible && shortcuts.isMouseOver();
  }
}
void help() {
  println("triggering Help");
  infoArea.setVisible(! infoArea.isVisible);
}
