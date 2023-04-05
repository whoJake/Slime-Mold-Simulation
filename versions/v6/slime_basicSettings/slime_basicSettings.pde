class Agent{
    float posX, posY, ang;
    Agent(float x, float y, float a){
        posX = x;
        posY = y;
        ang = a;
    }
}

volatile boolean running = true;

final static float circleSpawnRadius = 150;

static color wallColor;
color drawColor = color(220);
color agentColor = color(0, 255, 255);
color bgColor = color(0);

final static int simWidth = 500;
final static int simHeight = 500;

final static int strokeSize = 15;
final static float evaporateSpeed = 2;
final static float diffusionRate = 0.8;
final static float sensorOffsetDistance = 10;
final static float sensorAngle = 30.1;
final static float turnSpeed = 0.5;
final static int numOfAgents = 10000;

Agent[] agents = new Agent[numOfAgents];

void setup(){
  
   wallColor = color(255, 255, 255);
   
   size(800, 500); 
   background(0);
   
   //Boundry
   stroke(255);
   strokeWeight(3);
   line(501, 0, 501, 500);
   
   //spawn_centreRandomRotation();
   //spawn_allRandom();
   //spawn_circle();
   spawn_inwardCircle();
   
   initSettings();
   
}

void draw(){
   settingsUpdate();
   checkMouse();
   if(running) iterate();
   
   //Draw Agents
   for(Agent a: agents){
       drawAgent(a); 
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
   }
}

boolean collision(float newX, float newY){
   //Walls
   if(newX < 0 || newX > simWidth){
     return true;
   }else if(newY < 0 || newY > simHeight){
     return true; 
   }
   else if(get(int(newX), int(newY)) == wallColor){
      return true;
   }
   return false;
}

