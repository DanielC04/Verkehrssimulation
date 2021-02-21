void loadObjects() { //<>//
  JSONObject data = loadJSONObject(sketchPath + fileName);
  // allgemeine Einstellungen laden
  simDuration = data.getFloat("simDuration");
  simDuration -= simDuration % 25/12.; // simDurationTime leicht runden -> sicherstellen, dass Vor- und Zurückspulen bis zum Ende möglich ist 
  maxAcc = data.getFloat("maxAcc");
  maxDeacc = data.getFloat("maxDeacc");
  elevSpeed = data.getFloat("elevatorSpeed");
  // Fahrstühle laden
  JSONArray elevators = data.getJSONArray("Elevators");
  for (int i = 0; i < elevators.size(); i ++) {
    JSONObject elevator = elevators.getJSONObject(i);
    allElevators.add(new Elevator(new PVector(elevator.getInt("x") * scale, elevator.getInt("y") * scale, elevator.getInt("z") * scale), elevSpeed));
  }
  // Tunnel laden
  JSONArray tunnels = data.getJSONArray("Tunnels");
  for (int i = 0; i < tunnels.size(); i ++) {
    JSONObject tunnel = tunnels.getJSONObject(i);
    PVector pos1 = allElevators.get(tunnel.getInt("elev1")).pos1;
    PVector pos2 = allElevators.get(tunnel.getInt("elev2")).pos1;
    allTunnels.add(new Tunnel(pos1, pos2, tunnel.getFloat("vmax")));
  }
  // spawnTime der Autos laden und in Liste timer.spawnTimes[] speichern
  float[] spawnTimes = new float[data.getJSONArray("Cars").getJSONObject(data.getJSONArray("Cars").size() - 1).getInt("key") + 1];
  for (int i = 0; i < data.getJSONArray("Cars").size(); i ++) {
    JSONObject car =  data.getJSONArray("Cars").getJSONObject(i);
    spawnTimes[car.getInt("key")] = car.getFloat("spawnTime");
  }

  timer.spawnTimes = spawnTimes;

  //console.clear();
  // 
  if (! data.getString("Error").equals("null")) {
    println(data.getString("Error"));
    throw new IllegalArgumentException(data.getString("Error"));
  }
  println("-----------------------------");
  println("---Simulation-started---");
  println("-----------------------------");
  println("Benutzter Path Algorithmus: " + data.getString("pathAlg"));
  println("Benutzter Speed Algorithmus: " + data.getString("speedAlg"));
}

// Auto mit id key spawnen
void spawnCar(int key) {
  try{
  JSONArray cars = loadJSONObject(sketchPath + fileName).getJSONArray("Cars");
  for (int i = 0; i < cars.size(); i ++) {
    if (cars.getJSONObject(i).getInt("key") == key) {
      JSONObject car = cars.getJSONObject(i);
      // die Route (Liste von Fahrstuhl ids) in eine Liste von Edges umwandeln
      int[] indexRoute = car.getJSONArray("route").getIntArray();
      ArrayList<Street> route = new ArrayList<Street>();
      for (int j = 0; j < indexRoute.length - 1; j ++) {
        route.add(getTunnelByPosition(allElevators.get(indexRoute[j]).pos1, allElevators.get(indexRoute[j + 1]).pos1));
      }
      // Fahrstühle zur Route hinzufügen
      route.add(0, getElevatorByPosition(route.get(0).pos1));
      route.add(getElevatorByPosition(route.get(route.size() - 1).pos2));
      // checkpoint liste erstellen
      JSONArray checkpoints = car.getJSONArray("checkpoints");
      float[][] c = new float[checkpoints.size()][4];
      for (int j = 0; j < c.length; j ++){
        c[j] = checkpoints.getJSONArray(j).getFloatArray();
      }
      allCars.add (new Car (route, key, car.getJSONArray("accel").getFloatArray(), c));
    }
  }
  } catch(Exception e){
    println(e);
  }
}
