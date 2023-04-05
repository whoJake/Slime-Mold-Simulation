class Agent{
    float posX, posY, ang;
    Agent(float x, float y, float a){
        posX = x;
        posY = y;
        ang = a;
    }
}

volatile boolean running = true;
PImage colorMap;

final static float circleSpawnRadius = 150;

static color wallColor;
color drawColor = color(220);
color agentColor = color(0, 255, 255);
color bgColor = color(0);

final static int simWidth = 500;
final static int simHeight = 500;

static int strokeSize = 15;
static float evaporateSpeed = 2;
static float diffusionRate = 0.2;
static float sensorOffsetDistance = 10;
static float sensorAngle = 30.1;
static float turnSpeed = 0.5;


static int restartNumOfAgents = 10000;
static int numOfAgents = 10000;

Agent[] agents = new Agent[numOfAgents];

void setup(){
   colorMap = loadImage("colormap.gif");
  
   wallColor = color(255, 255, 254);
   
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
    
    float lerpR = lerpF(blurR, red(curC), 1 - diffusionRate);
    float lerpG = lerpF(blurG, green(curC), 1 - diffusionRate);
    float lerpB = lerpF(blurB, blue(curC), 1 - diffusionRate);
    
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
   spawn();
   for(int i = 0; i < numOfAgents; i++){
      float ang = random(360);
      float dist = random(circleSpawnRadius);
      agents[i] = new Agent(simWidth/2 + cos(ang) * dist, simHeight/2 + sin(ang) * dist, ang + 180);
   }
}

void spawn_centreRandomRotation(){
    spawn();
    for(int i = 0; i < numOfAgents; i++){
       agents[i] = new Agent(simWidth/2, simHeight/2, random(360)); 
    }
}

void spawn_allRandom(){
   spawn();
   for(int i = 0; i < numOfAgents; i++){
      agents[i] = new Agent(random(simWidth-1), random(simHeight-1), random(360)); 
   }
}

void spawn_circle(){
   spawn();
   for(int i = 0; i < numOfAgents; i++){
      float radius = circleSpawnRadius;
      float randomAngle = random(360);
      float maxOffsetX = cos(randomAngle) * radius;
      float maxOffsetY = sin(randomAngle) * radius;
      
      agents[i] = new Agent(maxOffsetX * random(1) + simWidth/2, maxOffsetY * random(1) + simHeight/2, randomAngle);
   }
}

void spawn(){
   bgFill();
   numOfAgents = restartNumOfAgents;
   agents = new Agent[numOfAgents];
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
   boolean title;
   Text(int _x, int _y, String t, boolean _title){
      x = _x;
      y = _y;
      text = t; 
      title = _title;
   }
}

class Slider{
   int x;
   int y;
   int l;
   float startVal;
   float endVal;
   float curVal;
   boolean held = false;
   Slider(int _x, int _y, int _l, float _startVal, float _endVal, float _curVal){
      x = _x;
      y = _y;
      l = _l;
      startVal = _startVal;
      endVal = _endVal;
      curVal = _curVal;
   }
}

final color buttonColor      = color(180);
final color buttonHoverColor = color(210);
final color buttonPressColor = color(150);
final color textColor        = color(255);
Button hoveredButton = null;
Button pressedButton = null;
boolean locked = false;
int lastEvent = 0;

Button[] allButtons = new Button[100];
Text[] allText = new Text[100];
Slider[] allSliders = new Slider[100];

