package code;

import java.awt.Color;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Random;

import ddf.minim.AudioSample;
import ddf.minim.Minim;
import processing.core.PApplet;
import processing.core.PGraphics;
import processing.core.PImage;
import processing.core.PVector;
import shiffman.box2d.Box2DProcessing;

public class Game_GUI extends PApplet{

	private static final long serialVersionUID = 1L;
	
	Box2DProcessing box2d;
	
	// BIRD
	Bird bird;
	ArrayList<Color> bird_colors;
	
	int counter = 1;
	
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
	private AudioSample wing_flap_sound;
	private AudioSample hit_sound;
	private AudioSample point_sound;
	// pause sound for some time
	
	// *************************************************** GAME VARIABLES ***************************************************
	
	private Pipes pipes;
	private int pipeOpenSize = 100;
	private int currDistToNextPipe;
	private int prevDistToNextPipe;
	
	private int background_index;
	private int points;	// pipes crossed
	
	private int gameFrameRate = 60;
	private float boost_vel = -5;
	
	private int game_width;
	private int game_height;
	private int game_ground_height;
	private float game_x_speed;
	private float game_ground_x_pos;
	private float scale_factor = 0.6f;
	
	private char lastKey;	// keeps the last key character pressed
	private int gameState; // 0: game didnt start yet; 1: game in process; 2: game finished
	
	// *************************************************** GAME VARIABLES (end) ***********************************************
	
	// OTHER VARIABLES
	String rsc_path;
	String img_path;
	String sound_path;
	
	// ***************************************** SETUP *******************************************
	public void setup(){
		
		// get Resources path
		getResourcesPath();

		// GET SOUNDS
		loadSounds(sound_path);
				
		// GET IMAGES
		loadSprites(img_path);

		// use landscape after resize to set the game width and height:
		resizeImage(background_img[0], scale_factor);
		resizeImage(background_img[1], scale_factor);
		game_width = background_img[0].width;
		game_height = background_img[0].height;
		
		// SET WINDOW SIZE
		size((int)(game_width), (int)(game_height), P2D);

		// MAKE BIRD
		defineColors();
		bird = new Bird(img_path, bird_colors.get(new Random().nextInt(bird_colors.size())));

		resizeSpritesSetup();

		// GAME PROPERTIES
		gameState = 0;
		game_ground_height = ground_img.height;
		currDistToNextPipe = game_width * 10;
		prevDistToNextPipe = currDistToNextPipe + 1;
		game_x_speed = -2f;
		game_ground_x_pos = 0;
		points = 0;
		background_index = new Random().nextInt(2);
		
		// define pipes
		PGraphics pipe = createGraphics(down_pipe_img.width, down_pipe_img.height + up_pipe_img.height + pipeOpenSize, JAVA2D);
		pipe.beginDraw();
		pipe.image(down_pipe_img, 0, 0);
		pipe.image(up_pipe_img, 0, up_pipe_img.height + pipeOpenSize);
		pipe.endDraw();
		PImage pipe_img = pipe.get();
		pipes = new Pipes(pipe_img, 4, pipeOpenSize, game_width + 100, 150, game_height - game_ground_height, game_ground_height);
		
		frameRate(gameFrameRate);
	}
	
	public void draw(){
		
		checkKeyPress();

		// ********************************* DRAW SPRITES **************************************
		drawSprites();	// do not draw anything BEFORE this! skyline will be put in front!

		// ******************************* DRAW SPRITES (end) ************************************
		
		if(gameState == 0){		// if game has not started (waiting for the first flap)
			gameState0();
		}else if(gameState == 1){	// if game has started:
			gameState1();
		}else if(gameState == 2){	// game has finished (bird has crashed into the ground or into pipes)
			gameState2();	
		}

	}

	// ******************************************* DRAW (end) *************************************************

	private void loadSprites(String img_path){
		background_img[0] = loadImage(img_path + "skyline_1.png");
		background_img[1] = loadImage(img_path + "skyline_2.png");

		ground_img = loadImage(img_path + "ground.png");
		down_pipe_img = loadImage(img_path + "pipe_down.png");
		up_pipe_img = loadImage(img_path + "pipe_up.png");
		tapToStart_img = loadImage(img_path + "tap_to_start.png");
		gameOver_img = loadImage(img_path + "game_over.png");
		getReady_img = loadImage(img_path + "get_ready.png");
		
		//get digits sprites:
		String[] files = new String[10];
		for(int i = 0; i <= 9; i++)files[i] = "digit_" + i + ".png";
		digits = new Digits(img_path, files, 0.5f);
	}
	
