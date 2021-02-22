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
      + "- ESC: Programm schließen \n"
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

  void setVisible(boolean b) {
    isVisible = b;
    shortcuts.setVisible(b);
    pythonHelp.setVisible(b);
    cam.setActive(!b);
    defaultInfo.setVisible(!b);
  }

  boolean isMouseOver() {
    return isVisible && (shortcuts.isMouseOver() || pythonHelp.isMouseOver());
  }
}
void help() {
  infoArea.setVisible(! infoArea.isVisible);
}
