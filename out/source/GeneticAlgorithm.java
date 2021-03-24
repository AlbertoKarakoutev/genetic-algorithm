import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Arrays; 
import java.util.List; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class GeneticAlgorithm extends PApplet {

 //<>// //<>// //<>// //<>//


float[] solutionGenes = 
{0.2561929f,
0.66913694f,
0.61161053f,
0.8175991f,
0.50009596f,
0.3128931f,
0.9460884f,
0.991004f,
0.38070688f,
0.2815694f};

int timer;
int generation;
boolean createdNewGeneration;
boolean stillMoving;

float bestFitness;

//Algorithm parameters
static final int POPULATION_SIZE = 300;
static final int TIME_PER_GENERATION = 10;
static final float SPEED_MULTIPLIER = 2;
static final boolean SOLVED = true;
static final String MUTATION_TYPE = "random"; //exponential/exponential-random/random/constant/no

Creature solution;
Creature previousTop;
Creature selected;
Creature[] creatures;

PVector direction;

//Wall variables
ArrayList<Wall> walls;
PVector newPosition;
PVector newSize;
boolean newPositionSet = false;

public void setup() {
    
    
    
    direction = new PVector(width / 2, 40);
    
    bestFitness = 0;
    
    timer = 1;
    generation = 0;
    createdNewGeneration = false;
    creatures = new Creature[POPULATION_SIZE];
    
    solution = new Creature(solutionGenes);
    
    for (int i = 0; i < creatures.length; i++) {
        creatures[i] = new Creature();
    }
    
    walls = new ArrayList<Wall>();
    walls.add(new Wall(new PVector(width / 2, 2 * height / 4), new PVector(30,(height / 4))));
    walls.add(new Wall(new PVector(2,height/3), new PVector(width/4,30)));
}

public void draw() {
    
    background(0);
    
    pushStyle();
    fill(255);
    noStroke();
    ellipse(direction.x, direction.y, 35, 35);
    popStyle();
    
    for (Wall wall : walls) {
        wall.show();
    }
    
    stillMoving = false;
    
    if (selected!= null) {
        pushMatrix();
        translate(width / 2, 0);
        creatureInfo(selected);
        
        text("  Last turn: " + selected.getLastTurn() + "rad.", 0, 280);
        popMatrix();
        
        pushStyle();
        fill(255);
        ellipse(selected.getLocation().x, selected.getLocation().y, 40, 40);
        popStyle();
    }
    
    pushStyle();
    stroke(255);
    textSize(20);
    text("Time left: " + Integer.toString(TIME_PER_GENERATION - timer) + "s", 0, 20);
    text("Generations: " + generation, 0, 40);
    text("Population size: " + POPULATION_SIZE, 0, 60);
    popStyle();
    
    if (generation > 0) {
        text("Overall best fitness: " + bestFitness, 0, 80);
        text("Last generation's top performer: ", 0, 100);
        creatureInfo(previousTop);
    }
    
    if (!SOLVED) {
        for (Creature creature : creatures) {
            boolean wallCollision = false;
            for (Wall wall : walls) {
                if (creature.hasCollided(wall)) {
                    wallCollision = true;
                }
            }
            if (!wallCollision && !creature.isOffScreen())creature.move();
            
            //creatures[i].checkOverlap();
            if (creature.isVisible()) {
                creature.show();
            }
            creature.check();
        }
        
        if (frameCount % (60) == 0) {
            timer++;
        }
        
        if (timer % (TIME_PER_GENERATION) >= 1) {
            createdNewGeneration = false;
        }
        if ((timer % (TIME_PER_GENERATION) == 0 || !stillMoving) && !createdNewGeneration) {
            selected = null;
            timer = 0;
            createdNewGeneration = true;
            generation++;
            
            //Find the top performer
            Creature top = creatures[0];
            for (Creature creature : creatures) {
                if (creature.getFitness() > bestFitness) {
                    bestFitness = creature.getFitness();
                }
                if (creature.getFitness() > top.getFitness()) {
                    top = creature;
                }
            }
            
            //Re-initialize the population with the genes of the "top" creature
            creatures = new Creature[POPULATION_SIZE];
            for (int i = 0; i < POPULATION_SIZE; i++) {
                creatures[i] = new Creature(top.getGenes(), top.getFitness());
                previousTop = top;
            }
            
        }
    } else {
        creatureInfo(solution);
        boolean wallCollision = false;
        for (Wall wall : walls) {
            if (solution.hasCollided(wall)) {
                wallCollision = true;
            }
        }
        if (!wallCollision && !solution.isOffScreen()) {
            solution.move();
            if (solution.getFitness()>0.997f) {
                noLoop();
            }
        }
        solution.show();
    }
    
    if (mousePressed) {
        if (mouseButton == LEFT) {
            pushStyle();
            if (mouseX - newPosition.x < 0 || mouseY - newPosition.y < 0) { 
                fill(255, 0, 0, 200);
            } else {
                fill(100);
            }
            strokeWeight(2);
            rect(newPosition.x, newPosition.y, mouseX - newPosition.x, mouseY - newPosition.y);
            popStyle();
        }
    }
}

public void creatureInfo(Creature best) {
    
    textSize(20);
    
    text("  Seed: " + best.getSeed(), 0, 120);
    text("  Fitness: " + best.getFitness(), 0, 140);
    text("  Acc. force: " + best.getAccelerationForce(), 0, 160);
    text("  Max. velocity : " + best.getMaximumVelocity(), 0, 180);
    text("  Mutation amount: " + best.getMutationAmount(), 0, 200);
    text("  Initial direction: " + best.getInitialDirection(), 0, 220);
    text("  Noise offset: " + best.getNoiseOffset(), 0, 240);
}

public void mousePressed() {
    
    boolean creatureSelect = false;
    if (mouseButton == LEFT) {
        for (Creature creature : creatures) {
            if (dist(creature.getLocation().x, creature.getLocation().y, mouseX, mouseY) < 5) {
                selected = creature;
                creatureSelect = true;
                break;
            }
        }
        if (!creatureSelect && !newPositionSet) {
            newPosition = new PVector(mouseX, mouseY);
            newPositionSet = true;
        }
    } else if (mouseButton == RIGHT) {
        for (Wall wall : walls) {
            if (mouseX > wall.getLocation().x && mouseX < wall.getLocation().x + wall.getSize().x && mouseY > wall.getLocation().y && mouseY < wall.getLocation().y + wall.getSize().y) {
                walls.remove(wall);
                newPositionSet = false;
                break;
            }
        }
    }
}

public void mouseReleased() {
    if (mouseButton == LEFT) {
        newPositionSet = false;
        
        float mouse_x = (mouseX<2) ? 2 : mouseX;
        mouse_x = (mouseX>width - 2) ? width - 2 : mouseX;
        float mouse_y = (mouseY<2) ? 2 : mouseY;
        mouse_y = (mouseY>height - 2) ? height - 2 : mouseY;
        if (mouseX - newPosition.x > 0 && mouseY - newPosition.y > 0) {
            newSize = new PVector(mouse_x - newPosition.x, mouse_y - newPosition.y);
            walls.add(new Wall(newPosition, newSize));
        }
    }
}
class Creature { //<>//

  PVector location;
  PVector velocity;
  PVector acceleration;

  float[] genes;

  boolean firstFrame = true;
  boolean visible = true;

  static final int genePoolSize = 10;
  int collisionPunishment = 0;
  int offScreenPunishment = 0;
  int goalNotVisiblePunishment = 0;

  float accelerationAngle = 0;
  float lastTurn;
  float noiseLocation = 0;

  //Genes:
  int col;                //0,1,2
  float accelerationForce;  //3
  float rotationSpeed;      //4
  float maximumVelocity;    //5
  int seed;                 //6
  PVector initialDirection; //7,8
  int noiseOffset;           //9

  int statringFrameCount;

  float mutationAmount;

  public Creature() {

    genes = new float[genePoolSize];

    for (int i = 0; i < genePoolSize; i++) {
      genes[i] = random(1);
    }

    readGenes();

    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = new PVector(0, 1);
  }

  public Creature(float[] genes) {

    this.genes = genes;

    readGenes();

    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = new PVector(0, 1);
  }

  public Creature(float[] genes, float fitness) {

    this.genes = genes;

    mutate(fitness);
    readGenes();

    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = new PVector(0, 1);
  }

  public float getFitness() {
    float d = dist(location.x, location.y, direction.x, direction.y);
    float dTL = dist(0, 0, direction.x, direction.y);
    float dTR = dist(width, 0, direction.x, direction.y);
    float dBR = dist(width, height, direction.x, direction.y);
    float dBL = dist(0, height, direction.x, direction.y);
    float dMax = max(max(dTL, dTR), max(dBL, dBR));
    float distanceReward = map(d, dMax, 0, 0, 3);          //Max=1
    float velocityReward = (velocity.mag()!=0 || maximumVelocity!=0) ? velocity.mag()/maximumVelocity : 0; //Max=1
    checkVisibleGoal();
    float fitness = distanceReward + collisionPunishment + offScreenPunishment + goalNotVisiblePunishment /*+ velocityReward - turnPenalty*/;
    //float fitnessMapped = map(fitness, -1, 1, 0, 1);
    return fitness;
  }

  public void readGenes() {
    int r = (int)mapGene(0, 0, 255);
    int g = (int)mapGene(1, 0, 255);
    int b = (int)mapGene(2, 0, 255);
    col = color(r, g, b);

    accelerationForce = SPEED_MULTIPLIER*mapGene(3, 0.2f, 1);
    rotationSpeed =     mapGene(4, 1, PI/2);
    maximumVelocity =   SPEED_MULTIPLIER*mapGene(5, 0.1f, 1)*5;
    seed =              (int)mapGene(6, 2, 1000);
    initialDirection = new PVector(mapGene(7, -1, 1), mapGene(8, -1, 1));
    noiseOffset = (int)mapGene(9, 0, 10000);
  }

  public void move() {
    stillMoving =  true;
    if (firstFrame) {
      statringFrameCount = frameCount;
      acceleration.rotate(initialDirection.heading());
      firstFrame=false;
    }

    noiseSeed(seed);
    float rotationDirection = map(noise(noiseOffset + noiseLocation), 0, 1, -1, 1);
    float thisTurn = 0;
    if (rotationDirection>0) {
      thisTurn = rotationSpeed*rotationDirection;
    } else {
      thisTurn = TWO_PI+(rotationSpeed*rotationDirection);
    }
    noiseLocation+=100;

    lastTurn = thisTurn;
    accelerationAngle += thisTurn;

    acceleration.x += accelerationForce * cos(accelerationAngle);
    acceleration.y += accelerationForce * sin(accelerationAngle);
    
    velocity.add(acceleration);
    velocity.limit(maximumVelocity);

    location.add(velocity);
  }

  public void mutate(float lastFitness) {
    float mutation = 0;

    switch(MUTATION_TYPE) {
    case "exponential-random":
      mutation = exp(-5*lastFitness)/2 - random(exp(-5*lastFitness)/5);
      break;
    case "exponential":
      mutation = exp(-5*lastFitness)/2;
      break;
    case "constant":
      mutation = 0.2f;
      break;
    case "random":
      mutation = random(0.0001f);
      break;
    case "no":
      mutation = 0;
      break;
    }
    mutationAmount = mutation;

    for (int i = 0; i < genePoolSize; i++) {

      boolean willMutate = random(1) > 0.5f; 

      if (willMutate) {
        if (genes[i] > 0.5f) {
          genes[i] -= mutation;
        } else {
          genes[i] += mutation;
        }
      }
      if (genes[i]<0)genes[i]=abs(genes[i]);
      if (genes[i]>1)genes[i]=2-genes[i];
    }
  }

  public void show() {

    boolean top = true;
    for (Creature creature : creatures) {
      if (creature.getFitness() > getFitness()) {
        top = false;
        break;
      }
    }
    pushStyle();
    noStroke();
    if (top) {
      fill(200, 100);
      textAlign(CENTER);
      text("TOP", location.x, location.y-30);
      ellipse(location.x, location.y, 50, 50);
    }
    fill(col);
    shapeMode(CENTER);
    pushMatrix();
    translate(location.x, location.y);
    rotate(velocity.heading()+PI/2);
    triangle(0, -8, -4, 8, 4, 8);
    popMatrix();
    popStyle();
  }

  public float mapGene(int gene, float lower, float upper) {
    return map(genes[gene], 0, 1, lower, upper);
  }

  public boolean isOffScreen() {
    float d = dist(location.x, location.y, direction.x, direction.y);
    float dTL = dist(0, 0, direction.x, direction.y);
    float dTR = dist(width, 0, direction.x, direction.y);
    float dBR = dist(width, height, direction.x, direction.y);
    float dBL = dist(0, height, direction.x, direction.y);
    float dMax = max(max(dTL, dTR), max(dBL, dBR));
    boolean outX = location.x+8>width || location.x-8<0;
    boolean outY = location.y+8>height || location.y-8<0;
    if (outX || outY) {
      offScreenPunishment = (int)map(d, 0, dMax, 0, -1);
    }
    return outX || outY;
  }

  public boolean hasCollided(Wall wall) {
    boolean betweenX = location.x+8>wall.getLocation().x && location.x-8<wall.getLocation().x+wall.getSize().x;
    boolean betweenY = location.y+8>wall.getLocation().y && location.y-8<wall.getLocation().y+wall.getSize().y;
    if (betweenX && betweenY) {
      collisionPunishment = -1;
    }
    return betweenX && betweenY;
  }

  public void checkVisibleGoal(){
    float x1 = direction.x;
    float y1 = direction.y;
    float x2 = location.x;
    float y2 = location.y;

    for(Wall wall : walls){
      for(int i = 0; i < 4; i++){
        PVector corner1 = wall.getShape().getVertex(i);
        PVector corner2 = wall.getShape().getVertex((i+1)%4);

        float x3 = corner1.x; 
        float y3 = corner1.y;
        float x4 = corner2.x;   
        float y4 = corner2.y;

        float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
        float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
        if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
          goalNotVisiblePunishment=-2;
          return;
        }
      }
    }
  }

  public void check() {
    if (getFitness()>0.997f) {
      //solution = new Creature(getGenes());
      //solved = true;
      println("Fitness: " + getFitness());

      print("{");
      for (int i = 0; i < genes.length; i++) {
        print(genes[i]);
        if(i<genes.length-1){
          print(", \n");
        }
      }
      println("};");

      exit();
    }
  }

  public float getMutationAmount() {
    return mutationAmount;
  }

  public float getAccelerationForce() {
    return accelerationForce;
  }

  public float getMaximumVelocity() {
    return maximumVelocity;
  }

  public PVector getInitialDirection() {
    return initialDirection;
  }

  public float getNoiseOffset() {
    return noiseOffset;
  }

  public float getLastTurn() {
    return lastTurn;
  }

  public float getSeed() {
    return seed;
  }

  public float[] getGenes() {
    return genes;
  }

  public PVector getLocation() {
    return location;
  }

  public boolean isVisible() {
    return visible;
  }
}
class Wall{
 
  PVector location;
  PVector size;
  
  PShape wallShape;

  public Wall(PVector location, PVector size){
    this.location = location;
    this.size = size;
    wallShape = createShape(RECT, location.x, location.y, size.x, size.y);
  }
  
  public void show(){
    pushStyle();
    shape(wallShape);
    popStyle();
  }
  
  public PVector getLocation(){
    return location;
  }
  
  public PVector getSize(){
    return size;
  }
  
  public PShape getShape(){
    return wallShape;
  }
}
  public void settings() {  size(1000, 1000, P2D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GeneticAlgorithm" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
