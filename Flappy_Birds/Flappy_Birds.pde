
import java.awt.Color;
import java.awt.Point;
import java.awt.geom.Point2D;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Random;

import ddf.minim.*;
import processing.core.PApplet;
import processing.core.PGraphics;
import processing.core.PImage;
import processing.core.PShape;
import processing.core.PVector;

  // BIRD
  Bird bird;
  ArrayList<Color> bird_colors;

  // SPRITE IMAGES:
  private PImage ground_img;
  private PImage[] background_img = new PImage[2];
  private PImage down_pipe_img;
  private PImage up_pipe_img;
  private Digits digits;
  private PImage tapToStart_img;
  private PImage gameOver_img;
  private PImage getReady_img;

  // SOUNDS
  private Minim minim;
  private AudioPlayer wing_flap_sound;
  private AudioPlayer hit_sound;
  private AudioPlayer point_sound;

  // *************************************************** GAME VARIABLES ***************************************************

  private int gameMode = 0;  // 0: normal play; 1: replay
  private ArrayList<Integer> action_times = new ArrayList<Integer>();  // times when the player hit a button
  private ArrayList<String> action_type = new ArrayList<String>();  // keys the player stroke (' ' to fly)
  private ArrayList<Integer> pipes_y_center = new ArrayList<Integer>();   // positions of the y coordinate of the center of the pipes
  private int next_pipe_idx;
  private int next_action_idx;
  private int single_game_time_start;
  private int single_game_time_duration;
  private int preview_time_start;

  private Pipes pipes;
  private int pipeOpenSize = 100;
  private int distToNextPipe;
  private int distToNextPipe2;

  private int background_index;
  private int points;  // pipes crossed

  private int gameFrameRate = 60;
  private float boost_vel = -5;

  private int game_width;
  private int game_height;
  private int game_ground_height;
  private float game_x_speed;
  private float game_ground_x_pos;
  private float scale_factor = 0.6f;

  private char lastKey;  // keeps the last key character pressed
  private int gameState; // 0: game didnt start yet; 1: game in process; 2: game finished
  private boolean muteSound = false;  // controls the sound effects (mute/unmuted)

  // *************************************************** GAME VARIABLES (end) ***********************************************

  // OTHER VARIABLES
  private boolean collisionTest = false;  // used to display boxes for collision detection for programming purposes

