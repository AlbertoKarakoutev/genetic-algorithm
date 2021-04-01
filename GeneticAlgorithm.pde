import java.util.Arrays; //<>// //<>// //<>// //<>//
import java.util.List;

float[] solutionGenes = 
{0.34707582, 
0.05257368, 
0.24554408, 
0.38847464, 
0.02394408, 
0.71729773, 
0.09751338, 
0.2722419, 
0.96869606, 
0.7224445, 
0.15077323, 
0.66264176};


int timer;
int generation;
boolean createdNewGeneration;
boolean stillMoving;
boolean pause = false;

float bestFitness;

//Algorithm parameters
static final int POPULATION_SIZE = 500;
static final int TIME_PER_GENERATION = 15;
static final float SPEED_MULTIPLIER = 2;
static final boolean SOLVED = true;
static final boolean AVOID = true;
static final String MUTATION_TYPE = "exponential-random"; /* [ exponential / exponential-random / random / constant / no ] */
static final float ACCURACY = 0.98;
static final float WALL_PUNISHMENT = -0.5;
static final float OFF_SCREEN_PUNISHMENT = -1;
static final float GOAL_NOT_VISIBLE_PUNISHMENT =-2;
static final float DISTANCE_REWARD_MAX = abs(WALL_PUNISHMENT - OFF_SCREEN_PUNISHMENT - GOAL_NOT_VISIBLE_PUNISHMENT) + 1;

Creature solution;
Creature previousTop;
Creature selected;
Creature[] creatures;
List<Creature> generationSolutions;

PVector direction;

//Wall variables 
ArrayList<Wall> walls;
PVector newPosition;
PVector newSize;
boolean newPositionSet = false;

void setup() {

  size(1000, 1000, P2D);
  direction = new PVector(width / 2, 40);

  bestFitness = 0;

  timer = 1;
  generation = 0;
  createdNewGeneration = false;
  creatures = new Creature[POPULATION_SIZE];

  solution = new Creature(solutionGenes);
  generationSolutions = new ArrayList<Creature>();

  for (int i = 0; i < creatures.length; i++) {
    creatures[i] = new Creature();
  }

  walls = new ArrayList<Wall>();
  walls.add(new Wall(new PVector(2, height/3), new PVector(3*width/4, 30)));
  walls.add(new Wall(new PVector(3*width/4, height/3), new PVector(30,(height / 6))));
  walls.add(new Wall(new PVector(width/4, height/2), new PVector(2*width/4, 30)));
  walls.add(new Wall(new PVector(2, 2*height/3), new PVector(3*width/4, 30)));
  walls.add(new Wall(new PVector(3*width/4, 2), new PVector(30,(height / 6))));
  walls.add(new Wall(new PVector(width/6, height/6), new PVector(3*width/4 - width/6, 30)));
}

void draw() {

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
    translate(width / 2, -100);
    creatureInfo(selected);
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
    
    //Move and show all the creatures if they haven't stopped
    for (Creature creature : creatures) {
      boolean wallCollision = false;
      for (Wall wall : walls) {
        if (creature.hasCollided(wall, creature.getLocation())) {
          creature.setCollisionPunishment(WALL_PUNISHMENT);
          wallCollision = true;
        }
      }
      if (!wallCollision && !creature.isOffScreen() && !pause)creature.move();
      creature.show();
      creature.check();
    }

    //Increment the timer every 60 frames
    if (frameCount % (60) == 0 && !pause) {
      timer++;
    }
    
    if (timer % (TIME_PER_GENERATION) >= 1) {
      createdNewGeneration = false;
    }
    
    //Create the new generation
    if ((timer % (TIME_PER_GENERATION) == 0 || !stillMoving) && !createdNewGeneration && !pause) {
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
    pushStyle();
    textSize(50);
    text("VIEWING SOLUTION", width/2-250, height-100);
    popStyle();
    boolean wallCollision = false;
    for (Wall wall : walls) {
      if (solution.hasCollided(wall, solution.getLocation())) {
        wallCollision = true;
      }
    }
    if (!wallCollision && !solution.isOffScreen() && !pause) {
      solution.move();
      if (solution.getFitness()>ACCURACY*DISTANCE_REWARD_MAX) {
        noLoop();
      }
    }
    solution.show();
  }

  if (mousePressed) {
    if (mouseButton == LEFT) {
      if (newPosition != null) {
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
}

void creatureInfo(Creature best) {

  textSize(20);

  text("  Seed: " + best.getSeed(), 0, 120);
  text("  Fitness: " + best.getFitness(), 0, 140);
  text("  Wall punishment: " + best.getWallPunishment(), 0, 160);
  text("  Off-screen punishment: " + best.getOffScreenPunishment(), 0, 180);
  text("  Goal punishment: " + best.getGoalPunishment(), 0, 200);
  text("  Acc. force: " + best.getAccelerationForce(), 0, 220);
  text("  Max. velocity : " + best.getMaximumVelocity(), 0, 240);
  text("  Mutation amount: " + best.getMutationAmount(), 0, 260);
  text("  Initial direction: " + best.getInitialDirection(), 0, 280);
  text("  Avoidance: " + best.getAvoidance(), 0, 300);
}

void mousePressed() {

  boolean creatureSelect = false;
  if (mouseButton == LEFT) {
    //Select a creature
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
    //Remove a wall
    for (Wall wall : walls) {
      if (mouseX > wall.getLocation().x && mouseX < wall.getLocation().x + wall.getSize().x && mouseY > wall.getLocation().y && mouseY < wall.getLocation().y + wall.getSize().y) {
        walls.remove(wall);
        newPositionSet = false;
        break;
      }
    }
  }
}

void mouseReleased() {
  if (mouseButton == LEFT) {
    if (newPosition != null) {
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
}

void keyPressed() {
  if (key == ' ') {
    pause=!pause;
  }
}
