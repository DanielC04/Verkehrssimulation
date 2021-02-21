public class Car {
  PShape car, backgroundSign;
  PVector pos, dsVector = new PVector();
  Street tunnel;
  int indexRoute = 0, indexA = 0, indexCheckpoints = 0, id, a = -1;
  private float v = 0, deltaPosOnStreet, posOnStreet = 0.;
  float [] acc;
  float [][] checkpoints;
  ArrayList<Street> route;

  public Car(ArrayList<Street> r, int i, float [] a, float[][] c) {
    car = loadShape(sketchPath + "/Car.obj");
    car.scale(18);
    car.translate(0, -12, 0);
    car.rotate(PI, 0, 0, 1);
    acc = a;
    checkpoints = c;

    backgroundSign = createShape(RECT, -100, -36, 180, 100);
    backgroundSign.setFill(color(240, 200));
    route = r;
    id = i;

    reset();

    println("~ ");
    println("~ ---" + timer.getStr() + "---");
    println("~ Car spawned: ");
    println("~    id: " + id);
  }  

  void reset() {
    tunnel = route.get(0);
    indexRoute = 0;
    posOnStreet = 0.;
    pos = tunnel.pos2.copy();
    setVelocity(v);
  }

  void display() {
    pushMatrix();
    if (tunnel.isLowerTunnel) {
      translate(0, 40, 0);
    }
    translate(pos.x, pos.y, pos.z);
    // draw car
    shape(car);
    if (signsVisible) {
      // draw Sign
      pushMatrix();
      rotate(tunnel.angleY, 0, 1, 0);
      translate(0, -100, 0);
      text("id: " + id + "\nspeed: " + (int) v, 0, 0);
      translate(20, 0, -1);
      shape(backgroundSign);
      popMatrix();
    }
    popMatrix();
  }

  void switchRoad() {
    // Rotationen der vorherigen Straße rückgängig machen
    car.rotate(- tunnel.angleX, tunnel.rotationAxis.x, tunnel.rotationAxis.y, tunnel.rotationAxis.z);
    car.rotate(- tunnel.angleY, 0, 1, 0);
    indexRoute ++;
    if (indexRoute == 1 || indexRoute == route.size() - 1) {                       // v auf 0 setzen, falls man Auto Fahrstuhl kommt
      v = 0;
    }
    if (indexRoute < route.size()) {            // sonst nächsten Tunnel der Route auswählen
      tunnel = route.get(indexRoute);
    } else {                                    // Auto ist am Ende der Route
      carsToDestroy.add(this);
    }
    posOnStreet = 0.;
    pos = tunnel.pos1.copy();
    setVelocity(v);
    // Auto genau wie Tunnel drehen
    car.rotate(tunnel.angleY, 0, 1, 0);
    car.rotate(tunnel.angleX, tunnel.rotationAxis.x, tunnel.rotationAxis.y, tunnel.rotationAxis.z);
  }

  public void moveCar() {
    updateAcc(timer.time);
    if (a == 1) {                            // beschleunigen bzw. abbremsen
      if (v != min(tunnel.vmax, v + maxAcc * dt)) {
        setVelocity(min(tunnel.vmax, v + maxAcc * dt));
      }
    } else if (a == -1) {
      if (v != max(0, v - maxDeacc * dt)) {
        setVelocity(max(0, v - maxDeacc * dt));
      }
    }
    if (posOnStreet+deltaPosOnStreet < 1) {                    // wenn Auto auf Straße ist: um dsVector auf Straße weiterbewegen
      pos.add(dsVector);
      posOnStreet += deltaPosOnStreet;
    } else {                                    // Straße wechseln, falss posOnStreet >= 1
      switchRoad();
    }
    checkCheckpoint(timer.time);
  }

  public void setVelocity(float newVel) {
    v = newVel;
    deltaPosOnStreet = (v * dt * scale)/tunnel.len;
    if (indexRoute == 0) {    // keine Unterscheidung von herauffahrenden und runterführenden Elevators
      PVector.mult(tunnel.movementVector, - deltaPosOnStreet, dsVector);     // -> bei einem der beiden (hier runterfahrend) muss der dsVector mit -1 multipliziert werden, damit das Auto sich nach unten bewegt
    } else {
      PVector.mult(tunnel.movementVector, deltaPosOnStreet, dsVector);
    }
  }
  // testet, ob Auto Beschleunigung ändern muss
  void updateAcc(float t) {
    if (acc.length > indexA && t >= acc[indexA]) {
      a *= -1;
      indexA ++;
    }
  }

  void checkCheckpoint(float t) {
    if (checkpoints.length > indexCheckpoints && t >= checkpoints[indexCheckpoints][0]) {
      posOnStreet = checkpoints[indexCheckpoints][2];
      if (a != checkpoints[indexCheckpoints][4]) {
        a*= -1;
        indexA ++;
      }
      if (indexRoute != checkpoints[indexCheckpoints][1]) {
        indexRoute = int(checkpoints[indexCheckpoints][1]) - 1;
        switchRoad();
      }
      if (indexRoute == 0) {
        pos = tunnel.pos2.copy();
        pos.sub(tunnel.movementVector.copy().setMag(posOnStreet * tunnel.len));
      } else {
        pos = tunnel.pos1.copy();
        pos.add(tunnel.movementVector.copy().setMag(posOnStreet * tunnel.len));
      }
      setVelocity(checkpoints[indexCheckpoints][3]);
      indexCheckpoints ++;
    }
  }
  // Auto zerstören
  private void destroyCar() {
    println("~");
    println("~ ---" + timer.getStr() + "---");
    println("~ Car despawned: ");
    println("~    id: " + id);
    allCars.remove(this);
  }
}
