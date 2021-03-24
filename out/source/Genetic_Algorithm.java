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

public class Genetic_Algorithm extends PApplet {




int timer;
int generation;
boolean createdNewGeneration;
boolean stillMoving;

float bestFitness;

Creature previousTop1;
Creature previousTop2;

int speedMultiplier = 2;

static final int populationSize = 1000;
int timePerGeneration = 10;

static final boolean exponentialMutation = true;
static final float constantMutation = 0.2f;

PVector direction;

Creature[] creatures;

Wall wall1;

public void setup(){
  
  
  
  direction = new PVector(width-20, height/2);
  
  timer = 1;
  generation = 0;
  createdNewGeneration = false;
  creatures = new Creature[populationSize];
  
  for(int i = 0; i < creatures.length; i++){
    creatures[i] = new Creature(direction); 
  }
  
  wall1 = new Wall(new PVector(width/4, height/5), new PVector(30, (height/5)*3));
  
}

public void draw(){
  
  background(0);
  
  pushStyle();
  fill(255);
  ellipse(direction.x, direction.y, 30, 30);
  popStyle();
  
  stillMoving = false;
  
  wall1.show();
  
  for(int i = 0; i < creatures.length; i++){
    if(!creatures[i].isOffScreen() && !creatures[i].hasCollided(wall1)){
      creatures[i].move();
      creatures[i].show();
    }
  }
  
  pushStyle();
  stroke(255);
  textSize(20);
  text("Time left: " + Integer.toString(timePerGeneration - timer) + "s", 0, 20);
  text("Generations: " + generation, 0, 40);
  text("Population size: " + populationSize, 0, 60);
  popStyle();
  
  generationInformation(); //<>//
  
  if(frameCount%(60) == 0){
    timer++;
  }
  
  if(timer%(timePerGeneration) >= 1){
    createdNewGeneration=false;
  }
  if((timer%(timePerGeneration) == 0 || !stillMoving) && !createdNewGeneration){
    timer = 0;
    createdNewGeneration = true; //<>//
    generation++; //<>//
    
    if(!stillMoving){
       
    }
    
    Creature top1 = creatures[0];
     for(int i = 0; i < creatures.length; i++){
      if(creatures[i].getFitness() > top1.getFitness()){
        top1 = creatures[i];
        bestFitness = (creatures[i].getFitness() > bestFitness) ? top1.getFitness() : bestFitness;
      }
    }
    
    List<Creature> creaturesReduced = new ArrayList<Creature>();
    for(Creature creature : creatures){
      if(creature!=top1){
         creaturesReduced.add(creature);
      }
    }
    
    Creature top2 = creaturesReduced.get(0);
    for(Creature creature : creaturesReduced){
      if(creature.getFitness() > top2.getFitness()){
        top2 = creature; 
      }
    }
    
    creatures = new Creature[populationSize];
    for(int i = 0; i < creatures.length; i++){
      if(generation>1){
        Creature newParent1 = (top1.getFitness() > previousTop1.getFitness()) ? top1 : previousTop1;
        Creature newParent2 = (top2.getFitness() > previousTop2.getFitness()) ? top2 : previousTop2;

        previousTop1 = newParent1;
        previousTop2 = newParent2;
        creatures[i] = new Creature(direction, newParent1.getFitness(), generation, newParent1, newParent2);
      }else{
        creatures[i] = new Creature(direction, 0, generation, top1, top2);
        
        previousTop1 = top1;
        previousTop2 = top2;
      } //<>//
    }
        
  }
  
}

public void generationInformation(){
      
  if(generation>0){
    textSize(20);
    text("Current best: " + bestFitness, 0, 80);
    text("Generation:", 0, 100);
    text("Top 1: ", 0, 120);
    text("  Fitness - " + previousTop1.getFitness(), 0, 140);
    text("  Acceleration force - " + previousTop1.getGenes()[3], 0, 160);
    text("  Turning speed - " + previousTop1.getGenes()[4], 0, 180);
    text("  Maximum velocity - " + previousTop1.getGenes()[5], 0, 200);
    text("  Initial direction - (" + previousTop1.getGenes()[6]+", " + previousTop1.getGenes()[7]+")", 0, 220);
    text("  Mutation amount - " + previousTop1.getMutationAmount(), 0, 240);
    text("  Mutation probability - " + previousTop1.getMutationProbability(),0, 260);
    text("  Seed - " + previousTop1.getSeed(), 0, 280);
  }
}
class Creature {

  PVector location;
  PVector velocity;
  PVector acceleration;

  PVector direction;

  float[] genes;

  
  int turns = 1;

  boolean lastRotationUp;

  static final int genePoolSize = 10;
  int collisionPunishment = 0;
  int offScreenPunishment = 0;

  float accelerationAngle;
  
  //Genes:
  int col;                //0, 1, 2
  float accelerationForce;  //3
  float rotationSpeed;      //4
  float maximumVelocity;    //5
  PVector initialDirection; //6, 7
  int seed;                 //8
  int rotationFrequency;    //9

  float mutationAmount;
  float mutationProbability;

  public Creature(PVector direction) {

    this.direction = direction;

    genes = new float[genePoolSize];

    for (int i = 0; i < genePoolSize; i++) {
      genes[i] = random(1);
    }

    readGenes();

    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = initialDirection;
  }

