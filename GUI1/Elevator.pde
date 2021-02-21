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
  void display() { 
    elev.draw(getGraphics());
  }

  void setupBox() {
    elev = new Box(40, pos.y, 100);
    elev.moveTo(pos.x, pos.y/2, pos.z);
    elev.drawMode(S3D.SOLID | S3D.WIRE);
    elev.addPickHandler(this, "elevatorPicked");
    elev.strokeWeight(4);
    elev.stroke(0);
    setColors();
  }

  public void deselect() {
    elev.stroke(#000000);
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
  
  void moveX(int newX) {
    pos.x = newX;
    elev.moveTo(pos.x, pos.y/2, pos.z);
    refreshPositionTunnels();
    appointP();
  }
  void moveY(int newY) {
    pos.y = newY;
    elev.pickable(false);
    setupBox();                                // Es gibt kein Funktion, um die Maße einer Box zu ändern -> wird die Tiefe eines Elevators geändert, muss eine neue Box erstellt werden
    elev.stroke(color(255, 0, 0));
    refreshPositionTunnels();
  }
  void moveZ(int newZ) {
    pos.z = newZ;
    elev.moveTo(pos.x, pos.y/2, pos.z);
    refreshPositionTunnels();
    appointP();
  }
  // Position aller mit diesem Fahrstuhl verbunden Tunnel anpassen
  void refreshPositionTunnels() {
    for (Tunnel i : tunnels) {
      i.tunnel.pickable(false);
      i.setupGraphics();
    }
  }
  // Farben des Fahrstuhls anhand der SpawnRate anpassen
  void setColors() {
    if (tab == 1) {
      elev.fill(lerpColor(color1, color2, spawnRateIn / cityCenterInfo.inputUpperBorder.getValue()));
    } else {
      elev.fill(lerpColor(color1, color2, spawnRateOut / cityCenterInfo.inputUpperBorder.getValue()));
    }
  }
  // Fahrstuhl und alle verbundenen Tunnel löschen
  void delete() {
    allElevators.remove(this);
    for (Tunnel i : tunnels) {
      i.delete();
    }
    elevInfo.setVisible(false);
  }
}
