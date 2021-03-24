import java.util.Arrays; //<>// //<>// //<>// //<>//
import java.util.List;

int timer;
int generation;
boolean createdNewGeneration;
boolean stillMoving;

float bestFitness;

int speedMultiplier = 2;

static final int populationSize = 100;
int timePerGeneration = 5;

String mutationType = "no";

float[] solutionGenes = 
{0.4591651, 
0.540843, 
0.45914054, 
0.45914495, 
0.5408548, 
0.4591558, 
0.45915926, 
0.45914233, 
0.5408727, 
0.4591496, 
0.45914185, 
0.45913744, 
0.45912325, 
0.54084516, 
0.54087305, 
0.5408708, 
0.540861, 
0.45915544, 
0.5408429, 
0.5408622, 
0.5408542, 
0.54083574, 
0.540853, 
0.54087996, 
0.54086745, 
0.54083407, 
0.5408453, 
0.5408361, 
0.5408573, 
0.54084444, 
}
;

boolean solved = false;
Creature solution;
Creature previousTop;
Creature selected;

PVector direction;

Creature[] creatures;

Wall[] walls;

void setup() {

  size(1000, 1000, P2D);

  direction = new PVector(width-20, height/2);

  bestFitness = 0;

  timer = 1;
  generation = 0;
  createdNewGeneration = false;
  creatures = new Creature[populationSize];

  solution = new Creature(solutionGenes);

  for (int i = 0; i < creatures.length; i++) {
    creatures[i] = new Creature();
  }

  walls = new Wall[1];
  //walls[0] = new Wall(new PVector(width/4, height/4), new PVector(30, (height/4)));
  walls[0] = new Wall(new PVector(width/2, 2*height/4), new PVector(30, (height/4)));
  //walls[2] = new Wall(new PVector(3*width/4, height/4), new PVector(30, (height/4)));
}

void draw() {

  background(0);

  pushStyle();
  fill(255);
  ellipse(direction.x, direction.y, 30, 30);
  popStyle();

  stillMoving = false;

  if (selected!=null) {
    pushMatrix();
    translate(width/2, 0);
    creatureInfo(selected);
    popMatrix();

    pushStyle();
    fill(255);
    ellipse(selected.getLocation().x, selected.getLocation().y, 40, 40);
    popStyle();
  }

  for (Wall wall : walls) {
    wall.show();
  }

  if (!solved) {
    for (int i = 0; i < creatures.length; i++) {
      boolean wallCollision = false;
      for (Wall wall : walls) {
        if (creatures[i].hasCollided(wall)) {
          wallCollision = true;
        }
      }
      if (!wallCollision && !creatures[i].isOffScreen())creatures[i].move();

      //creatures[i].checkOverlap();
      if (creatures[i].isVisible()) {
        creatures[i].show();
      }
      creatures[i].check();
    }
  }

  pushStyle();
  stroke(255);
  textSize(20);
  text("Time left: " + Integer.toString(timePerGeneration - timer) + "s", 0, 20);
  text("Generations: " + generation, 0, 40);
  text("Population size: " + populationSize, 0, 60);
  popStyle();

  if (generation>0) {
    text("Current best fitness: " + bestFitness, 0, 80);

    text("Last generation top: ", 0, 100);
    creatureInfo(previousTop);
  }

  if (!solved) {
    if (frameCount%(60) == 0) {
      timer++;
    }

    if (timer%(timePerGeneration) >= 1) {
      createdNewGeneration=false;
    }
    if ((timer%(timePerGeneration) == 0 || !stillMoving) && !createdNewGeneration) {
      selected = null;
      timer = 0;
      createdNewGeneration = true;
      generation++;

      Creature top = creatures[0];
      for (int i = 0; i < creatures.length; i++) {
        if (creatures[i].getFitness() > bestFitness) {
          bestFitness = creatures[i].getFitness();
        }
        if (creatures[i].getFitness() > top.getFitness()) {
          top = creatures[i];
        }
      }
      
      creatures = new Creature[populationSize];
      for (int i = 0; i < creatures.length; i++) {

        creatures[i] = new Creature(top);

        previousTop = top;
      }
    }
  }
  if (solved) {
    creatureInfo(solution);
    boolean wallCollision = false;
    for (Wall wall : walls) {
      if (solution.hasCollided(wall)) {
        wallCollision = true;
      }
    }
    if (!wallCollision && !solution.isOffScreen()){
      solution.move();
    }else{
      solution = new Creature(solutionGenes);
    }
    solution.show();
  }
}

void creatureInfo(Creature best) {

  textSize(20);

  text("  Seed: " + best.getSeed(), 0, 120);
  text("  Fitness: " + best.getFitness(), 0, 140);
  text("  Last turn: " + best.getLastTurn()+"rad.", 0, 160);
  text("  Acc. force: " + best.getAccelerationForce(), 0, 180);
  text("  Max. velocity : " + best.getMaximumVelocity(), 0, 200);
  text("  Mutation amount: " + best.getMutationAmount(), 0, 220);
  text("  Initial direction: " + best.getInitialDirection(), 0, 240);
  text("  Acceleration frequency: " + 60/best.getAccelerationFrequency()+"/s", 0, 260);
  text("  Turn equence: " + best.getTurnSequenceString(), 0, 280);
}

void mousePressed() {
  for (Creature creature : creatures) {
    if (dist(creature.getLocation().x, creature.getLocation().y, mouseX, mouseY) < 5) {
      selected = creature;
      break;
    }
  }
}