	private void resizeSpritesSetup(){
		resizeImage(ground_img, scale_factor);
		resizeImage(up_pipe_img, scale_factor);
		resizeImage(down_pipe_img, scale_factor);
		resizeImage(gameOver_img, 1.5f);
		resizeImage(getReady_img, 1.3f);
		resizeImage(tapToStart_img, 1f);
		bird.resize(1f);
	}
	
	private void loadSounds(String sound_path){
		Minim minim = new Minim(this);
		wing_flap_sound = minim.loadSample(sound_path + "sfx_wing.wav");
		hit_sound = minim.loadSample(sound_path + "sfx_hit.wav");
		point_sound = minim.loadSample(sound_path + "sfx_point.wav");
	}
	
	public void getResourcesPath(){
		URI uri = null;
		try {
			uri = new URI(Game_GUI.class.getResource("/resources/").toString());
		} catch (URISyntaxException e) {
			e.printStackTrace();
		}
		rsc_path = uri.getPath();
		img_path = rsc_path + "images/";
		sound_path = rsc_path + "sounds/";
	}
	
	private void drawSprites(){
		image(background_img[background_index], 0, 0);

		pipes.display();

		game_ground_x_pos = (game_ground_x_pos + game_x_speed) % (ground_img.width - game_width - 10);
		image(ground_img, game_ground_x_pos , game_height - game_ground_height);

		// draw bird:
		bird.display();
		
		// display score
		digits.displayNumber(points, game_width/2, game_height/10);
	}

	private void checkKeyPress(){
		if(keyPressed){
			// TAP CONTROL
			// avoid continuum pressing
			if(lastKey != key && key == ' '){
				if(gameState == 0){
					gameState = 1;
					bird.setYPosition(game_height/2);
				}
				if(gameState == 1){
					bird.setYVelocity(boost_vel);
					wing_flap_sound.trigger();
				}

			}
			if(gameState == 2 && key == ENTER){
				gameState = 0;
				setup();
			}
			if(lastKey != key && (key == 'r' || key == 'R')){
				gameState = 0;
				setup();
			}
			lastKey = key;
		}else{
			// set lastKey to unused key
			lastKey = '.';
		}
	}
	
	private void gameState0(){
		
		bird.setYPosition(game_height/2 + 7 * sin(frameCount/10f));	// small oscillations
		image(tapToStart_img, game_width/2 - tapToStart_img.width/2, game_height*3/5 - tapToStart_img.height/2);
		image(getReady_img, game_width/2 - getReady_img.width/2, game_height/3 - getReady_img.height/2);
		
	}
	
	private void gameState1(){
		
		pipes.positionUpdate();
		currDistToNextPipe = pipes.getDistToClosestPipe((int)bird.getPosition().x);
		if(currDistToNextPipe > prevDistToNextPipe){	// new pipe crossed!
			point_sound.trigger();
			points++;
		}
		prevDistToNextPipe = currDistToNextPipe;
		
		// update bird (velocity, position, direction, distance_covered, imageMode)
		bird.update();
		
		// COLLISION CHECK
		float bird_pos_x = bird.getPosition().x;
		float bird_pos_y = bird.getPosition().y;
		// ground collision
		if(bird_pos_y > game_height - game_ground_height){
			gameState = 2;
			hit_sound.trigger();
			bird.setYPosition(game_height - game_ground_height - 5);
			bird.setEnabled(new boolean[]{false, true, false, false});
			game_x_speed = 0;
		// pipe collision
		}else if(pipes.isCollision((int)bird_pos_x, (int)bird_pos_y, bird.bird_width, bird.bird_height)){
			gameState = 2;
			hit_sound.trigger();
			bird.setEnabled(new boolean[]{false, true, false, false});
			game_x_speed = 0;
		}
		
	}
	
	private void gameState2(){
		// Display GAME OVER text
		image(gameOver_img, game_width/2 - gameOver_img.width/2, game_height/3 - gameOver_img.height/2);
		
		if(bird.getPosition().y < game_height - game_ground_height - 5){
			bird.addToVelocity(bird.getAcceleration());
			bird.addToPosition(bird.getVelocity());
			bird.direction = getBirdDirection();
		}
		else{
			bird.direction = 0;
			bird.setYPosition(game_height - game_ground_height - 5);
		}

	}
	
	private void resizeImage(PImage img, float factor){
		img.resize((int)(img.width * factor), (int)(img.height * factor));
	}
	
