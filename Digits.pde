  private class Digits {
    PImage[] images;
    int digit_width;

    // give digits file Strings in order: 0, 1, 2, ..., 8, 9
    public Digits(String[] files, float size_factor) {
      images = new PImage[files.length];

      for (int i = 0; i < files.length; i++) {
        images[i] = loadImage(files[i]);
        resizeImage(images[i], size_factor);
      }

      digit_width = images[0].width;
    }

    public void displayNumber(int num, int x_pos, int y_pos) {
      int numberOfDigits;
      if (num == 0) {
        numberOfDigits = 1;
      } else {
        numberOfDigits = (int)Math.floor(Math.log10(num) + 1);
      }
      int num_width = numberOfDigits * digit_width;
      int counter = 1;
      int temp = num;
      int digit;
      while (temp > - 1) {
        digit = temp % 10;
        temp /= 10;
        int x = x_pos + num_width/2 - counter * digit_width;
        image(images[digit], x, y_pos);
        counter++;
        if (temp == 0)temp = -1;
      }
    }
  }
