// Edge enthält alle Informationen, die ein Auto braucht, um auf ihr zu fahren
class Street {
  boolean isLowerTunnel = false;
  PVector pos1, pos2, movementVector, rotationAxis;
  float len, angleX, angleY, vmax;

  public Street(PVector p1, PVector p2, float v) {
    pos1 = p1;
    pos2 = p2;
    vmax = v;
    movementVector = PVector.sub(pos2, pos1);
    len = movementVector.mag();
    // calculate rotationAxis and -angle
    angleY = new PVector(movementVector.z, movementVector.x).heading();
    angleX = asin(movementVector.y/movementVector.mag());
    rotationAxis = movementVector.cross(new PVector(0, 1, 0));
  }
}

class Tunnel extends Street {
  // car always drives from node1 to node2
  Path path;
  Oval base;
  Tube tunnel;
  int diameter = 20;

  public Tunnel(PVector p1, PVector p2, float v) {
    super(p1, p2, v);
    path = new Linear(pos1, pos2, 1);
    base = new Oval(diameter, 20);
    while (tunnel == null) {
      try {
        tunnel = new Tube(path, base);
        tunnel
          .use(S3D.BODY)
          .texture(tunnelTexture, S3D.BODY)
          .uv(0, this.len/40, 0, 6, S3D.BODY)
          .drawMode(S3D.TEXTURE)
          .use(S3D.END0 | S3D.END1)
          .visible(false);
      }
      catch (Exception i) {
        tunnel = null;
        pos1.x ++;
        path = new Linear(pos1, pos2, 1);
      }
    }    
    if (existsTunnel(pos2, pos1)) {
      isLowerTunnel = true;
    }
  }
  public void display() {
    if (isLowerTunnel) {
      pushMatrix();
      translate(0, 40, 0);
      tunnel.draw(getGraphics());
      popMatrix();
    } else {
      tunnel.draw(getGraphics());
    }
  }
}

public class Elevator extends Street {
  PShape elev;

  public Elevator(PVector p, float vmax) {
    super(p, new PVector(p.x, 0, p.z), vmax);
    angleX = 0.;
    angleY = 0.;
    elev = createShape(BOX, 40, len, 100);
    elev.setFill(false);
    elev.setStroke(color(0));
    elev.setStrokeWeight(4);
    elev.translate(pos1.x, len/2, pos1.z);
  }
  public void display() {
    shape (elev);
  }
}
