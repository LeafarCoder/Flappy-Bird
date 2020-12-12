  private class Pipes {
    private PImage pipe_img;
    private int count;
    private float[] x_pos;
    private int[] y_center_opening;  // coordinate of the center of the opening (counting from the ground)
    private int open_size;
    private int pipe_width;
    private int pipe_height;
    private int x_spaces;
    private int y_spread;

    public Pipes(PImage pipe, int count, int open_size, int spawn_x_start, int x_spacing, int y_spread, int y_ground) {
      this.pipe_img = pipe;
      this.x_pos = new float[count];
      this.count = count;
      this.y_center_opening = new int[count];
      this.open_size = open_size;
      this.pipe_width = pipe.width;
      this.pipe_height = (pipe.height - open_size)/2;
      this.x_spaces = x_spacing;
      this.y_spread = y_spread;

      for (int i = 0; i < count; i++) {
        x_pos[i] = spawn_x_start + i * x_spaces;
        if (gameMode == 0) {
          y_center_opening[i] = getRandomYPos();
          pipes_y_center.add(y_center_opening[i]);
        } else if (gameMode == 1) {
          y_center_opening[i] = pipes_y_center.get(next_pipe_idx++);
        }
      }
    }

    public void display() {
      for (int i = 0; i < count; i++) {
        int rel_y = game_height - game_ground_height - y_center_opening[i];
        image(pipe_img, x_pos[i] - pipe_width/2, rel_y - pipe_img.height/2);

        if (collisionTest) {
          int x = (int) x_pos[i];
          int y = y_center_opening[i];
          fill(255, 100);
          rect(x - pipe_width/2, rel_y + open_size/2, pipe_width, pipe_height);
          rect(x - pipe_width/2, rel_y - open_size/2 - pipe_height, pipe_width, pipe_height);
          fill(255, 255);
        }
      }
    }

    private void positionUpdate() {
      for (int i = 0; i < count; i++) {
        x_pos[i] += game_x_speed;

        // if pipe goes out of sight relocate it
        if (x_pos[i] + pipe_width< 0) {
          x_pos[i] = x_pos[(i + count - 1) % count] + x_spaces;  // put it behind the last one
          if (gameMode == 0) {
            y_center_opening[i] = getRandomYPos();
            pipes_y_center.add(y_center_opening[i]);
          } else if (gameMode == 1) {
            y_center_opening[i] = pipes_y_center.get(next_pipe_idx++);
          }
        }
      }
    }

    private int getRandomYPos() {
      int offset = 50;
      int y = (int)(y_spread/2 + new Random().nextGaussian() * y_spread * 0.1);

      if (y > game_height - game_ground_height - offset - open_size/2)
        y = game_height - game_ground_height - offset - open_size/2;

      if (y <  offset + open_size)
        y = offset + open_size/2;

      return y;
    }

    // input coordinates (x,y) refer to left upper corner of the object
    public boolean isCollision(int x, int y, int w, int h) {

      boolean ans = false;

      for (int i = 0; i < count; i++) {
        // skip pipes that are not in the proper x_range
        if ((x  > x_pos[i] + pipe_width/2) || (x  + w < x_pos[i]- pipe_width/2))continue;

        // other wise the x coordinates cross! now check for y coordinates:
        // if y coordinates also dont cross we are safe (just break):
        int pipe_y_rel = game_height - game_ground_height - y_center_opening[i]; 
        if ((y > pipe_y_rel - open_size/2) && (y + h  < pipe_y_rel + open_size/2))break;
        // otherwise return true;
        ans = true;
      }

      return ans;
    }

    public int getDistToClosestPipe(int bird_x) {
      int ans = 2*game_width; // hypothetical maximum
      for (int i = 0; i < count; i++) {
        if (bird_x < x_pos[i]) {
          ans = (int)min(ans, x_pos[i] - bird_x);
        }
      }
      return ans;
    }

    public int getVertDistOfNextPipe() {
      int bird_x = (int)bird.getPosition().x;
      int x_dist = 2*game_width; // hypothetical maximum
      int vert = 0;
      for (int i = 0; i < count; i++) {
        if (x_dist > Math.abs(x_pos[i] - bird_x)) {
          x_dist = (int)Math.abs(x_pos[i] - bird_x);

          int rel_y = game_height - game_ground_height - y_center_opening[i];
          vert = (int)(rel_y - bird.getPosition().y);
        }
      }
      return vert;
    }
  }
