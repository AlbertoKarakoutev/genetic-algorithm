class Wall{

  PVector location;
  
  PVector vertex1Scaled;
  PVector vertex2Scaled;
  
  PShape wallShape;
  
  public Wall(float x1, float y1, float x2, float y2){
    
    float scaleX = width/WALL_GRID_SIZE;
    float scaleY = height/WALL_GRID_SIZE;
    
    PVector vertex1Scaled = new PVector(x1*scaleX, y1*scaleY);
    PVector vertex2Scaled = new PVector(x2*scaleX + 20, y2*scaleY + 20);
    
    location = vertex1Scaled;
    
    this.vertex1Scaled = vertex1Scaled;
    this.vertex2Scaled = vertex2Scaled;
    
    wallShape = createShape(RECT, vertex1Scaled.x, vertex1Scaled.y, vertex2Scaled.x - vertex1Scaled.x, vertex2Scaled.y - vertex1Scaled.y);
  }
  
  void show(){
    pushStyle();
    wallShape.setFill(color(255, 170));
    shape(wallShape);
    popStyle();
  }

  PVector getVertex1(){
    return vertex1Scaled; 
  }
  
  PVector getVertex2(){
    return vertex2Scaled; 
  }
  
  PShape getShape(){
    return wallShape;
  }
}
