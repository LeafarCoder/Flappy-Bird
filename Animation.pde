  private class Animation {
    private PImage[] images;
    private boolean[] enabledImages;
    private int width;
    private int height;
    private int changePerFrames = 1;  // wait this number of frames before changing frame (works as a rate)
    private int currentWait = 1;
    private int frame;

    private Animation(PImage[] images, int changePerFrames) {
      this.frame = 0;
      this.images = images;
      this.changePerFrames = changePerFrames;
      enabledImages = new boolean[images.length];

      for (int i = 0; i < images.length; i++) {
        enabledImages[i] = true;
      }

      this.width = images[0].width;
      this.height = images[0].height;
    }

    public void display(int x_offset, int y_offset) {
      image(images[frame], x_offset, y_offset);
      if ((currentWait++ % changePerFrames) == 0) {
        // go to next enabled image:
        for (int i = 1; i <= images.length; i++) {
          if (enabledImages[(frame + i)% images.length]) {
            frame = (frame+i) % images.length;
            break;
          }
        }
      }
    }

    public void setEnabled(boolean e[]) {
      this.enabledImages = e;
    }

    public PImage[] getFrames() {
      return images;
    }
  }
