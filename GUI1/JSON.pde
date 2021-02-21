void loadData() {
  try {
    JSONObject data = loadJSONObject(sketchPath + fileName);
    // input general settings
    defaultInfo.inputA.setValue(data.getFloat("maxAcc"));
    defaultInfo.inputDeA.setValue(data.getFloat("maxDeacc"));
    defaultInfo.inputSafetyDist.setValue(data.getFloat("safetyDist"));
    defaultInfo.inputSimDur.setValue(data.getFloat("simDuration"));
    defaultInfo.inputElevatorV.setValue(data.getFloat("elevatorSpeed"));
    defaultInfo.pathAlg.setText(data.getString("pathAlg"));
    defaultInfo.speedAlg.setText(data.getString("speedAlg"));

    // input CityCenter
    JSONArray cityCenterIn = data.getJSONObject("CityCenter").getJSONArray("In");
    for (int i = 0; i < cityCenterIn.size(); i ++) {
      JSONObject cc = cityCenterIn.getJSONObject(i);
      PVector pos = new PVector(cc.getFloat("x") * scale, 0, cc.getFloat("z") * scale);
      allCityCentersIn.add(new CityCenter(pos, cc.getFloat("weight")));
    }
    JSONArray cityCenterOut = data.getJSONObject("CityCenter").getJSONArray("Out");
    for (int i = 0; i < cityCenterOut.size(); i ++) {
      JSONObject cc = cityCenterOut.getJSONObject(i);
      PVector pos = new PVector(cc.getFloat("x") * scale, 0, cc.getFloat("z") * scale);
      allCityCentersOut.add(new CityCenter(pos, cc.getFloat("weight")));
    }
    cityCenterInfo.inputUpperBorder.setValue(data.getJSONObject("CityCenter").getFloat("upperBorder"));

    // load Nodes
    JSONArray nodes = data.getJSONArray("Elevators");
    for (int i = 0; i < nodes.size(); i ++) {
      JSONObject node = nodes.getJSONObject(i);
      allElevators.add(new Elevator(new PVector(node.getFloat("x") * scale, node.getFloat("y") * scale, node.getFloat("z") * scale), node.getFloat("vmax")));
    }

    // load tunnels
    JSONArray tunnels = data.getJSONArray("Tunnels");
    for (int i = 0; i < tunnels.size(); i ++) {
      JSONObject tunnel = tunnels.getJSONObject(i);
      Elevator e1 = allElevators.get(tunnel.getInt("elev1"));
      Elevator e2 = allElevators.get(tunnel.getInt("elev2"));
      allTunnels.add(new Tunnel(e1, e2, tunnel.getFloat("vmax")));
    }
    popup.addText("Loaded Objects successfully");
  } 
  catch(Exception e) {
    popup.addText("Error while loading Objects!");
    println(e);
  }
}

void saveData() {
  try {
    JSONObject data = loadJSONObject(sketchPath + fileName);
    // save general Settings
    data.setFloat("maxAcc", defaultInfo.inputA.getValue());
    data.setFloat("maxDeacc", defaultInfo.inputDeA.getValue());
    data.setFloat("safetyDist", defaultInfo.inputSafetyDist.getValue());
    data.setFloat("simDuration", defaultInfo.inputSimDur.getValue());
    data.setFloat("elevatorSpeed", defaultInfo.inputElevatorV.getValue());
    data.setString("pathAlg", defaultInfo.pathAlg.getText());
    data.setString("speedAlg", defaultInfo.speedAlg.getText());
    // save CityCenter
    JSONObject CityCenters = new JSONObject();
    // stuff for tab 1 -> incoming traffic
    JSONArray in = new JSONArray();
    for (int j = 0; j < allCityCentersIn.size(); j ++) {
      CityCenter i = allCityCentersIn.get(j);
      JSONObject cc = new JSONObject();
      cc.setFloat("x", i.pos.x / scale);
      cc.setFloat("z", i.pos.z / scale);
      cc.setFloat("weight", i.weight);
      in.setJSONObject(j, cc);
    }
    CityCenters.setJSONArray("In", in);
    // stuff for tab 2 -> outgoing traffic
    JSONArray out = new JSONArray();
    for (int j = 0; j < allCityCentersOut.size(); j ++) {
      CityCenter i = allCityCentersOut.get(j);
      JSONObject cc = new JSONObject();
      cc.setFloat("x", i.pos.x / scale);
      cc.setFloat("z", i.pos.z / scale);
      cc.setFloat("weight", i.weight);
      out.setJSONObject(j, cc);
    }
    CityCenters.setFloat("upperBorder", upperBorder);
    CityCenters.setJSONArray("Out", out);  

    // save Elevators
    JSONArray elevators = new JSONArray();
    for (Elevator e : allElevators) {
      if (elevatorOverlapsOther(e)){
        popup.addText("An elevator overlaps another!");
        throw new IllegalArgumentException("Elevator overlap");
      }
      JSONObject elevator = new JSONObject();
      elevator.setFloat("x", e.pos.x / scale);
      elevator.setFloat("y", e.pos.y / scale);
      elevator.setFloat("z", e.pos.z / scale);
      elevator.setFloat("spawnRateIn", e.spawnRateIn);
      elevator.setFloat("spawnRateOut", e.spawnRateOut);
      elevator.setFloat("vmax", e.vmax);
      elevators.setJSONObject(elevators.size(), elevator);
    }

    // save Tunnels
    JSONArray tunnels = new JSONArray();
    for (Tunnel t : allTunnels) {
      JSONObject tunnel = new JSONObject();
      tunnel.setInt("elev1", idOfElevator(t.elev1));
      tunnel.setInt("elev2", idOfElevator(t.elev2));
      tunnel.setFloat("vmax", t.vmax);

      tunnels.setJSONObject(tunnels.size(), tunnel);
    }

    // set jsonobjects and write them into file 
    data.setJSONObject("CityCenter", CityCenters);
    data.setJSONArray("Elevators", elevators);
    data.setJSONArray("Tunnels", tunnels);

    saveJSONObject(data, sketchPath + fileName);

    popup.addText("Saved Data");
  } 
  catch (Exception e) {
    popup.addText("Problem while saving data");
    println(e);
  }
}
