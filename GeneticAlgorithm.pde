import java.util.Arrays; //<>//
import java.util.List;
import processing.sound.*;

/*Labirynth 1 solution*/
float[] solutionGenes = 
{0.74257475, 
0.2815247, 
0.50877297, 
0.884677, 
0.9273903, 
0.05489403, 
0.73953724, 
0.105920196, 
0.83321095};


/*Labirynth 2 solution*/
//float[] solutionGenes = 
//{0.363456, 
//0.033715487, 
//0.30815732, 
//0.74984586, 
//0.9954581, 
//0.78455096, 
//0.77401865, 
//0.7113639, 
//0.8150138};


int timer;
int generation;
int noUpgradeCounter;
boolean createdNewGeneration;
boolean stillMoving;
boolean pause = false;

float bestFitness;

//Algorithm parameters
static final int POPULATION_SIZE = 500;
static final int TIME_PER_GENERATION = 17;
static final float SPEED_MULTIPLIER = 1;
static final boolean SOLVED = true;
static final String MUTATION_TYPE = "exponential-random"; /* [ exponential / exponential-random / random / constant / no ] */
static final float ACCURACY = 0.98;
static final float WALL_PUNISHMENT = -0.5;
static final float OFF_SCREEN_PUNISHMENT = -1;
static final float GOAL_NOT_VISIBLE_PUNISHMENT =-0.5;
static final float DISTANCE_REWARD_MAX = abs(WALL_PUNISHMENT - OFF_SCREEN_PUNISHMENT) + 1;
static final int WALL_GRID_SIZE = 10;

Creature solution;
Creature previousTop;
Creature selected;
Creature[] creatures;
List<Creature> generationSolutions;

PVector direction;

//Wall variables 
ArrayList<Wall> walls;
PVector newVertex1;
PVector newVertex2;
boolean newVertex1Set = false;


SoundFile done;
SoundFile no_upgrade;
SoundFile upgrade;
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
    
    previousTop = creatures[0];
    
    walls = new ArrayList<Wall>();
    
    /*Labirynth 1 walls*/
    walls.add(new Wall(0, 3, 8, 3));
    walls.add(new Wall(8, 1.5, 8, 5));
    walls.add(new Wall(2, 5, 8, 5));
    walls.add(new Wall(1, 7, 10, 7));
    walls.add(new Wall(0, 8, 9, 8));
    walls.add(new Wall(6, 0, 6, 1.5));  
    walls.add(new Wall(2, 1.5, 6, 1.5));
    walls.add(new Wall(8, 9, 8, 10));
    walls.add(new Wall(3, 9, 8, 9));
    walls.add(new Wall(2, 6, 10, 6));
    
    /*Labirynth 2 walls*/
    //walls.add(new Wall(0, 0, 1, 1));
    //walls.add(new Wall(2, 1, 3, 2));
    //walls.add(new Wall(1, 2, 2, 3));
    //walls.add(new Wall(5, 1, 6, 2));
    //walls.add(new Wall(4, 2, 5, 3));  
    //walls.add(new Wall(3, 3, 4, 4));
    //walls.add(new Wall(3, 5, 4, 6));
    //walls.add(new Wall(6, 4, 7, 5));
    //walls.add(new Wall(6, 6, 7, 7));
    //walls.add(new Wall(0, 6, 1, 7));
    //walls.add(new Wall(2, 7, 3, 8));
    //walls.add(new Wall(3, 2, 4, 3));
    
    done = new SoundFile(this, "done.wav");
    upgrade = new SoundFile(this, "upgrade.wav");
    no_upgrade = new SoundFile(this, "no-upgrade.wav");
    
    done.amp(0.5);
    upgrade.amp(0.5);
    no_upgrade.amp(0.5);
}

