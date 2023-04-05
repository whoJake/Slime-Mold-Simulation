class Agent{
    float posX, posY, ang;
    Agent(float x, float y, float a){
        posX = x;
        posY = y;
        ang = a;
    }
}

volatile boolean running = false;

static color wallColor;

final static int strokeSize = 8;
final static float evaporateSpeed = 3;
final static float diffusionRate = 0.75;
final static float sensorOffsetDistance = 10;
final static float sensorAngle = 27;
final static float turnSpeed = 1;
final static int numOfAgents = 10000;

Agent[] agents = new Agent[numOfAgents];

void setup(){
   size(450, 450); 
   wallColor = color(255, 255, 255);
   background(0);
   spawn_centreRandomRotation();
   //spawn_allRandom();
   //spawn_circle();
}

void draw(){
   checkMouse();
   if(running) iterate();
}

void keyPressed(){
   if(key == CODED){
      if(keyCode == UP){
          if(!running) running = true;
      }
   }
}

void iterate(){
   trails();
   
   for(int i = 0; i < numOfAgents; i++){
       //Check for mouse drawn over them
       checkTrapped(agents[i]);
     
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
       
       //Sensory Movement
       float weightF = sense(agents[i], 0);
       float weightFL = sense(agents[i], -sensorAngle);
       float weightFR = sense(agents[i], sensorAngle);
       
       float randSteerStrength = random(1);
       
       if(weightF > weightFL && weightF > weightFR){
           agents[i].ang += 0;
       }
       else if(weightF < weightFL && weightF < weightFR){
           agents[i].ang += (randSteerStrength - 0.5) * 2 * turnSpeed;
       }
       else if(weightFR > weightFL){
           agents[i].ang -= randSteerStrength * turnSpeed;
       }
       else if(weightFL > weightFR){
           agents[i].ang += randSteerStrength * turnSpeed;
       }
       
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
   else if(get(int(newX), int(newY)) == wallColor){
      return true;
   }
   return false;
}

void trails(){
    for(int x = 0; x < width; x++){
      for(int y = 0; y < height; y++){
         spread(x, y);
      }
    }
}

void spread(int x, int y){
    color centre = get(x, y);
    if(isSameColor(centre, wallColor)) return;
  
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
              if(isSameColor(c, wallColor)) continue;
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
    
    //Replacement for trails
    float newR = lerpR - evaporateSpeed;
    float newG = lerpG - evaporateSpeed;
    float newB = lerpB - evaporateSpeed;
    if(newR < 0) newR = 0;
    if(newG < 0) newG = 0;
    if(newB < 0) newB = 0;
    
    set(x, y, color(newR, newG, newB));
  
}

float sense(Agent a, float sensorOffset){
    float sensorAngle = a.ang + sensorOffset;
    float sensDirX = cos(sensorAngle);
    float sensDirY = sin(sensorAngle);
    
    int sensorCentreX = int(a.posX + sensDirX * sensorOffsetDistance);
    int sensorCentreY = int(a.posY + sensDirY * sensorOffsetDistance);
    
    float sensorSum = 0;
    for(int offsetX = -1; offsetX <= 1; offsetX++){
       for(int offsetY = -1; offsetY <= 1; offsetY++){
           int samplePosX = sensorCentreX + offsetX;
           int samplePosY = sensorCentreY + offsetY;
           if(samplePosX < 0) samplePosX = 0;
           if(samplePosX > width-1) samplePosX = width-1;
           if(samplePosY < 0) samplePosY = 0;
           if(samplePosY > height-1) samplePosY = height-1;
           
           color sample = get(samplePosX, samplePosY);
           if(isSameColor(sample, wallColor)) continue;
           
           sensorSum += red(sample) + blue(sample) + green(sample);
       }
    }
    return sensorSum;
}

void checkTrapped(Agent a){
    int curX = int(a.posX);
    int curY = int(a.posY);
    color c = get(curX, curY);
    
    if(isSameColor(c, wallColor)){
       a.posX = random(width-1);
       a.posY = random(height-1);
       checkTrapped(a);
    }
}

boolean isSameColor(color a, color b){
   float aR = red(a);
   float aG = green(a);
   float aB = blue(a);
   float bR = red(b);
   float bG = green(b);
   float bB = blue(b);
   if(aR == bR && aG == bG && aB == bB) return true;
   return false;
}

void checkMouse(){
   stroke(wallColor);
   strokeWeight(strokeSize);
   if(mousePressed == true){
      line(mouseX, mouseY, pmouseX, pmouseY); 
   }
}

float lerpF(float start, float end, float interp){
   return start + ((end-start) * interp);
}

void drawAgent(Agent a){
  set(int(a.posX), int(a.posY), color(255, 0, 255));
}

void spawn_centreRandomRotation(){
    for(int i = 0; i < numOfAgents; i++){
       agents[i] = new Agent(width/2, height/2, random(360)); 
    }
}

void spawn_allRandom(){
   for(int i = 0; i < numOfAgents; i++){
      agents[i] = new Agent(random(width-1), random(height-1), random(360)); 
   }
}

void spawn_circle(){
   for(int i = 0; i < numOfAgents; i++){
      float radius = 100;
      float randomAngle = random(360);
      float maxOffsetX = cos(randomAngle) * radius;
      float maxOffsetY = sin(randomAngle) * radius;
      
      agents[i] = new Agent(maxOffsetX * random(1) + width/2, maxOffsetY * random(1) + height/2, randomAngle);
   }
}
