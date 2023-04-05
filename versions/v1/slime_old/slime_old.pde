class Agent{
    float posX, posY, ang;
    Agent(float x, float y, float a){
        posX = x;
        posY = y;
        ang = a;
    }
}

final static int numOfAgents = 100;

Agent[] agents = new Agent[numOfAgents];

void setup(){
   size(500, 500); 
   background(0);
   spawn_centreRandomRotation();
}

void draw(){
   loadPixels();
   trails();
   iterate();
}

void iterate(){
   for(int i = 0; i < numOfAgents; i++){
       //Move forward
       float newX = agents[i].posX + cos(agents[i].ang);
       float newY = agents[i].posY + sin(agents[i].ang);
       while(collision(newX, newY)){
          agents[i].ang = random(360);
          newX = agents[i].posX + cos(agents[i].ang);
          newY = agents[i].posY + sin(agents[i].ang);
       }
       agents[i].posX = newX;
       agents[i].posY = newY;
       
       //Draw Agent
       drawAgent(agents[i]);
   }
}

boolean collision(float newX, float newY){
   //Walls
   if(newX < 0 || newX > width){
     return true;
   }else if(newY < 0 || newY > height){
     return true; 
   }
   return false;
}

void trails(){
    for(int x = 0; x < width; x++){
      for(int y = 0; y < height; y++){
         color c = get(x, y); 
         float r = red(c) - 2;
         float g = green(c) - 2;
         float b = blue(c) - 2;
         if(r < 0) r = 0;
         if(g < 0) g = 0;
         if(b < 0) b = 0;
         set(x, y, color(r, g, b));
      }
    }
}

void drawAgent(Agent a){
  set(int(a.posX), int(a.posY), color(255, 255, 255));
}

void spawn_centreRandomRotation(){
    for(int i = 0; i < numOfAgents; i++){
       agents[i] = new Agent(width/2, height/2, random(360)); 
    }
}