	private float getBirdDirection(){
		float ans;
		ans = map((float)bird.getVelocity().y, 10f, 2f, PI/2, -PI/8);
		if(ans < -PI/8)ans = -PI/8;
		if(ans > PI/2)ans = PI/2;
		
		return ans;
	}
	
	private void defineColors(){
		 bird_colors = new ArrayList<>();
		 bird_colors.add(new Color(255, 50, 50));	// red
		 bird_colors.add(new Color(255, 100, 255));	// pink
		 bird_colors.add(new Color(50, 150, 255));	// light blue
		 bird_colors.add(new Color(0, 255, 0));		// green
		 bird_colors.add(new Color(255, 255, 0));	// yellow
		 bird_colors.add(new Color(150, 50, 255));	// purple
		 bird_colors.add(new Color(100, 100, 100));		// black
		 bird_colors.add(new Color(255, 255, 255));	// white
	}

	private class Bird{
		private Animation bird_gif;
		
		// cinematic variables
		private PVector position;
		private PVector velocity;
		private PVector acceleration;
		private float direction;
		
		// sprite properties:
		private int bird_width;
		private int bird_height;


		public Bird(String img_path, Color c){
			// bird GIF wing flap
			// String[] bird_color_images = {"bird_1.png","bird_2.png","bird_3.png","bird_2.png"};
			String[] bird_color_images = {"bird_color_1.png","bird_color_2.png","bird_color_3.png","bird_color_2.png"};
			String[] bird_body_images = {"bird_body_1.png","bird_body_2.png","bird_body_3.png","bird_body_2.png"};
			PImage[] images = new PImage[4];
			
			for(int i = 0; i < 4; i++){
				PImage bird_body = loadImage(img_path + bird_body_images[i]);
				PImage bird_color = loadImage(img_path + bird_color_images[i]);
				
				PGraphics graphic = createGraphics(bird_body.width, bird_body.height);
				graphic.beginDraw();
				graphic.image(bird_body,0,0);
				graphic.tint(c.getRed(), c.getGreen(), c.getBlue(), 255);	// paint with the requested color
				graphic.image(bird_color,0,0);
				graphic.tint(255,255);	// back to normal
				graphic.endDraw();
				images[i] = (PImage)graphic.get();
			}
			this.bird_gif = new Animation(images, 6);
			bird_width = bird_gif.width;
			bird_height = bird_gif.height;

			// SET CINEMATIC VARIABLES
			// set position to the center of the bird
			position = new PVector(game_width * (1/3f) + bird_width/2, game_height/2 + bird_height/2);
			velocity = new PVector(0, 0);
			acceleration = new PVector(0, 0.3f);
			direction = 0;
		}
		
		public void update(){
			
			// update position and velocity
			bird.addToVelocity(bird.getAcceleration());
			bird.addToPosition(bird.getVelocity());
			if(position.y < 0 ){
				bird.setYVelocity(0);
				bird.setYPosition(0);
			}

			// set enabled images (when bird is going down only one sprite; else do whole animation)
			if(bird.getVelocity().y > 4 ){
				bird.setImageMode("static");
			}else{
				bird.setImageMode("gif");
			}
			
			// CHANGE BIRD DIRETION ACCORDING TO VERTICAL SPEED
			bird.direction = getBirdDirection();
		}
		
		public PVector getPosition(){
			return position;
		}
		
		public PVector getVelocity(){
			return velocity;
		}
		
		public PVector getAcceleration(){
			return acceleration;
		}
		
		public void addToPosition(PVector vel){
			position.add(vel);
		}
		
		public void setYPosition(float y){
			position = new PVector((float)position.x, y);
		}
		
		public void addToVelocity(PVector acel){
			velocity.add(acel);
		}
		
		public void setYVelocity(float y){
			velocity = new PVector((float)velocity.x, y);
		}

		public void setImageMode(String mode){
			switch (mode) {
			case "static":
				setEnabled(new boolean[]{false,true,false,false});
				break;
			case "gif":
				setEnabled(new boolean[]{true,true,true,true});
				break;

			}
		}

		public void setEnabled(boolean e[]){
			bird_gif.setEnabled(e);
		}

		
		public void display(){
			// DRAW BIRD
			pushMatrix();
			translate((int)bird.getPosition().x, (int)bird.getPosition().y);
			rotate(direction);
			translate((int)-bird_gif.width/2, (int)-bird_gif.height/2);
			bird_gif.display();
			popMatrix();
		}

		public void resize(float scale){
			for(PImage img : bird_gif.images){
				resizeImage(img, scale);
			}
		}
		
	}

