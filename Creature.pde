class Creature { //<>// //<>//

  PVector location;
  PVector velocity;
  PVector acceleration;

  float[] genes;

  boolean firstFrame = true;
  boolean visible = true;

  static final int genePoolSize = 12;
  float collisionPunishment = 0;
  float offScreenPunishment = 0;
  float goalNotVisiblePunishment = 0;

  float accelerationAngle = 0;
  float lastTurn;

  //Genes:
  color col;                //0,1,2
  float accelerationForce;  //3
  float rotationSpeed;      //4
  float maximumVelocity;    //5
  int seed;                 //6
  PVector initialDirection; //7,8
  int rayLength;            //9
  float noiseLocation;      //10
  float avoidance;          //11

  int statringFrameCount;

  double mutationAmount;


  /*
    Initialization constructor that creates a random gene array.
  */
  public Creature() {
    genes = new float[genePoolSize];
    for (int i = 0; i < genePoolSize; i++) {
      genes[i] = random(1);
    }
    readGenes();
    location = new PVector(10, height/2);
    velocity = new PVector();
    acceleration = new PVector(0, 1);
  }


  /*
    A no-mutation constructor for the viewing of the "solution" of the algorithm.
  */
  public Creature(float[] genes) {
    this.genes = genes;
    readGenes();
    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = new PVector(0, 1);
  }


  /*
    An inheritance constructor that evolves the children 
    from their parents' genes and mutates them.
  */
  public Creature(float[] genes, float fitness) {
    this.genes = genes;
    mutate(fitness);
    readGenes();
    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = new PVector(0, 1);
  }


  /*
    Calculates the rotation of the acceleration vector, 
    based on a Perlin noise function and maps it in the range(-1;1). Multiplies 
    that by the angle of rotation per frame(rotationSpeed). Aggregates that to the 
    acceleration angle and sets the acceleration. Adds that to the velocity, 
    and the velocity to the location.
  */
  void move() {
    stillMoving =  true;
    if (firstFrame) {
      statringFrameCount = frameCount;
      acceleration.rotate(-initialDirection.heading());
      firstFrame=false;
    }

    noiseSeed(seed);
    float rotationDirection = map(noise(noiseLocation), 0, 1, -1, 1);
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

    if(AVOID){
      avoidBounds();
      avoidWalls();
    }

    velocity.add(acceleration);
    velocity.limit(maximumVelocity);

    location.add(velocity);
    acceleration.set(0, 0);
  }


  /*
    Draws the creature to the screen.
    If it is the top performer, marks it as such.
  */
  void show() {
    checkOverlap();
    if(!isVisible()){
      return; 
    }
    
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


  /*
    Calculates the "Fitness" function for a creature at a given point.
    The fitness function is calculated by subtracting the penalties for:
    - A wall collision (0;-1)
    - An out of screen punishment (0;-1)
    - A goal visibility punishment (0;-2)
    And then adding the distance to the goal reward (0;4).
  */
  float getFitness() {
    float d = dist(location.x, location.y, direction.x, direction.y);
    float dTL = dist(0, 0, direction.x, direction.y);
    float dTR = dist(width, 0, direction.x, direction.y);
    float dBR = dist(width, height, direction.x, direction.y);
    float dBL = dist(0, height, direction.x, direction.y);
    float dMax = max(max(dTL, dTR), max(dBL, dBR));
    float distanceReward = map(d, dMax, 0, 0, DISTANCE_REWARD_MAX);
    if(timer > TIME_PER_GENERATION/2){
      distanceReward -= timer/TIME_PER_GENERATION;
    }
    if (wallIsBlocking(direction)!=null) {
      goalNotVisiblePunishment=GOAL_NOT_VISIBLE_PUNISHMENT;
    } else {
      goalNotVisiblePunishment=0;
    }
    float fitness = distanceReward + collisionPunishment + offScreenPunishment + goalNotVisiblePunishment /*+ velocityReward - turnPenalty*/;

    return fitness;
  }


  /*
    Interprets and maps the genes from the genes[] array 
    and assigns them to their appropriate variables.
  */
  void readGenes() {
    int r = (int)mapGene(0, 0, 255);
    int g = (int)mapGene(1, 0, 255);
    int b = (int)mapGene(2, 0, 255);
    col = color(r, g, b);

    accelerationForce = SPEED_MULTIPLIER*mapGene(3, 0.2, 1);
    rotationSpeed =     mapGene(4, 1, PI/8);
    maximumVelocity =   SPEED_MULTIPLIER*mapGene(5, 0.1, 1)*5;
    seed =              (int)mapGene(6, 2, 1000);
    initialDirection = new PVector(mapGene(7, -1, 1), mapGene(8, -1, 1));
    rayLength = (int)mapGene(9, 30, 50);
    noiseLocation = mapGene(10, 0, 300);
    avoidance = (int)mapGene(11, 0, 10);
  }


  /*
    Based on the mutation type, calculates the mutation amount for the creature.
    After that, there is a 50/50 chance that a gene will mutate by that given amount.
    If after mutation a gene has clipped the (0;1) limit, re-maps the gene value in (0;1).
  */
  void mutate(float lastFitness) {
    double mutation = 0;

    switch(MUTATION_TYPE) {
    case "exponential-random":
      mutation = exp(-5*lastFitness)/100 - random(0.0004);
      break;
    case "exponential":
      mutation = exp(-5*lastFitness)/100;
      break;
    case "constant":
      mutation = 0.0004;
      break;
    case "random":
      mutation = random(0.004);
      break;
    case "no":
      mutation = 0;
      break;
    }
    mutationAmount = mutation;

    for (int i = 0; i < genePoolSize; i++) {

      boolean willMutate = random(1) > 0.9; 

      if (willMutate) {
        if (genes[i] > 0.5) {
          genes[i] -= (float)mutation;
        } else {
          genes[i] += (float)mutation;
        }
      }
      if (genes[i]<0)genes[i]=abs(genes[i]);
      if (genes[i]>1)genes[i]=2-genes[i];
    }
  }


  /*
    Determines whether a creature is about to hit a wall. If it is, it calculates 
    the wall side, which is about to be hit. Creates a vector, perpendicular to that side
    facing away from it, with a magninute inversely proportional to the
    distance to that side. Adds that vector to the creature's acceleration.
  */
  void avoidWalls() {
    for(PVector ray : rays()){
      if (wallIsBlocking(PVector.add(location, ray))!=null) {
        
        
        PVector[] collisionLine = wallIsBlocking(PVector.add(location, ray));
        float intersectionAngle = (ray.heading() > 0) ? ray.heading() : TWO_PI+ray.heading();
        PVector vectorOffset = new PVector();
        
        if (collisionLine[0].x == collisionLine[1].x) {
          //For vertical walls
          float dist = dist(location.x, location.y, collisionLine[0].x, location.y);
          float strength = map(dist, rayLength, 0, 0, avoidance*accelerationForce);
          
          if (intersectionAngle < PI/2 || (intersectionAngle >= 3*PI/2 && intersectionAngle <= TWO_PI)) {
            
            //Moving right
            vectorOffset.set(-strength, 0);
            
          } else {
            
            //Moving left
            vectorOffset.set(strength, 0);
            
          }
        } else {
          
          //For horizontal walls
          float dist = dist(location.x, location.y, location.x, collisionLine[0].y);
          float strength = map(dist, rayLength, 0, 0, avoidance*accelerationForce);
          
          if (intersectionAngle >=  PI) {
            
            //Moving up
            vectorOffset.set(0, strength);
            
          } else {
            
            //Moving down
            vectorOffset.set(0, -strength);
            
          }
        }
        
        acceleration.add(vectorOffset);
        break;
      }
    }
  }


  /*
    Checks whether a creature is about to hit a screen boundry. Creates a vector, 
    perpendicular to that boundry facing away from it, with a magninute that is
    inversely proportional to the distance to that boundry. 
    Adds that vector to the creature's acceleration.
  */
  void avoidBounds() {
    float dLeft = dist(location.x, location.y, 0, location.y);
    float dRight = dist(location.x, location.y, width, location.y);
    float dTop = dist(location.x, location.y, location.x, 0);
    float dBottom = dist(location.x, location.y, location.x, height);

    int min = 50;

    boolean headingForCollision = dLeft<=min||dRight<=min||dTop<=min||dBottom<=min;

    if (headingForCollision) {
      float dist1 = min(dLeft, dRight);
      float dist2 = min(dTop, dBottom);
      float dist = min(dist1, dist2);

      float strength = map(dist, min, 0, 0, avoidance*accelerationForce);
      PVector vectorOffset = new PVector();
      if (dist==dLeft) {
        vectorOffset.set(strength, 0);
      } else if (dist==dRight) {
        vectorOffset.set(-strength, 0);
      } else if (dist==dTop) {
        vectorOffset.set(0, strength);
      } else if (dist==dBottom) {
        vectorOffset.set(0, -strength);
      }
      
      acceleration.add(vectorOffset);
    }
  }


  /*
    A vector array, originating from the creatuer's
    position with a fixed radious and count.
  */
  PVector[] rays() {

    int numViewDirections = 8;
    PVector[] directions = new PVector[numViewDirections];

    for (int i = 0; i < numViewDirections; i++) {
      float theta = i * (TWO_PI/numViewDirections);
      float x = sin(theta);
      float y = cos(theta);

      directions[i] = new PVector(x*rayLength, y*rayLength);
    }
    return directions;
  }
  

  /*
    Re-maps the gene value to a new range.
   */
  float mapGene(int gene, float lower, float upper) {
    return map(genes[gene], 0, 1, lower, upper);
  }


  /*
    Checks whether a creature is off-screen.
    If it is, sets the punishment.
  */
  boolean isOffScreen() {
    boolean outX = location.x+8>width || location.x-8<0;
    boolean outY = location.y+8>height || location.y-8<0;
    if (outX || outY) {
      offScreenPunishment = OFF_SCREEN_PUNISHMENT;
    }
    return outX || outY;
  }


  /*
    Checks whether a creature has hit a wall.
  */
  boolean hasCollided(Wall wall, PVector inputLocation) {
    boolean betweenX = inputLocation.x+8>wall.getLocation().x && inputLocation.x-8<wall.getLocation().x+wall.getSize().x;
    boolean betweenY = inputLocation.y+8>wall.getLocation().y && inputLocation.y-8<wall.getLocation().y+wall.getSize().y;
    return betweenX && betweenY;
  }


  /*
    Checks whether the creature is overlapping with any visible creatures and 
    sets the visible flag as false if it does.
  */
  void checkOverlap(){ //<>//
    for(Creature creature : creatures){ //<>//
      if(creature != this){ //<>//
        if(creature.isVisible()){ //<>//
          if(dist(creature.getLocation().x, creature.getLocation().y, location.x, location.y) < 10){ //<>//
            visible = false; //<>//
            return;
          }
        }
      }
    }
    visible = true;
  }


  /*
    Checks whether a creature can "see" the vector "goal". If it can't,
    return's the two points, forming the line that is blocking the creature's
    "vision".
  */
  PVector[] wallIsBlocking(PVector goal) {
    float x1 = goal.x;
    float y1 = goal.y;
    float x2 = location.x;
    float y2 = location.y;

    for (Wall wall : walls) {
      for (int i = 0; i < 4; i++) {
        PVector corner1 = wall.getShape().getVertex(i);
        PVector corner2 = wall.getShape().getVertex((i+1)%4);

        float x3 = corner1.x; 
        float y3 = corner1.y;
        float x4 = corner2.x;   
        float y4 = corner2.y;

        float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
        float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
        if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
          PVector otherCorner1 = wall.getShape().getVertex((i+2)%4);
          PVector otherCorner2 = wall.getShape().getVertex((i+3)%4);
          float distCorner1 = dist(location.x, location.y, corner1.x, corner1.y);
          float distCorner2 = dist(location.x, location.y, corner2.x, corner2.y);
          float distCorner3 = dist(location.x, location.y, otherCorner1.x, otherCorner1.y);
          float distCorner4 =  dist(location.x, location.y, otherCorner2.x, otherCorner2.y);
          float minDist = min(min(distCorner1, distCorner3), min(distCorner2, distCorner4));
          if (minDist == distCorner1 || minDist == distCorner2) {
            PVector[] line = {corner1, corner2};
            return line;
          } else {
            PVector[] closerLine = {otherCorner1, otherCorner2};
            return closerLine;
          }
        }
      }
    }
    return null;
  }


  /*
    Checks if the creature has reached the required fitness value.
    If it has, prints the creature's genes and exits the simulation.
  */
  void check() {
    if (getFitness()>ACCURACY*DISTANCE_REWARD_MAX) {
      
      println("\nFitness: " + getFitness());
      println("Generation: " + generation);
      print("{");
      for (int i = 0; i < genes.length; i++) {
        print(genes[i]);
        if (i<genes.length-1) {
          print(", \n");
        }
      }
      println("};");

      exit();
    }
  }

  double getMutationAmount() {
    return mutationAmount;
  }

  float getAccelerationForce() {
    return accelerationForce;
  }

  float getMaximumVelocity() {
    return maximumVelocity;
  }

  PVector getInitialDirection() {
    return initialDirection;
  }

  float getLastTurn() {
    return lastTurn;
  }

  float getSeed() {
    return seed;
  }

  float[] getGenes() {
    return genes;
  }

  PVector getLocation() {
    return location;
  }

  String getPunishments() {
    return "Walls->" + collisionPunishment + ",\n                        Off-Screen->" + offScreenPunishment + ",\n                        Visibility->" + goalNotVisiblePunishment;
  }

  float getWallPunishment() {
    return collisionPunishment;
  }

  float getOffScreenPunishment() {
    return offScreenPunishment;
  }

  float getGoalPunishment() {
    return goalNotVisiblePunishment;
  }

  float getAvoidance(){
    return avoidance;
  }

  void setCollisionPunishment(float collisionPunishment) {
    this.collisionPunishment = collisionPunishment;
  }

  boolean isVisible() {
    return visible;
  }
}
