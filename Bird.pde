  private class Bird {
    private Animation bird_gif;
    private PShape bird_shape;
    private PVector[] bird_shape_vertices;

    // cinematic variables
    private PVector position;
    private PVector velocity;
    private PVector acceleration;
    private float direction;
    private float distance_covered;

    // sprite properties:
    private int bird_width;
    private int bird_height;


    public Bird(Color c) {
      // bird GIF wing flap
      String folder = "resources/sprites/";
      String[] bird_color_images = {folder+"bird_color_1.png", folder+"bird_color_2.png", folder+"bird_color_3.png", folder+"bird_color_2.png"};
      String[] bird_body_images = {folder+"bird_body_1.png", folder+"bird_body_2.png", folder+"bird_body_3.png", folder+"bird_body_2.png"};
      PImage[] images = new PImage[4];

      for (int i = 0; i < 4; i++) {
        PImage bird_body = loadImage(bird_body_images[i]);
        PImage bird_color = loadImage(bird_color_images[i]);

        PGraphics graphic = createGraphics(bird_body.width, bird_body.height);
        graphic.beginDraw();
        graphic.image(bird_body, 0, 0);
        graphic.tint(c.getRed(), c.getGreen(), c.getBlue(), 255);  // paint with the requested color
        graphic.image(bird_color, 0, 0);
        graphic.tint(255, 255);  // back to normal
        graphic.endDraw();
        images[i] = (PImage)graphic.get();
      }
      this.bird_gif = new Animation(images, 6);
      bird_width = bird_gif.width;
      bird_height = bird_gif.height;

      //set shape:
      setShapeVertices();
      bird_shape = createShape();
      bird_shape.beginShape();
      for (PVector vec : bird_shape_vertices) {
        bird_shape.vertex(vec.x, vec.y);
      }
      bird_shape.endShape(CLOSE);

      // SET CINEMATIC VARIABLES
      // set position to the center of the bird
      position = new PVector(game_width * (1/3f) + bird_width/2, game_height/2 + bird_height/2);
      velocity = new PVector(0, 0);
      acceleration = new PVector(0, 0.3f);
      direction = 0;
      distance_covered = 0;
    }

    public void update() {
      bird.addToVelocity(bird.getAcceleration());
      bird.addToPosition(bird.getVelocity());
      // update position and velocity
      if (position.y < bird_height/2 ) {
        bird.setYVelocity(0);
        bird.setYPosition(bird_height/2);
      }

      // set enabled images (when bird is going down only one sprite; else do whole animation)
      if (bird.getVelocity().y > 4 ) {
        bird.setImageMode("static");
      } else {
        bird.setImageMode("gif");
      }

      // update distance covered
      bird.distance_covered += abs(game_x_speed);

      // CHANGE BIRD DIRETION ACCORDING TO VERTICAL SPEED
      bird.direction = getBirdDirection();
    }

    public PVector getPosition() {
      return position;
    }

    public PVector getVelocity() {
      return velocity;
    }

    public PVector getAcceleration() {
      return acceleration;
    }

    public void addToPosition(PVector vel) {
      position.add(vel);
    }

    public void setYAcceleration(float y) {
      acceleration = new PVector((float)acceleration.x, y);
    }

    public void setYPosition(float y) {
      position = new PVector((float)position.x, y);
    }

    public void addToVelocity(PVector acel) {
      velocity.add(acel);
    }

    public void setYVelocity(float y) {
      velocity = new PVector((float)velocity.x, y);
    }

    public void setImageMode(String mode) {
      switch (mode) {
      case "static":
        setEnabled(new boolean[]{false, true, false, false});
        break;
      case "gif":
        setEnabled(new boolean[]{true, true, true, true});
        break;
      }
    }

    public void setEnabled(boolean e[]) {
      bird_gif.setEnabled(e);
    }

    public void setShapeVertices() {
      int vertices = 11;
      bird_shape_vertices = new PVector[vertices];

      // around image center
      bird_shape_vertices[0] = new PVector(0, -10);
      bird_shape_vertices[1] = new PVector(7, -10);
      bird_shape_vertices[2] = new PVector(11, -7);
      bird_shape_vertices[3] = new PVector(17, 6);
      bird_shape_vertices[4] = new PVector(13, 12);
      bird_shape_vertices[5] = new PVector(0, 14);
      bird_shape_vertices[6] = new PVector(-8, 14);
      bird_shape_vertices[7] = new PVector(-16, 12);
      bird_shape_vertices[8] = new PVector(-18, 0);
      bird_shape_vertices[9] = new PVector(-12, -7);
      bird_shape_vertices[10] = new PVector(-6, -10);

      // offset (put in top_left corner):
      for (int i = 0; i < vertices; i++) {
        // bird_shape_vertices[i] = bird_shape_vertices[i].addLocal(bird_width/2, bird_height/2);
        bird_shape_vertices[i].add(new PVector(1, -2));
        bird_shape_vertices[i].mult(0.9f);
      }
    }


    public void display() {
      // DRAW BIRD
      pushMatrix();
      translate((int)bird.getPosition().x, (int)bird.getPosition().y);
      rotate(direction);
      // translate((int)-bird_gif.width/2, (int)-bird_gif.height/2);
      bird_gif.display(-bird_gif.width/2, -bird_gif.height/2);
      if (collisionTest) {
        bird_shape.setFill(color(255, 100));
        shape(bird_shape);
        //fill(255,100);
        //rect(-bird_width/2, -bird_height/2,bird_width, bird_height);
      }
      popMatrix();
    }

    public void resize(float scale) {
      for (PImage img : bird_gif.images) {
        resizeImage(img, scale);
      }
    }

    private PVector sumVectors(PVector v1, PVector v2) {
      return new PVector(v1.x + v2.x, v1.y + v2.y);
    }
  }