  public Creature(PVector direction, float lastFitness, int generation, Creature parent1, Creature parent2) {

    this.direction = direction;

    genes = new float[genePoolSize];

    for (int i = 0; i < genePoolSize; i++) {
      boolean motherGenes = (random(1)<0.5f) ? true : false;
      genes[i] = ((motherGenes)?parent1.getGenes()[i]:parent2.getGenes()[i]); 

      if (genes[i]<0)genes[i]=0;
      if (genes[i]>1)genes[i]=1;
    }

    mutate(generation, lastFitness);

    readGenes();

    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = initialDirection;
  }

  public float getFitness() {
    float d = dist(location.x, location.y, direction.x, direction.y);
    float dTL = dist(0, 0, direction.x, direction.y);
    float dTR = dist(width, 0, direction.x, direction.y);
    float dBR = dist(width, height, direction.x, direction.y);
    float dBL = dist(0, height, direction.x, direction.y);
    float dMax = max(max(dTL, dTR), max(dBL, dBR));
    float distanceReward = map(d, dMax, 0, 0, 1);          //Max=1
    float velocityReward = velocity.mag()/maximumVelocity; //Max=1
    float turnReward = 1/turns;                            //Max=1
    float timePunishment = timer/timePerGeneration;        //Max=-1
    float fitness = distanceReward + collisionPunishment + offScreenPunishment + velocityReward + turnReward - timePunishment;
    return fitness;
  }

  public void readGenes() {
    int r = (int)mapGene(0, 0, 255);
    int g = (int)mapGene(1, 0, 255);
    int b = (int)mapGene(2, 0, 255);
    col = color(r, g, b);

    accelerationForce = speedMultiplier*(float)(genes[3]/2);
    rotationSpeed =     mapGene(4, 0, HALF_PI);
    maximumVelocity =   speedMultiplier*mapGene(5, 0, 1)*3;
    initialDirection =  new PVector(mapGene(6, -1, 1), mapGene(7, -1, 1));
    seed =              (int)mapGene(8, 0, 100);
    rotationFrequency = (int)mapGene(9, 15, 60);
  }

  public float mapGene(int gene, float lower, float upper) {
    return map(genes[gene], 0, 1, lower, upper);
  }

  public void move() {
    stillMoving =  true;

    noiseSeed(seed);
    if (frameCount%rotationFrequency==0) {
      if (noise(acceleration.x*10, acceleration.y*10) < 0.5f) {
        accelerationAngle += rotationSpeed;
      } else {
        accelerationAngle -= rotationSpeed;
      }

      turns++;
    }

    if (frameCount>0) {
      acceleration.x = accelerationForce * cos(accelerationAngle%TWO_PI);
      acceleration.y = accelerationForce * sin(accelerationAngle%TWO_PI);
    }
    
    velocity.limit(maximumVelocity);

    velocity.add(acceleration);
    location.add(velocity);
  }

  public void mutate(int generation, float lastFitness) {
    for (int i = 0; i < genePoolSize; i++) {

      boolean willMutate = random(1) > lastFitness;  
      mutationProbability = 1-lastFitness;

      //float mutation = 1/(1*(exp(generation/2)));
      //mutationAmount = mutation;

      if (exponentialMutation) {
        if (willMutate ) {
          genes[i] = genes[i] + ((random(1)<0.5f) ? constantMutation : -constantMutation);
        }
      } else {
        genes[i] = genes[i] + ((random(1)<0.5f) ? constantMutation : -constantMutation);
      }


      if (genes[i]<0)genes[i]=0;
      if (genes[i]>1)genes[i]=1;
    }
  }

  public boolean isOffScreen() {
    boolean outX = location.x+8>width || location.x-8<0;
    boolean outY = location.y+8>height || location.y-8<0;
    if (outX || outY) {
      offScreenPunishment = -10;
    }
    return outX || outY;
  }

  public boolean hasCollided(Wall wall) {
    boolean betweenX = location.x+8>wall.getLocation().x && location.x-8<wall.getLocation().x+wall.getSize().x;
    boolean betweenY = location.y+8>wall.getLocation().y && location.y-8<wall.getLocation().y+wall.getSize().y;
    if (betweenX && betweenY) {
      collisionPunishment = -10;
    }
    return betweenX && betweenY;
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
        if(getFitness()>0.99f){
          println("Fitness: " + getFitness());
           for(Float gene : genes){
             println(gene); 
           }
           exit();
        }
      fill(200, 200);
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

  public float getMutationAmount() {
    return mutationAmount;
  }

  public float getMutationProbability() {
    return mutationProbability;
  }
  
  public float getAccelerationForce(){
    return accelerationForce;
  }

  public float getSeed() {
    return seed;
  }

  public float[] getGenes() {
    return genes;
  }
  
  public boolean isLastRotationUp(){
    return lastRotationUp;
  }
}
class Wall{
 
  PVector location;
  PVector size;
  
  public Wall(PVector location, PVector size){
    this.location = location;
    this.size = size;
  }
  
  public void show(){
    pushStyle();
    fill(100);
    rect(location.x, location.y, size.x, size.y);
    popStyle();
  }
  
  public PVector getLocation(){
    return location;
  }
  
  public PVector getSize(){
    return size;
  }
  
}
  public void settings() {  size(1000, 1000, P2D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Genetic_Algorithm" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