void draw() {

    background(51);

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
    text("Consecutive upgrade fails: " + noUpgradeCounter, 0, 80);
    popStyle();

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
            Creature[] sorted = QuickSort(creatures, 0, creatures.length - 1);
            Creature first = sorted[creatures.length - 1];
            
            if(previousTop.getFitness() >= first.getFitness()){
                no_upgrade.play();
                noUpgradeCounter++;
                if(noUpgradeCounter > 20){
                    for(int i = 0; i < sorted.length/2; i++){
                        Creature temp = sorted[i];
                        sorted[i] = sorted[(sorted.length - 1) - i];
                        sorted[(sorted.length - 1) - i] = temp;
                    }
                    noUpgradeCounter = 0;   
                }
            }else{
                upgrade.play();
                noUpgradeCounter = 0;
            }
            bestFitness = first.getFitness();
            previousTop = first;
            
            //Two new creatures are added from two parents in descending order
            for(int i = POPULATION_SIZE - 1; i >= POPULATION_SIZE/2; i-=2){
                
                Creature parent1 = sorted[i];
                Creature parent2 = sorted[i-1];
                sorted[i - POPULATION_SIZE/2] = new Creature(parent1.getGenes(), parent2.getGenes(), parent1.getFitness());
                sorted[i - POPULATION_SIZE/2 - 1] = new Creature(parent1.getGenes(), parent2.getGenes(), parent1.getFitness());
                sorted[i] = new Creature(parent1.getGenes());
                sorted[i-1] = new Creature(parent2.getGenes()); 
            }

            creatures = sorted;

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
    
    if (generation > 0) {
        text("Overall best fitness: " + bestFitness, 0, 100);
        text("Last generation's top performer: ", 0, 760);
        creatureInfo(previousTop);
    }
    
    if (mousePressed) {
        if (mouseButton == LEFT) {
            if (newVertex1 != null) {
                pushStyle();
                if (mouseX - newVertex1.x < 0 || mouseY - newVertex1.y < 0) { 
                    fill(255, 0, 0, 200);
                } else {
                    fill(100);
                }
                strokeWeight(2);
                rect(newVertex1.x, newVertex1.y, mouseX - newVertex1.x, mouseY - newVertex1.y);
                popStyle();
            }
        }
    }
}

void creatureInfo(Creature best) {

    //int xOff = 0;
    int yOff = 660;

    textSize(20);

    text("  Fitness: " + best.getFitness(), 0, 140+yOff);
    text("  Wall punishment: " + best.getWallPunishment(), 0, 160+yOff);
    text("  Off-screen punishment: " + best.getOffScreenPunishment(), 0, 180+yOff);
    text("  Goal punishment: " + best.getGoalPunishment(), 0, 200+yOff);
    text("  Acc. force: " + best.getAccelerationForce(), 0, 220+yOff);
    text("  Max. velocity : " + best.getVelocityForce(), 0, 240+yOff);
    text("  Mutation amount: " + best.getMutationAmount(), 0, 260+yOff);
    text("  Initial direction: " + best.getInitialDirection(), 0, 280+yOff);
    text("  Avoidance: " + best.getAvoidance(), 0, 300+yOff);
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
        if (!creatureSelect && !newVertex1Set) {
            newVertex1 = new PVector(mouseX, mouseY);
            newVertex1Set = true;
        }
    } else if (mouseButton == RIGHT) {
        //Remove a wall
        for (Wall wall : walls) {
            if (mouseX > wall.getVertex1().x && mouseX < wall.getVertex2().x && mouseY > wall.getVertex1().y && mouseY < wall.getVertex2().y) {
                walls.remove(wall);
                newVertex1Set = false;
                break;
            }
        }
    }
}

void mouseReleased() {
    if (mouseButton == LEFT) {
        if (newVertex1 != null) {
            newVertex1Set = false;

            float mouse_x = (mouseX<2) ? 2 : mouseX;
            mouse_x = (mouseX>width - 2) ? width - 2 : mouseX;
            float mouse_y = (mouseY<2) ? 2 : mouseY;
            mouse_y = (mouseY>height - 2) ? height - 2 : mouseY;
            if (mouseX - newVertex1.x > 0 && mouseY - newVertex1.y > 0) {
                newVertex2 = new PVector(mouse_x, mouse_y);
                newVertex2.div(width/WALL_GRID_SIZE);
                newVertex1.div(width/WALL_GRID_SIZE);
                walls.add(new Wall(newVertex1.x, newVertex1.y, newVertex2.x, newVertex2.y));
            }
        }
    }
}

void keyPressed() {
    if (key == ' ') {
        pause=!pause;
    }
}

Creature[] QuickSort(Creature[] input, int start, int end) {
    Creature[] local = input;
    if (start >= end)
        return local;

    // Partition
    float pivotValue = local[end].getFitness();
    int pIndex = start;
    {
        for (int i = start; i < end; i++) {
            if (local[i].getFitness() < pivotValue) {
                Creature temp = local[pIndex];
                local[pIndex] = local[i];
                local[i] = temp;
                pIndex++;
            }
        }
        Creature temp = local[pIndex];
        local[pIndex] = local[end];
        local[end] = temp;
    }

    local = QuickSort(local, start, pIndex - 1);
    local = QuickSort(local, pIndex + 1, end);
    return local;
}
