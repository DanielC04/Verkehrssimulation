public class Tunnel {
  final int diameter = 20;
  Elevator elev1, elev2;
  Path path;
  Oval base;
  Tube tunnel;
  boolean isLowerTunnel = false;
  float len, vmax;

  public Tunnel(Elevator e1, Elevator e2, float v) {
    elev1 = e1;
    e1.tunnels.add(this);
    elev2 = e2;
    e2.tunnels.add(this);
    vmax = v;
    if (existsTunnel(elev2, elev1)){
      isLowerTunnel = true;
    }
    base = new Oval(diameter, 20);
    setupGraphics();
  }

  void setupGraphics() {
    len = elev1.pos.dist(elev2.pos) / scale;
    PVector pos1 = elev1.pos.copy(), pos2 = elev2.pos.copy();
    if (isLowerTunnel){
      pos1.add(0, 40, 0);
      pos2.add(0, 40, 0);
    }
    path = new Linear(pos1, pos2, 1);
    tunnel = new Tube(path, base);
    tunnel.drawMode(S3D.TEXTURE);
    tunnel.texture(tunnelTexture, S3D.BODY).uv(0, this.len * scale/40, 0, 6, S3D.BODY);
    tunnel.visible(false, S3D.END0 | S3D.END1);
    tunnel.stroke(color(255, 0, 0));
    tunnel.addPickHandler(this, "tunnelPicked");
  }

  public void display() {
    tunnel.draw(getGraphics());
  }

  void select() {
    tunnel.drawMode(S3D.TEXTURE | S3D.WIRE);
    selectedTunnel = this;
    tunnelInfo.setVisible(true);
  }

  void deselect() {
    tunnel.drawMode(S3D.TEXTURE);
    selectedTunnel = null;
  }

  public void tunnelPicked(Shape3D shape, int partNo, int partFlag) {
    deselectAll();
    select();
  }

  void delete() {
    allTunnels.remove(this);
    tunnelInfo.setVisible(false);
  }
}
