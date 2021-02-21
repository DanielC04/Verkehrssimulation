class LoadingScreen {
  final int countCars = 10, radius = 300;
  PShape [] cars = new PShape[countCars];
  PVector [] rotationAxis = new PVector[countCars];
  float rotationZ = 0.;

  LoadingScreen() {
    for (int i = 0; i < countCars; i ++) {
      float angle = i * TWO_PI / countCars;
      rotationAxis[i] = new PVector(radius * sin(angle), radius * cos(angle), 0);
      cars[i] = loadShape(sketchPath + "/Car.obj");
      cars[i].scale(25);
      cars[i].translate(0, -16, 0);
      cars[i].rotate(HALF_PI, 1, 0, 0);
      cars[i].rotate(- angle, 0, 0, 1);
      cars[i].translate(rotationAxis[i].x, rotationAxis[i].y, rotationAxis[i].z);
    }
  }

  void display() {
    if (! error.equals("loading")) {    // show Error-message
      hint(DISABLE_DEPTH_TEST);
      cam.beginHUD();
      text(error, width/2, 100);
      cam.endHUD();
      hint(ENABLE_DEPTH_TEST);
    } else {
      hint(DISABLE_DEPTH_TEST);
      cam.beginHUD();
      text("Python Script is running...", width/2, 50);
      cam.endHUD();
      hint(ENABLE_DEPTH_TEST);
      rotate(rotationZ, 0, 0, 1);
      rotationZ += 0.05;
      for (int i = 0; i < countCars; i ++) {
        pushMatrix();
        translate(0, 0, 100 * noise(rotationZ + i/5.));
        cars[i].rotate(0.05, rotationAxis[i].x, rotationAxis[i].y, rotationAxis[i].z);
        shape(cars[i]);
        popMatrix();
      }
    }
  }
}
