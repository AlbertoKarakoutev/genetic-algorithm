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
  color col;                //0,1,2
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

  float getFitness() {
    float d = dist(location.x, location.y, direction.x, direction.y);
    float dTL = dist(0, 0, direction.x, direction.y);
    float dTR = dist(width, 0, direction.x, direction.y);
    float dBR = dist(width, height, direction.x, direction.y);
    float dBL = dist(0, height, direction.x, direction.y);
    float dMax = max(max(dTL, dTR), max(dBL, dBR));
    float distanceReward = map(d, dMax, 0, 0, 1);          //Max=1
    float velocityReward = (velocity.mag()!=0 || maximumVelocity!=0) ? velocity.mag()/maximumVelocity : 0; //Max=1
    checkVisibleGoal();
    float fitness = distanceReward + collisionPunishment + offScreenPunishment + goalNotVisiblePunishment /*+ velocityReward - turnPenalty*/;
    //float fitnessMapped = map(fitness, -1, 1, 0, 1);
    return fitness;
  }

  void readGenes() {
    int r = (int)mapGene(0, 0, 255);
    int g = (int)mapGene(1, 0, 255);
    int b = (int)mapGene(2, 0, 255);
    col = color(r, g, b);

    accelerationForce = SPEED_MULTIPLIER*mapGene(3, 0.2, 1);
    rotationSpeed =     mapGene(4, 1, PI/2);
    maximumVelocity =   SPEED_MULTIPLIER*mapGene(5, 0.1, 1)*5;
    seed =              (int)mapGene(6, 2, 1000);
    initialDirection = new PVector(mapGene(7, -1, 1), mapGene(8, -1, 1));
    noiseOffset = (int)mapGene(9, 0, 10000);
  }

  void move() {
    stillMoving =  true;
    if (firstFrame) {
      statringFrameCount = frameCount;
      //acceleration.rotate(initialDirection.heading());
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

  void mutate(float lastFitness) {
    float mutation = 0;

    switch(MUTATION_TYPE) {
    case "exponential-random":
      mutation = exp(-5*lastFitness)/2 - random(exp(-5*lastFitness)/5);
      break;
    case "exponential":
      mutation = exp(-5*lastFitness)/2;
      break;
    case "constant":
      mutation = 0.2;
      break;
    case "random":
      mutation = random(0.0001);
      break;
    case "no":
      mutation = 0;
      break;
    }
    mutationAmount = mutation;

    for (int i = 0; i < genePoolSize; i++) {

      //boolean willMutate = random(1) > 0.5; 

      //if (willMutate) {
      if (genes[i] > 0.5) {
        genes[i] -= mutation;
      } else {
        genes[i] += mutation;
      }
      //}
      if (genes[i]<0)genes[i]=abs(genes[i]);
      if (genes[i]>1)genes[i]=2-genes[i];
    }
  }

  void show() {

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

  float mapGene(int gene, float lower, float upper) {
    return map(genes[gene], 0, 1, lower, upper);
  }

  boolean isOffScreen() {
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

  boolean hasCollided(Wall wall) {
    boolean betweenX = location.x+8>wall.getLocation().x && location.x-8<wall.getLocation().x+wall.getSize().x;
    boolean betweenY = location.y+8>wall.getLocation().y && location.y-8<wall.getLocation().y+wall.getSize().y;
    if (betweenX && betweenY) {
      collisionPunishment = -1;
    }
    return betweenX && betweenY;
  }

  void checkVisibleGoal(){
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
          goalNotVisiblePunishment=-3;
          return;
        }
      }
    }
  }

  void check() {
    if (getFitness()>0.997) {
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

  float getMutationAmount() {
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

  float getNoiseOffset() {
    return noiseOffset;
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

  boolean isVisible() {
    return visible;
  }
}
