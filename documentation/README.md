# Genetic Algorithm

A path-finding optimisation algorithm, based on evolutionary principals such as inheritance and mutation, intended to eneble the navigation of subjects through a maze.

## Introduction

The algorithm is coded in Processing, a _Java_ based graphically-focused programming environment.
It is initialized with a population of fixed size of **Creatures** - the main path-finding objects. After the initialization, 
the Creature objects start navigating through the set maze and attempt to reach a pre-determined destination. Each generation is started after a specified time has passed and/or 
all the Creatures are unable to move.

## Algorithm parameters
```java
static final boolean SOLVED
static final float ACCURACY
static final int POPULATION_SIZE
static final String MUTATION_TYPE *
static final float WALL_PUNISHMENT
static final float SPEED_MULTIPLIER
static final int TIME_PER_GENERATION
static final float DISTANCE_REWARD_MAX **
static final float OFF_SCREEN_PUNISHMENT
static final float GOAL_NOT_VISIBLE_PUNISHMENT
```
###### \* exponential/exponential-random/random/constant/no
###### \*\* _|WALL_PUNISHMENT - OFF_SCREEN_PUNISHMENT - GOAL_NOT_VISIBLE_PUNISHMENT| + 1_

## Creature Initialization
  ```java
  Creature()
  ```
* ### Generation == 0  
  A creature object is created with a set of genes (a _float[]_ with a set length and value ranges: **[0; 1]**) which are selected randomly. The genes are interpreted and assigned to it's "qualities". 
  The creature is created at a fixed point and with acceleration and velocity vectors of 0.
* ### Generation > 0
  A creature object is created with a set of genes. The genes are directly copied from it's parent creature. They are then mutated by a specified amount. After that, they are interpreted and assigned as well.  

## Creature Display
  ```java
  void show()
  ```
  The creature is displayed as a small ~8px isosceles triangle, pointing in the direction of its movement. If it is the top-performer of it's generation, it is circled by a halo, marking it as such.
 
## Creature Movement
  ```java
  void move()
  ```
  Initializes the acceleration with the ***initialDirection*** property. After that, a rotation direction is generated, based on a seed, which is set for a Perlin noise function, and offset by a specific amount.
  The rotation is applied in the specified direction and added ot the acceleration using polar coordinates. The creature than calculates any collisions with walls and/or screen boundries and aggregates the acceleration into the velocity, which is limited
  to a maximum value. The velocity is then added to the location.
  
## Creature Fitness Function
  ```java
  float getFitness()
  ```
  The fitness function is calculated based on penalties and rewards for the creature. As of this time, there are _three_ penalties that can be applied:
  * A wall collision penalty for hitting a maze wall
  * An out-of-bounds penalty for trying to go out of the screen
  * An invisible goal penalty, for when the creature does not have a clear view of its destination vector.  
  
The penalties are given specific weights, depending on their importance. The reward is based on the creature's distance from the destination and it's maximum values depend on the sum of the penalties.  

## Creature Genes Interpretation
  ```java
  void readGenes()
  ```
  All the values from the ***genes*** array are re-mapped to the appropriate values for each of the creature's variables. The genes are assigned as follows:
  * 0-2 - the three colors of the creature
  * 3 - the acceleration force that the creature can exibit
  * 4 - the rotation speed (angle, by which the creature can turn)
  * 5 - the maximum velocity that the creature's speed is limited to
  * 6 - the seed for the Perlin noise function
  * 7-8 - the acceleration initialization vector, which whanges the start direction
  * 9 - the length of the vector, which checks for impending collisions
  * 10 - the initial value of the offset for the noise function

## Creature Mutation
  ```java
  void readGenes(float lastFitness)
  ```
  The creature mutation consists of looping over all it's genes, and mutating a gene 50% of the time. Based on the ***MUTATION_TYPE***, the creatures have five ways of mutating their genes:  
  * exponential-random - The mutation amount is reduced the closer the creatures get to their destination. Based on the _lastFitness_ parameter, which is the best fitness value of the previous generation, 
  the creature mutation is calculated. Additionally, a small random offset is aggregated to ensure a more efficient rotation schematic.
  * exponential - similar to the _exponential-random_, but without the additional ranom offset.
  * constant - a constant value of mutationis applied
  * random - a value between 0 and a small maximum amount is applied as a mutation
  * no - (_testing_) No mutation value is applied.

After applying all the mutations, the genes are checked for low or high capping and reduced to the approptiate range of **[0; 1]**
  
## Creature Obstacle Avoiding
```java
void avoidWalls()
```
Based on the vector in front of the creasture, it checks whether it is visible and so determines if it will hit a wall. After that, the wall type is found by comparing it's two 
corners (_horizontal/vertical_). A vector is created with a magnitude, depending of the proximity of the creature to the wall. That vector is pointed in the opposite direction and added to the creature's acceleration.  
  
    
```java
void avoidBounds()
```
The creature checks it's proximity to the outside screen boundries. If it is about to collide, a vector similar to the one in _avoidWalls()_ is created and added to the acceleration.
  
  
```java
PVector wallIsBlocking(PVector goal)
```
Based on a line-line intersection calculation, the function determines whether the creature can see the _goal_ vector. If it can't,
the function returns the two vectors, describing the line that is obstructing the creature's vision.
  
## Winning Conditions  
```java
void check()
```
If a creature is within a threshold distance of the goal, the simulation ends and the creature's **solution genes** are printed out on the console.
  
## Solution
When the solution genes have been set, the user can flag the **SOLVED** parameter as true, and view only the solution creature for the maze. 
  
  
  
  
  
  
  
  
  
