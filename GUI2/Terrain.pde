class Terrain {
  ArrayList<PShape> terrainSlices = new ArrayList<PShape>();
  PShape terrainShape;
  int dim = terrainBorder / 10, scl = 20, heightOfHills = 50;
  float offset = 0.05, drawOffset = - dim * scl / 2;

  public Terrain() {
    float zoff = 0;
    for (int z = 0; z < dim - 1; z ++) {
      float xoff = 0;
      terrainShape = createShape();
      terrainShape.beginShape(TRIANGLE_STRIP);
      terrainShape.noStroke();
      for (int x = 0; x < dim; x ++) {
        terrainShape.fill(random(25), map(noise(xoff, zoff), 0, 1, 255, 0), random(25), 100);
        float y = map(noise(xoff, zoff), 0, 1, -heightOfHills, heightOfHills);
        terrainShape.vertex(x * scl + drawOffset, y, z * scl + drawOffset);
        y = map(noise(xoff, zoff + offset), 0, 1, -heightOfHills, heightOfHills);
        terrainShape.vertex(x * scl + drawOffset, y, (z + 1) * scl + drawOffset);
        xoff += offset;
      }
      zoff += offset;
      terrainShape.endShape();
      terrainSlices.add(terrainShape);
    }
  }

  public void display() {
    for (PShape s : terrainSlices) {
      shape(s);
    }
  }
}
