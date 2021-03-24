class Wall{
 
  PVector location;
  PVector size;
  
  public Wall(PVector location, PVector size){
    this.location = location;
    this.size = size;
  }
  
  void show(){
    pushStyle();
    fill(100);
    rect(location.x, location.y, size.x, size.y);
    popStyle();
  }
  
  PVector getLocation(){
    return location;
  }
  
  PVector getSize(){
    return size;
  }
  
}
