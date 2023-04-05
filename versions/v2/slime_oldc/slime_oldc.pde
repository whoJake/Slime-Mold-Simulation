class Agent{
    float posX, posY, ang;
    Agent(float x, float y, float a){
        posX = x;
        posY = y;
        ang = a;
    }
}

final static float evaporateSpeed = 0.5;
final static float diffusionRate = 0.7;
final static int trailDissapateRate = 1;
final static int numOfAgents = 250;

Agent[] agents = new Agent[numOfAgents];

void setup(){
   size(320, 180); 
   background(0);
   spawn_centreRandomRotation();
}

void draw(){
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
         float r = red(c) - trailDissapateRate;
         float g = green(c) - trailDissapateRate;
         float b = blue(c) - trailDissapateRate;
         if(r < 0) r = 0;
         if(g < 0) g = 0;
         if(b < 0) b = 0;
         set(x, y, color(r, g, b));
         spread(x, y);
      }
    }
}

void spread(int x, int y){
    float sumR = 0;
    float sumG = 0;
    float sumB = 0;
    color curC = get(x, y);
  
    for(int offsetX = -1; offsetX <= 1; offsetX++){
       for(int offsetY = -1; offsetY <= 1; offsetY++){
           int sampleX = x + offsetX;
           int sampleY = y + offsetY;
           
           if(sampleX >= 0 && sampleX < width && sampleY >= 0 && sampleY < height){
              color c = get(sampleX, sampleY);
              sumR += red(c);
              sumG += green(c);
              sumB += blue(c);
           }
       }
    }
    
    float blurR = sumR/9;
    float blurG = sumG/9;
    float blurB = sumB/9;
    
    float lerpR = lerpF(blurR, red(curC), diffusionRate);
    float lerpG = lerpF(blurG, green(curC), diffusionRate);
    float lerpB = lerpF(blurB, blue(curC), diffusionRate);
    
    float newR = lerpR - evaporateSpeed;
    float newG = lerpG - evaporateSpeed;
    float newB = lerpB - evaporateSpeed;
    if(newR < 0) newR = 0;
    if(newG < 0) newG = 0;
    if(newB < 0) newB = 0;
    
    set(x, y, color(newR, newG, newB));
  
}

float lerpF(float start, float end, float interp){
   return start + ((end-start) * interp);
}

void drawAgent(Agent a){
  set(int(a.posX), int(a.posY), color(255, 255, 255));
}

void spawn_centreRandomRotation(){
    for(int i = 0; i < numOfAgents; i++){
       agents[i] = new Agent(width/2, height/2, random(360)); 
    }
}
