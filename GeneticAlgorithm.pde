import java.util.Arrays; //<>// //<>// //<>// //<>//
import java.util.List;

float[] solutionGenes = 
{0.060411155, 
0.75677484, 
0.66067684, 
0.1981659, 
0.8992988, 
0.12986219, 
0.07193941, 
0.0549348, 
0.6006528, 
0.18245798};


int timer;
int generation;
boolean createdNewGeneration;
boolean stillMoving;

float bestFitness;

//Algorithm parameters
static final int POPULATION_SIZE = 300;
static final int TIME_PER_GENERATION = 10;
static final float SPEED_MULTIPLIER = 2;
static final boolean SOLVED = false;
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

void setup() {
    
    size(1000, 1000, P2D);
    
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
            if (solution.getFitness()>0.997) {
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

void creatureInfo(Creature best) {
    
    textSize(20);
    
    text("  Seed: " + best.getSeed(), 0, 120);
    text("  Fitness: " + best.getFitness(), 0, 140);
    text("  Acc. force: " + best.getAccelerationForce(), 0, 160);
    text("  Max. velocity : " + best.getMaximumVelocity(), 0, 180);
    text("  Mutation amount: " + best.getMutationAmount(), 0, 200);
    text("  Initial direction: " + best.getInitialDirection(), 0, 220);
}

void mousePressed() {
    
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

void mouseReleased() {
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