// ***************************************** SETTINGS *******************************************

  void settings(){
  
    // SET WINDOW SIZE
    //size((int)game_width, (int)game_height);
    size(428, 587);
  }

    // ***************************************** SETUP *******************************************
  
  public void setup() {
    // GET SOUNDS
    String snd_folder = "resources/sounds/";
    minim = new Minim(this);
    wing_flap_sound = minim.loadFile(snd_folder+"sfx_wing.wav");
    hit_sound = minim.loadFile(snd_folder+"sfx_hit.wav");
    point_sound = minim.loadFile(snd_folder+"sfx_point.wav");
  
    // GET SPRITES (IMAGES)
    String img_folder = "resources/sprites/";
    background_img[0] = loadImage(img_folder+"skyline_1.png");
    background_img[1] = loadImage(img_folder+"skyline_2.png");

    ground_img = loadImage(img_folder+"ground.png");
    down_pipe_img = loadImage(img_folder+"pipe_down.png");
    up_pipe_img = loadImage(img_folder+"pipe_up.png");
    tapToStart_img = loadImage(img_folder+"tap_to_start.png");
    gameOver_img = loadImage(img_folder+"game_over.png");
    getReady_img = loadImage(img_folder+"get_ready.png");

    //get digits sprites:
    String[] files = new String[10];
    for (int i = 0; i <= 9; i++)files[i] = img_folder+"digit_" + i + ".png";
    digits = new Digits(files, 0.5f);
    
    // use landscape after resize to set the game width and height:
    resizeImage(background_img[0], scale_factor);
    resizeImage(background_img[1], scale_factor);
    game_width = background_img[0].width;
    game_height = background_img[0].height;
    
    // MAKE BIRD
    defineColors();
    if(gameMode == 0){
      bird = new Bird(bird_colors.get(new Random().nextInt(bird_colors.size())));
    }

    resizeSpritesSetup();

    // GAME PROPERTIES
    gameState = 0;
    game_ground_height = ground_img.height;
    distToNextPipe = game_width * 10;
    game_x_speed = -2f;
    game_ground_x_pos = 0;
    points = 0;
    if(gameMode == 0){
      background_index = new Random().nextInt(2);
    }

    // define pipes
    PGraphics pipe = createGraphics(down_pipe_img.width, down_pipe_img.height + up_pipe_img.height + pipeOpenSize, JAVA2D);
    pipe.beginDraw();
    pipe.image(down_pipe_img, 0, 0);
    pipe.image(up_pipe_img, 0, up_pipe_img.height + pipeOpenSize);
    pipe.endDraw();
    PImage pipe_img = pipe.get();
    pipes = new Pipes(pipe_img, 4, pipeOpenSize, game_width + 50, 150, game_height - game_ground_height, game_ground_height);
    //pipes = new Pipes(pipe_img, 4, pipeOpenSize, game_width - 100, 150, game_height - game_ground_height, game_ground_height);
    distToNextPipe = pipes.getDistToClosestPipe((int)bird.getPosition().x);
    distToNextPipe2 = distToNextPipe;

    frameRate(gameFrameRate);
  }

  public void draw() {
    // if in Preview mode (review game after game over)
    if (gameMode == 1) {
      int timeToEnd = preview_time_start + single_game_time_duration - frameCount;
      if(timeToEnd < 1)timeToEnd = 1;

      // adjust Framerate (faster in the start, slower at end, when about to collide)
      int fr = (int)map(log(timeToEnd), log(single_game_time_duration), 0, 100, 10);
      println(fr + " : " + frameRate);

      // adjust zoom (get closer)
      float scale_f = map(log(timeToEnd), log(single_game_time_duration), 0, 1.0f, 4f);
      scale(scale_f);
      
      // adjust offset percentage
      float offset_time_start_perc = 0.5;
      float offset_f = map(timeToEnd, offset_time_start_perc*single_game_time_duration, 0, 0f, 1f);
      if(timeToEnd > offset_time_start_perc*single_game_time_duration){offset_f = 0f;}
      
      PVector transl = new PVector(offset_f*(-bird.getPosition().x + width/(2*scale_f)), offset_f*(-bird.getPosition().y + height/(2*scale_f)));
      translate(transl.x, transl.y);
      
      frameRate(fr);
    }

    background(255);
    checkKeyPress();

    // ********************************* DRAW SPRITES **************************************
    drawSprites();  // do not draw anything BEFORE this! skyline will be put in front!
    
    if (gameState == 0) {    // if game has not started (waiting for the first flap)
      gameState0();
    } else if (gameState == 1) {  // if game has started:
      gameState1();
    } else if (gameState == 2) {  // game has finished (bird has crashed into the ground or into pipes)
      gameState2();
    }
    
    // Display white big numbers (score)
    digits.displayNumber(points, game_width/2, game_height/10);

  }

  // ******************************************* DRAW (end) *************************************************


  private void resizeSpritesSetup() {
    resizeImage(ground_img, scale_factor);
    resizeImage(up_pipe_img, scale_factor);
    resizeImage(down_pipe_img, scale_factor);
    resizeImage(gameOver_img, 1.5f);
    resizeImage(getReady_img, 1.3f);
    resizeImage(tapToStart_img, 1f);
    bird.resize(1f);
  }



  private void drawSprites() {
    image(background_img[background_index], 0, 0);

    pipes.display();

    game_ground_x_pos = (game_ground_x_pos + game_x_speed) % (ground_img.width - game_width - 10);
    image(ground_img, game_ground_x_pos, game_height - game_ground_height);

    // draw bird:
    bird.display();
  }

  private void checkKeyPress() {
    if (gameMode == 1) {  // replay mode
      if(action_times.size() > next_action_idx){
        if (action_times.get(next_action_idx) == frameCount - preview_time_start) {  // if action was performed now
          key = action_type.get(next_action_idx).charAt(0);  // parse String to chat
          keyPressed = true;
          next_action_idx++;
        } else {
          keyPressed = false;
        }
      }
    }

    if (keyPressed) {

      if (gameMode == 0) {
        if(gameState == 1){
          action_times.add(frameCount - single_game_time_start);
          action_type.add(""+key);  // parse char to String
        }
      }

      if (gameState == 2 && key == ENTER) {
        gameMode = 0;
        action_times = new ArrayList<Integer>();
        action_type = new ArrayList<String>();
        pipes_y_center = new ArrayList<Integer>();
        next_action_idx = 0;
        next_pipe_idx = 0;

        gameState = 0;
        setup();
      }

      if (lastKey != key) {  // use this block for PRESSED keys (not continuous)
        switch (key) {
          // TAP CONTROL (SPACE BAR)
        case ' ':
          if (gameState == 0) {
            gameState = 1;
            single_game_time_start = frameCount;
            bird.setYPosition(game_height/2 + bird.bird_height/2);
            bird.setYVelocity(boost_vel);
            play_sound(wing_flap_sound);
          }else if (gameState == 1) {
            bird.setYVelocity(boost_vel);
            play_sound(wing_flap_sound);
          }
          break;

          // restart game
        case 'R':
        case 'r':
          gameMode = 0;
          action_times = new ArrayList<Integer>();
          action_type = new ArrayList<String>();
          pipes_y_center = new ArrayList<Integer>();
          next_action_idx = 0;
          next_pipe_idx = 0;

          gameState = 0;
          setup();
          break;
          
        case 'M':
        case 'm':
          muteSound = !muteSound;
          break;

        case 'C':
        case 'c':
          collisionTest = !collisionTest;
          break;

        case 'P':
        case 'p':
          if(gameState == 2){  // if game has finished!
            gameMode = 1;
            next_action_idx = 0;
            next_pipe_idx = 0;
            preview_time_start = frameCount;
  
            gameState = 0;
            setup();
          }
          break;
            
        }
      }


      lastKey = key;
    } else {
      // set lastKey to unused key
      lastKey = '.';
    }
  }

  private void play_sound(AudioPlayer sound){
    if(!muteSound){
      sound.rewind();
      sound.play();
    }
  }
  private void gameState0() {

    bird.setYPosition(game_height/2 + 7 * sin(frameCount/10f));  // small oscillations
    image(tapToStart_img, game_width/2 - tapToStart_img.width/2, game_height*3/5 - tapToStart_img.height/2);
    image(getReady_img, game_width/2 - getReady_img.width/2, game_height/3 - getReady_img.height/2);
  }

  private void gameState1() {
    pipes.positionUpdate();
    distToNextPipe = pipes.getDistToClosestPipe((int)bird.getPosition().x);
    if (distToNextPipe > distToNextPipe2) {  // new pipe crossed!
      play_sound(point_sound);
      points++;
    }
    distToNextPipe2 = distToNextPipe;

    // update bird (velocity, position, direction, distance_covered, imageMode)
    bird.update();

    // COLLISION CHECK
    // ground collision
    if (bird.getPosition().y > game_height - game_ground_height) {
      single_game_time_duration = frameCount - single_game_time_start;
      if (gameMode == 1){
        delay(1000);
        frameRate(gameFrameRate);
      }
      gameMode = 0;
      gameState = 2;
      play_sound(hit_sound);
      bird.setYPosition(game_height - game_ground_height - 5);
      bird.setEnabled(new boolean[]{false, true, false, false});
      game_x_speed = 0;
    // pipe collision
    } else if (checkBirdPipesCollision()) {
      single_game_time_duration = frameCount - single_game_time_start;
      if (gameMode == 1){
        delay(1000);
        frameRate(gameFrameRate);
      }
      gameMode = 0;
      gameState = 2;
      play_sound(hit_sound);
      bird.setEnabled(new boolean[]{false, true, false, false});
      game_x_speed = 0;
    }
  }

  private void gameState2() {
    image(gameOver_img, game_width/2 - gameOver_img.width/2, game_height/3 - gameOver_img.height/2);

    if (bird.getPosition().y < game_height - game_ground_height - 5) {
      bird.addToVelocity(bird.getAcceleration());
      bird.addToPosition(bird.getVelocity());
      bird.direction = getBirdDirection();
    } else {
      bird.direction = 0;
      bird.setYPosition(game_height - game_ground_height - 5);
    }
  }

  private void resizeImage(PImage img, float factor) {
    img.resize((int)(img.width * factor), (int)(img.height * factor));
  }

  private void resizeGif(Animation gif, float factor) {
    gif.width *= factor;
    gif.height *= factor;
    for (PImage img : gif.getFrames()) {
      resizeImage(img, factor);
    }
  }

  private float getBirdDirection() {
    float ans;
    ans = map((float)bird.getVelocity().y, 10f, 2f, PI/2, -PI/8);
    if (ans < -PI/8)ans = -PI/8;
    if (ans > PI/2)ans = PI/2;

    return ans;
  }

  private void defineColors() {
    bird_colors = new ArrayList<Color>();
    bird_colors.add(new Color(255, 50, 50));  // red
    bird_colors.add(new Color(255, 100, 255));  // pink
    bird_colors.add(new Color(50, 150, 255));  // light blue
    bird_colors.add(new Color(0, 255, 0));    // green
    bird_colors.add(new Color(255, 255, 0));  // yellow
    bird_colors.add(new Color(150, 50, 255));  // purple
    bird_colors.add(new Color(100, 100, 100));    // black
    bird_colors.add(new Color(255, 255, 255));  // white
  }

  private boolean checkBirdPipesCollision() {
    boolean ans = false;

    int vert_count = bird.bird_shape_vertices.length;
    PVector[] vertices = new PVector[vert_count];
    for (int i = 0; i < vert_count; i++) {
      vertices[i] = new PVector().add(bird.bird_shape_vertices[i], bird.getPosition());
    }

    float rx, ry;
    float rw = pipes.pipe_width;
    float rh = pipes.pipe_height;

    for (int i = 0; i < pipes.count; i++) {
      float rel_y = game_height - game_ground_height - pipes.y_center_opening[i];
      rx = pipes.x_pos[i] - pipes.pipe_width/2;
      ry = rel_y + pipes.open_size/2;
      ans |= polyRect(vertices, rx, ry, rw, rh);

      rx = pipes.x_pos[i] - pipes.pipe_width/2;
      ry = rel_y - pipes.open_size/2 - rh;
      ans |= polyRect(vertices, rx, ry, rw, rh);

      if (ans)break;
    }

    return ans;
  }

  // POLYGON/RECTANGLE
  private boolean polyRect(PVector[] vertices, float rx, float ry, float rw, float rh) {

    int next = 0;
    for (int current=0; current<vertices.length; current++) {
      next = current+1;
      if (next == vertices.length) next = 0;

      PVector vc = vertices[current];    // c for "current"
      PVector vn = vertices[next];       // n for "next"

      boolean collision = lineRect(vc.x, vc.y, vn.x, vn.y, rx, ry, rw, rh);
      if (collision) return true;
    }
    return false;
  }

  // LINE/RECTANGLE
  private boolean lineRect(float x1, float y1, float x2, float y2, float rx, float ry, float rw, float rh) {

    boolean left =   lineLine(x1, y1, x2, y2, rx, ry, rx, ry+rh);
    boolean right =  lineLine(x1, y1, x2, y2, rx+rw, ry, rx+rw, ry+rh);
    boolean top =    lineLine(x1, y1, x2, y2, rx, ry, rx+rw, ry);
    boolean bottom = lineLine(x1, y1, x2, y2, rx, ry+rh, rx+rw, ry+rh);

    if (left || right || top || bottom) {
      return true;
    }
    return false;
  }

  // LINE/LINE
  private boolean lineLine(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {

    float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));

    if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
      return true;
    }
    return false;
  }