void initSettings(){
   allButtons[0] = new Button(520, 20, 100, 30, "Pause");
   allButtons[1] = new Button(680, 20, 100, 30, "Resume");
   allButtons[2] = new Button(520, 90, 70, 30, "Inwards");
   allButtons[3] = new Button(615, 90, 70, 30, "Point");
   allButtons[4] = new Button(710, 90, 70, 30, "Random");
   allButtons[5] = new Button(615, 420, 70, 30, "Color");
   
   allText[0] = new Text(650, 80, "Respawn Agents", true);
   allText[1] = new Text(650, 170, "Simulation Variables", true);
   
   allText[2] = new Text(520, 200, "Diffusion Rate", false);
   allText[3] = new Text(520, 230, "Evaporate Rate", false);
   allText[4] = new Text(520, 260, "Sensor Offset", false);
   allText[5] = new Text(520, 290, "Sensor Angle", false);
   allText[6] = new Text(520, 320, "Turn Speed", false);
   
   allText[7] = new Text(650, 370, "Number of Agents", true);
   allText[8] = new Text(565, 389, "Only works on restart", false);
   
   allSliders[0] = new Slider(640, 195, 100, 0, 1, diffusionRate);
   allSliders[1] = new Slider(640, 225, 100, 0, 10, evaporateSpeed);
   allSliders[2] = new Slider(640, 255, 100, 2, 50, sensorOffsetDistance);
   allSliders[3] = new Slider(640, 285, 100, 10, 100, sensorAngle);
   allSliders[4] = new Slider(640, 315, 100, 0.15, 2, turnSpeed);
   
   allSliders[5] = new Slider(520, 400, 200, 1000, 50000, numOfAgents);
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

void updateSliders(){
   for(Slider s: allSliders){
      if(s == null) continue;
      if(!mousePressed || mouseButton != LEFT) s.held = false;
      if(s.held){
         float perc = (float(mouseX) - s.x) / s.l;
         if(perc < 0) perc = 0;
         if(perc > 1) perc = 1;
         float newVal = s.startVal + ((s.endVal - s.startVal) * perc);
         newVal = float(nf(newVal, 0, 2));
         s.curVal = newVal;
      }
      else if(mouseX >= s.x - 5 && mouseX <= s.x + s.l + 5 && mouseY >= s.y - 5 && mouseY <= s.y + 5 && mousePressed && mouseButton == LEFT){
        s.held = true;
      }
   }
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

void drawSlider(Slider s){
    stroke(255);
    strokeWeight(4);
    fill(255);
    line(s.x, s.y, s.x + s.l, s.y);
    float percent = (s.curVal - s.startVal) / (s.endVal - s.startVal);
    strokeWeight(2);
    fill(0);
    circle(s.x + (s.l * percent), s.y, 7);
    fill(255);
    textSize(14);
    text("" + s.curVal, s.x + s.l + 15, s.y + 5);
}

void settingsUpdate(){
   drawSettings();
   currentButtonHovered();
   //Button presses
     if(mousePressed && mouseButton == LEFT){
         if(hoveredButton != null){
           pressedButton = hoveredButton;
         }
     }else{
         pressedButton = null; 
    }
   
   if(!locked){
     updateSliders();
     
     //Pause
     if(pressedButton == allButtons[0]){
       pauseSimulation();
     }
     //Resume
     if(pressedButton == allButtons[1]){
        resumeSimulation(); 
     }
     //Inward circle spawn
     if(pressedButton == allButtons[2]){
        spawn_inwardCircle(); 
     }
     //Center point spawn
     if(pressedButton == allButtons[3]){
        spawn_centreRandomRotation(); 
     }
     //All random spawn
     if(pressedButton == allButtons[4]){
        spawn_allRandom(); 
     }
     if(pressedButton == allButtons[5]){
        toggleLock();
     }
     
     for(Slider s: allSliders){
        if(s == null) continue;
        if(s.held){
           //Diffusion rate
           if(s == allSliders[0]){
               diffusionRate = s.curVal;
           }
           if(s == allSliders[1]){
              evaporateSpeed = s.curVal; 
           }
           if(s == allSliders[2]){
              sensorOffsetDistance = s.curVal; 
           }
           if(s == allSliders[3]){
              sensorAngle = s.curVal; 
           }
           if(s == allSliders[4]){
              turnSpeed = s.curVal; 
           }
           if(s == allSliders[5]){
              restartNumOfAgents = int(s.curVal); 
           }
        }
     }
   }else{
      if(mousePressed && mouseButton == LEFT){
         if(pressedButton == allButtons[5]){
            toggleLock(); 
         }else{
            pickColor(); 
         }
      }
   }
}

void drawSettings(){
   fill(0);
   strokeWeight(0);
   stroke(0);
   rect(503, 0, 800, 800);
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
      if(t.title){
         textAlign(CENTER);
         textSize(20);
      }else{
         textAlign(LEFT);
         textSize(16);
      }
      fill(textColor);
      text(t.text, t.x, t.y);
   }
   //Sliders
   for(Slider s: allSliders){
      if(s == null) continue;
      drawSlider(s);
   }
   
   if(locked){
      image(colorMap, 528, 221);
   }
}

void pickColor(){
    if(mouseX < 502) return;
    color newColor = get(mouseX, mouseY);
    if(!isSameColor(newColor, buttonColor) && !isSameColor(newColor, buttonHoverColor) && !isSameColor(newColor, buttonPressColor)){
       agentColor = newColor; 
    }
}

void toggleLock(){
    int c = millis();
    if(c - lastEvent > 200){
       lastEvent = c;
       locked = !locked;
    }
}

void pauseSimulation(){
   if(running) running = !running; 
}

void resumeSimulation(){
   if(!running) running = !running; 
}