	private class Animation {
		private PImage[] images;
		private boolean[] enabledImages;
		private int width;
		private int height;
		private int changePerFrames = 1;	// wait this number of frames before changing frame (works as a rate)
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

		public void display() {
			image(images[frame], 0, 0);
			if((currentWait++ % changePerFrames) == 0){
				// go to next enabled image:
				for(int i = 1; i <= images.length; i++){
					if(enabledImages[(frame + i)% images.length]){
						frame = (frame+i) % images.length;
						break;
					}
				}
			}
		}
		
		public void setEnabled(boolean e[]){
			this.enabledImages = e;
		}

	}
	
	private class Digits{
		PImage[] images;
		int digit_width;
		
		// give digits file Strings in order: 0, 1, 2, ..., 8, 9
		public Digits(String path, String[] files, float size_factor){
			images = new PImage[files.length];
			
			for(int i = 0; i < files.length; i++){
				images[i] = loadImage(path + files[i]);
				resizeImage(images[i], size_factor);
			}
			
			digit_width = images[0].width;
		}
		
		public void displayNumber(int num, int x_pos, int y_pos){
			int numberOfDigits;
			if(num == 0){
				numberOfDigits = 1;
			}else{
				numberOfDigits = (int)Math.floor(Math.log10(num) + 1);

			}
			int num_width = numberOfDigits * digit_width;
			int counter = 1;
			int temp = num;
			int digit;
			while(temp > - 1){
				digit = temp % 10;
				temp /= 10;
				int x = x_pos + num_width/2 - counter * digit_width;
				image(images[digit], x, y_pos);
				counter++;
				if(temp == 0)temp = -1;
			}
		}
		
		
	}
	
	private class Pipes{
		
		private PImage pipe_img;
		private int count;
		private float[] x_pos;
		private int[] y_center_opening;	// coordinate of the center of the opening (counting from the ground)
		private int open_size;
		private int pipe_width;
		private int x_spaces;
		private int y_spread;
		
		public Pipes(PImage pipe, int count, int open_size, int spawn_x_start, int x_spacing, int y_spread, int y_ground){
			this.pipe_img = pipe;
			this.x_pos = new float[count];
			this.count = count;
			this.y_center_opening = new int[count];
			this.open_size = open_size;
			this.pipe_width = pipe.width;
			this.x_spaces = x_spacing;
			this.y_spread = y_spread;
			
			for(int i = 0; i < count; i++){
				x_pos[i] = spawn_x_start + i * x_spaces;
				y_center_opening[i] = getRandomYPos();
			}

		}

		public void display(){
		
			for(int i = 0; i < count; i++){
				image(pipe_img, x_pos[i] - pipe_width/2, game_height - game_ground_height - y_center_opening[i] - pipe_img.height/2);
			}
		}
		
		private void positionUpdate(){
			for(int i = 0; i < count; i++){
				x_pos[i] += game_x_speed;

				// if pipe goes out of sight relocate it
				if(x_pos[i] + pipe_width< 0){
					x_pos[i] = x_pos[(i + count - 1) % count] + x_spaces;	// put it behind the last one
					y_center_opening[i] = getRandomYPos();
				}
			}
		}

		private int getRandomYPos(){
			int offset = 50;
			int y = (int)(y_spread/2 + new Random().nextGaussian() * y_spread * 0.1);
			if(y > game_height - game_ground_height - offset - open_size/2)y = game_height - game_ground_height - offset - open_size/2;
			if(y <  offset + open_size)y = offset + open_size/2;
			
			return y;			
		}
		
		// input coordinates (x,y) refer to center of the object
		public boolean isCollision(int x, int y, int w, int h){
			
			boolean ans = false;
			
			for(int i = 0; i < count; i++){
				// skip pipes that are not in the proper x_range
				if((x - w/2  > x_pos[i] + pipe_width/2) || (x  + w/2 < x_pos[i]- pipe_width/2))continue;
				
				// other wise the x coordinates cross! now check for y coordinates:
				// if y coordinates also dont cross we are safe (just break):
				int pipe_y_rel = game_height - game_ground_height - y_center_opening[i]; 
				if((y - h/2 > pipe_y_rel - open_size/2) && (y + h/2  < pipe_y_rel + open_size/2))break;
				// otherwise return true;
				ans = true;
			}
			
			return ans;
		}
		
		public int getDistToClosestPipe(int bird_x){
			int ans = 2*game_width; // hypothetical maximum
			for(int i = 0; i < count; i++){
				if(bird_x < x_pos[i]){
					ans = (int)min(ans, x_pos[i] - bird_x);
				}
			}
			return ans;
		}
		
	}

}

