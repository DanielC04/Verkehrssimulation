class Terrain {
  final int dim = border / 10, scl = 20, heightOfHills = 50;
  final float offset = 0.05, drawOffset = - dim * scl / 2;
  ArrayList<PShape> terrainSlices = new ArrayList<PShape>();

  public Terrain() {
    float zoff = 0;
    for (int z = 0; z < dim - 1; z ++) {
      float xoff = 0;
      PShape terrainSlice = createShape();
      terrainSlice.beginShape(TRIANGLE_STRIP);
      terrainSlice.noStroke();
      for (int x = 0; x < dim; x ++) {
        terrainSlice.fill(random(25), map(noise(xoff, zoff), 0, 1, 255, 0), random(25), 200);
        float y = map(noise(xoff, zoff), 0, 1, -heightOfHills, heightOfHills);
        terrainSlice.vertex(x * scl + drawOffset, y, z * scl + drawOffset);
        y = map(noise(xoff, zoff + offset), 0, 1, -heightOfHills, heightOfHills);
        terrainSlice.vertex(x * scl + drawOffset, y, (z + 1) * scl + drawOffset);
        xoff += offset;
      }
      zoff += offset;
      terrainSlice.endShape();
      terrainSlices.add(terrainSlice);
    }
  }

  public void display() {
    for (PShape s : terrainSlices) {
      shape(s);
    }
  }
}
