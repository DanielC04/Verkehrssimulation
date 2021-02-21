public class CityCenter { //<>//
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

  void display() {
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

  void deselect() {
    shape.drawMode(S3D.SOLID);
    cityCenterInfo.setVisible(false);
  }

  void moveX(float value) {
    pos.x = value;
    shape.moveTo(pos.x, 20, pos.z);
    ball.moveTo(pos.x, -100, pos.z);
  }
  void moveZ(float value) {
    pos.z = value;
    shape.moveTo(pos.x, 20, pos.z);
    ball.moveTo(pos.x, -100, pos.z);
  }

  void calculateP() {
    for (Elevator e : allElevators) {
      float d = dist(pos.x, pos.z, e.pos.x, e.pos.z);
      float newP = upperBorder * pow(2.71828, -0.5 * d * d / weight / weight);   // Normalverteilung mit Erwartungswert 0; Vertikal so skaliert, dass maximaler Wert upperBorder ist
      if (tab == 1) {
        e.spawnRateIn += newP;
      } else {
        e.spawnRateOut += newP;
      }
    }
  }
  void delete() {
    if (tab == 1) {
      allCityCentersIn.remove(this);
    } else {
      allCityCentersOut.remove(this);
    }
    cityCenterInfo.setVisible(false);
    appointP();
  }
}

void appointP() {
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
