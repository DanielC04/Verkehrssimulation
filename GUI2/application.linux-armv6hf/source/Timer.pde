class Timer { //<>//
  float time  ;
  float[] spawnTimes = new float[0];
  int spawnTimeIndex = 0;

  Timer() {
    reset();
  }
  void increment() {
    time += dt;
    while (spawnTimes.length > spawnTimeIndex && time >= spawnTimes[spawnTimeIndex]) {
      spawnCar(spawnTimeIndex);
      spawnTimeIndex ++;
    }
    if (time >= simDuration && dt != 0) {
      stopSimulation();
    }
  }
  void reset() {
    dt = 0.04;
    time = -dt + 0.001;
    spawnTimeIndex = 0;
  }
  void stop() {
    dt = 0.;
  }
  String getStr() {
    int h = int(time / 3600.);
    int min = int(time / 60.);
    int sec = int(time % 60);
    String result = "";
    if (h > 0) {
      result += h + ':';
    }
    if (sec < 10) {
      result += min + ":0" + sec;
    } else {
      result += min + ":" + sec;
    }
    return result;
  }
}
