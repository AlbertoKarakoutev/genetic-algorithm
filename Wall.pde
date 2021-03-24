class Wall{
 
  PVector location;
  PVector size;
  
  PShape wallShape;

  public Wall(PVector location, PVector size){
    this.location = location;
    this.size = size;
    wallShape = createShape(RECT, location.x, location.y, size.x, size.y);
  }
  
  void show(){
    pushStyle();
    shape(wallShape);
    popStyle();
  }
  
  PVector getLocation(){
    return location;
  }
  
  PVector getSize(){
    return size;
  }
  
  PShape getShape(){
    return wallShape;
  }
}
