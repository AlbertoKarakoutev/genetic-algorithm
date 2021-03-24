class Creature {

  PVector location;
  PVector velocity;
  PVector acceleration;

  float[] genes;

  boolean firstFrame = true;

  boolean visible = true;

  static final int genePoolSize = 30;
  int collisionPunishment = 0;
  int offScreenPunishment = 0;

  float accelerationAngle;
  float lastTurn;

  //Genes:
  color col;                //0,1,2
  float accelerationForce;  //3
  float rotationSpeed;      //4
  float maximumVelocity;    //5
  int seed;                 //6
  PVector initialDirection; //7,8
  int accelerationFrequency;//9
  float[] turnSequence;       //10:29

  float mutationAmount;

  public Creature() {

    genes = new float[genePoolSize];

    for (int i = 0; i < genePoolSize; i++) {
      genes[i] = random(1); //<>//
    }

    readGenes();

    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = initialDirection.copy();
  }

  public Creature(float[] genes) {

    this.genes = genes;

    readGenes();

    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = initialDirection.copy();
  }

  public Creature(Creature parent) {
    float lastFitness = parent.getFitness();
    genes = parent.getGenes();
    mutate(lastFitness);
    readGenes();
    location = new PVector(100, height/2);
    velocity = new PVector();
    acceleration = initialDirection.copy();
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
    float fitness = distanceReward + collisionPunishment + offScreenPunishment /*+ velocityReward - turnPenalty*/;
    if (fitness<-1)fitness=-1;
    return map(fitness, -1, 1, 0, 1);
  }

  void readGenes() {
    int r = (int)mapGene(0, 0, 255);
    int g = (int)mapGene(1, 0, 255);
    int b = (int)mapGene(2, 0, 255);
    col = color(r, g, b);

    accelerationForce = speedMultiplier*mapGene(3, 0.2, 1);
    rotationSpeed =     mapGene(4, 1, PI/2);
    maximumVelocity =   speedMultiplier*mapGene(5, 0.1, 1)*5;
    seed =              (int)mapGene(6, 2, 1000);
    initialDirection = new PVector(mapGene(7, -1, 1), mapGene(8, -1, 1));
    accelerationFrequency = (int)mapGene(9, 5, 10);
    turnSequence = new float[20];
    for(int i = 10; i < 10+turnSequence.length;i++){
      turnSequence[i-10] = map(genes[i], 0, 1, -1, 1); 
    }
  }

  void move() {
    stillMoving =  true;

    if (firstFrame) {
      accelerationAngle=initialDirection.heading();
      firstFrame=false;
    }

    noiseSeed(seed);
    float rotationDirection = turnSequence[frameCount%turnSequence.length];
    float thisTurn = 0;
    if(rotationDirection>0){
      thisTurn = rotationSpeed*rotationDirection;
    }else{
      thisTurn = TWO_PI+(rotationSpeed*rotationDirection);
    }
    lastTurn = thisTurn;
    accelerationAngle = thisTurn;


    if (frameCount%accelerationFrequency==0) {
      acceleration.x = accelerationForce * cos(accelerationAngle);
      acceleration.y = accelerationForce * sin(accelerationAngle);
    }

    //velocity.setMag(maximumVelocity);

    velocity.add(acceleration);
    velocity.limit(maximumVelocity);
    //if(PVector.add(velocity, acceleration).mag() < maximumVelocity){
    //  velocity.add(acceleration);
    //}else{
    //  velocity.setMag(maximumVelocity);
    //}

    location.add(velocity);
  }

  void mutate(float lastFitness) {
    float mutation = 0;

    switch(mutationType) {
    case "exponential-random":
      mutation = exp(-5*lastFitness)/2-random(0.15);
      break;
    case "exponential":
      mutation = exp(-5*lastFitness)/2;
      break;
    case "constant":
      mutation = 0.2;
      break;
    case "random":
      mutation = random(0.05, 0.1);
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

  void checkOverlap() {
    //for(Creature creature : creatures){
    //  if(creature.isVisible()){
    //    if(dist(creature.getLocation().x, creature.getLocation().y, location.x, location.y) < 3){
    //      visible = false;
    //      return;
    //    }
    //  }
    //}
    visible = true;
  }


  void check() {
    if (dist(location.x, location.y, direction.x, direction.y)<2) {
      println("Fitness: " + getFitness());
      
      print("{");
      for (Float gene : genes) {
        println(gene + ", ");
      }
      println("}");
      
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

  float getAccelerationFrequency() {
    return accelerationFrequency;
  }

  String getTurnSequenceString(){
    String TSS = "[";
    for(float turn : turnSequence){
      TSS = TSS + ((turn<0)?"L":"R");
    }
    TSS = TSS+"]";
    return TSS;
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