void trails(){
    for(int x = 0; x < simWidth; x++){
      for(int y = 0; y < simHeight; y++){
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
           
           if(sampleX >= 0 && sampleX < simWidth && sampleY >= 0 && sampleY < simHeight){
              color c = get(sampleX, sampleY);
              if(isSameColor(c, wallColor)) continue;
              if(isSameColor(c, drawColor)) continue;
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
           if(samplePosX > simWidth-1) samplePosX = simWidth-1;
           if(samplePosY < 0) samplePosY = 0;
           if(samplePosY > simHeight-1) samplePosY = simHeight-1;
           
           color sample = get(samplePosX, samplePosY);
           if(isSameColor(sample, wallColor)){
              sensorSum -= 30000;
              continue;
           }
           if(isSameColor(sample, drawColor)){
              sensorSum += 30000;
              continue;
           }
           
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
       a.posX = random(simWidth-1);
       a.posY = random(simHeight-1);
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
   strokeWeight(strokeSize);
   if(mousePressed && mouseButton == LEFT && mouseX < simWidth - strokeSize && mouseY < simHeight - strokeSize){
      stroke(drawColor);
      fill(drawColor);
      circle(mouseX, mouseY, strokeSize); 
   }
   if(mousePressed && mouseButton == RIGHT && mouseX < simWidth - strokeSize && mouseY < simHeight - strokeSize){
      stroke(0);
      fill(0);
      line(mouseX, mouseY, pmouseX, pmouseY); 
   }
}

//Linear Interpolation
float lerpF(float start, float end, float interp){
   return start + ((end-start) * interp);
}

void drawAgent(Agent a){
  set(int(a.posX), int(a.posY), agentColor);
}

void bgFill(){
   stroke(bgColor);
   fill(bgColor);
   stroke(0);
   rect(0, 0, simWidth, simHeight);
}

//Spawn Agent Options
void spawn_inwardCircle(){
   bgFill();
   for(int i = 0; i < numOfAgents; i++){
      float ang = random(360);
      float dist = random(circleSpawnRadius);
      agents[i] = new Agent(simWidth/2 + cos(ang) * dist, simHeight/2 + sin(ang) * dist, ang + 180);
   }
}

void spawn_centreRandomRotation(){
    bgFill();
    for(int i = 0; i < numOfAgents; i++){
       agents[i] = new Agent(simWidth/2, simHeight/2, random(360)); 
    }
}

void spawn_allRandom(){
   bgFill();
   for(int i = 0; i < numOfAgents; i++){
      agents[i] = new Agent(random(simWidth-1), random(simHeight-1), random(360)); 
   }
}

void spawn_circle(){
   bgFill();
   for(int i = 0; i < numOfAgents; i++){
      float radius = circleSpawnRadius;
      float randomAngle = random(360);
      float maxOffsetX = cos(randomAngle) * radius;
      float maxOffsetY = sin(randomAngle) * radius;
      
      agents[i] = new Agent(maxOffsetX * random(1) + simWidth/2, maxOffsetY * random(1) + simHeight/2, randomAngle);
   }
}

//Settings
class Button{
    int x;
    int y;
    int bWidth;
    int bHeight;
    String text;
    Button(int _x, int _y, int w, int h, String t){
        x = _x;
        y = _y;
        bWidth = w;
        bHeight = h;
        text = t;
    }
}

class Text{
   int x;
   int y;
   String text;
   Text(int _x, int _y, String t){
      x = _x;
      y = _y;
      text = t; 
   }
}

final color buttonColor      = color(180);
final color buttonHoverColor = color(210);
final color buttonPressColor = color(150);
final color textColor        = color(255);
final int   textWeight       = 20;
Button hoveredButton = null;
Button pressedButton = null;

Button[] allButtons = new Button[100];
Text[] allText = new Text[100];

void initSettings(){
   allButtons[0] = new Button(520, 20, 100, 30, "Pause");
   allButtons[1] = new Button(680, 20, 100, 30, "Resume");
   allButtons[2] = new Button(520, 90, 70, 30, "Inwards");
   allButtons[3] = new Button(615, 90, 70, 30, "Point");
   allButtons[4] = new Button(710, 90, 70, 30, "Random");
   
   allText[0] = new Text(650, 80, "Respawn Agents");
}

//Returns null for no button hovered
void currentButtonHovered(){
    for(Button b: allButtons){
        if(b == null) continue;
        if(mouseX >= b.x && mouseX <= b.x + b.bWidth && mouseY >= b.y && mouseY <= b.y + b.bHeight){
          hoveredButton = b;
          return;
        }
    }
    hoveredButton = null;
}

void drawButton(Button b, color c){
    stroke(255);
    strokeWeight(1);
    fill(c);
    rect(b.x, b.y, b.bWidth, b.bHeight);
    fill(0);
    textSize(16);
    textAlign(CENTER);
    text(b.text, b.x + (b.bWidth/2), b.y + (b.bHeight/2) + 6);
}



void settingsUpdate(){
   currentButtonHovered();
   drawSettings();
   
   //Button presses
   if(mousePressed && mouseButton == LEFT && hoveredButton != null){
       pressedButton = hoveredButton;
   }else{
       pressedButton = null; 
   }
   
   //Pause
   if(pressedButton == allButtons[0]){
     pauseSimulation();
   }
   if(pressedButton == allButtons[1]){
      resumeSimulation(); 
   }
   if(pressedButton == allButtons[2]){
      spawn_inwardCircle(); 
   }
   if(pressedButton == allButtons[3]){
      spawn_centreRandomRotation(); 
   }
   if(pressedButton == allButtons[4]){
      spawn_allRandom(); 
   }
   
}

void drawSettings(){
   //Buttons
   for(Button b: allButtons){
      if(b == null) continue;
      if(b == pressedButton) drawButton(b, buttonPressColor);
      else if(b == hoveredButton) drawButton(b, buttonHoverColor);
      else drawButton(b, buttonColor);
   }
   //Text
   for(Text t: allText){
      if(t == null) continue;
      textAlign(CENTER);
      fill(textColor);
      textSize(textWeight);
      text(t.text, t.x, t.y);
   }
}

void pauseSimulation(){
   if(running) running = !running; 
}

void resumeSimulation(){
   if(!running) running = !running; 
}
