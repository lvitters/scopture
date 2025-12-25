class ProjectionWindow {
  // Window Properties (Direct window layout)
  float x, y;
  float radius;
  
  // Control Mode
  // 0 = Manual
  // 1 = Timed (BPM)
  // 2 = Noise
  int controlMode = 0;
  
  // --- PROPERTIES ---
  
  // 1. Content Position (Offset from center)
  float contentX = 0, contentY = 0;
  float tContentX = 0, tContentY = 0; // Target for lerping
  
  // 2. Size
  float shapeSize;
  float tShapeSize;
  
  // 3. Rotation
  float rotation = 0;
  float rotationSpeed = 0;
  float tRotationSpeed = 0; // Target speed
  
  // 4. Style (Fill vs Stroke)
  boolean isFilled = true;
  // If timed/noise, this might flip automatically. 
  // For manual, user sets it.
  
  // 5. Color
  int cColor = color(0, 0, 100); // Current color (HSB)
  int tColor = color(0, 0, 100); // Target color
  
  // 6. Stroke Weight (Fixed or variable? Let's make it variable)
  float strokeWeightVal = 2;
  float tStrokeWeightVal = 2;
  
  // 7. Automation Scales
  float autoPosScale = 1.0;
  float autoSizeScale = 1.0;

  // --- INTERNALS ---
  
  MorphShape shape;
  int id;
  float seed; // Random seed for noise offsets
  float lerpSpeed = 0.1;
  
  // Masking
  PGraphics pg;
  PGraphics pgMask;
  
  // Interaction
  boolean isDragging = false;
  boolean isResizing = false;
  boolean isSelected = false;
  float dragOffsetX, dragOffsetY;
  
  ProjectionWindow(int id, float x, float y, float radius) {
    this.id = id;
    this.x = x; this.y = y;
    this.radius = radius;
    
    // Defaults
    this.shapeSize = radius * 1.5;
    this.tShapeSize = shapeSize;
    
    this.shape = new MorphShape(shapeSize);
    this.seed = random(10000);
    
    checkBuffers();
  }
  
  void checkBuffers() {
    int requiredSize = (int)(radius * 2 + 20);
    if (pg == null || pg.width != requiredSize) {
      pg = createGraphics(requiredSize, requiredSize);
      pgMask = createGraphics(requiredSize, requiredSize);
      
      pgMask.beginDraw();
      pgMask.background(0);
      pgMask.fill(255);
      pgMask.noStroke();
      pgMask.ellipse(requiredSize/2, requiredSize/2, radius * 2, radius * 2);
      pgMask.endDraw();
    }
  }
  
  // Main Update Loop
  // time: global time for noise
  // noiseSpeed: global speed for noise walking
  // beatHappened: true if a beat occurred this frame
  // uniform: whether automation should be uniform
  void update(float time, float noiseSpeed, boolean beatHappened, boolean uniform) {
    
    // --- MODE LOGIC ---
    
    if (controlMode == 1) { 
      // --- TIMED EVENTS ---
      if (beatHappened) {
        triggerRandomState();
      }
      lerpProperties();
      
    } else if (controlMode == 2) {
      // --- NOISE ---
      applyNoise(time, noiseSpeed, uniform);
      
    } else {
      // --- MANUAL ---
      lerpProperties();
    }
    
    // --- CONTINUOUS ROTATION ---
    rotation += rotationSpeed;
    
    // --- SHAPE UPDATE ---
    shape.currentSize = shapeSize * autoSizeScale;
    shape.rotation = rotation; 
    
    // Color & Style
    if (isFilled) {
      shape.fillColor = cColor;
      shape.strokeColor = color(0, 0); 
      shape.strokeWeightVal = 0;
    } else {
      shape.fillColor = color(0, 0);
      shape.strokeColor = cColor;
      shape.strokeWeightVal = strokeWeightVal;
    }
    
    // Recalculate vertices if size/type changed
    shape.calculateTargetVertices(shape.currentShapeType);
    shape.update(); 
  }
  
  void lerpProperties() {
    contentX = lerp(contentX, tContentX, lerpSpeed);
    contentY = lerp(contentY, tContentY, lerpSpeed);
    shapeSize = lerp(shapeSize, tShapeSize, lerpSpeed);
    rotationSpeed = lerp(rotationSpeed, tRotationSpeed, lerpSpeed);
    strokeWeightVal = lerp(strokeWeightVal, tStrokeWeightVal, lerpSpeed);
    cColor = lerpColor(cColor, tColor, lerpSpeed);
  }
  
  void triggerRandomState() {
    float limit = radius * 0.5;
    tContentX = random(-limit, limit);
    tContentY = random(-limit, limit);
    tShapeSize = random(radius * 0.5, radius * 2.5);
    tRotationSpeed = random(-0.1, 0.1);
    tColor = color(random(360), random(50, 100), random(50, 100));
    isFilled = random(1) > 0.5;
    tStrokeWeightVal = random(1, 10);
    shape.setTargetShape(int(random(6)));
  }
  
  // Called when Uniform automation triggers a beat
  void setDirectTargetProperties(float tx, float ty, float tsz, float trot, int tcol, boolean fill, float tstr, int shapeType) {
    // tx, ty, tsz are proportional (0-1 range approx or normalized). 
    // We map them to this window's radius.
    float limit = radius * 0.5;
    tContentX = map(tx, -1, 1, -limit, limit);
    tContentY = map(ty, -1, 1, -limit, limit);
    tShapeSize = map(tsz, 0, 1, radius * 0.5, radius * 2.5);
    
    tRotationSpeed = trot;
    tColor = tcol;
    isFilled = fill;
    tStrokeWeightVal = tstr;
    shape.setTargetShape(shapeType);
  }
  
  void applyNoise(float time, float speed, boolean uniform) {
    float effectiveSeed = uniform ? 0 : seed;
    float t = time * speed + effectiveSeed;
    
    // Use slower time for physical movement (Position, Size, Rot)
    float tPhys = t * 0.2;
    
    // Pos (Normalized)
    float limit = radius * 0.5;
    contentX = map(noise(tPhys), 0, 1, -limit, limit);
    contentY = map(noise(tPhys + 1000), 0, 1, -limit, limit);
    
    // Size (Normalized)
    shapeSize = map(noise(tPhys + 2000), 0, 1, radius * 0.5, radius * 2.5);
    
    // Rot Speed
    rotationSpeed = map(noise(tPhys + 3000), 0, 1, -0.1, 0.1);
    
    // Color (Drift Hue) - Keep faster/normal speed
    float h = map(noise(t + 4000), 0, 1, 0, 360);
    float s = map(noise(t + 5000), 0, 1, 50, 100);
    float b = map(noise(t + 6000), 0, 1, 50, 100);
    cColor = color(h, s, b);
    
    // Style
    isFilled = noise(t * 0.1 + 7000) > 0.5;
    
    strokeWeightVal = map(noise(t + 8000), 0, 1, 1, 10);
  }

  void draw(PGraphics context, boolean drawDecorations) {
    PGraphics target = (context == null) ? g : context;

    pg.beginDraw();
    pg.background(0, 0); 
    pg.pushMatrix();
    
    // Apply Position Scale Here
    pg.translate(pg.width/2 + contentX * autoPosScale, pg.height/2 + contentY * autoPosScale);
    
    shape.draw(pg);
    pg.popMatrix();
    pg.endDraw();
    
    pg.mask(pgMask);
    
    target.pushMatrix();
    target.translate(x, y);
    target.imageMode(CENTER);
    target.image(pg, 0, 0);
    
    if (drawDecorations) {
      target.noFill();
      if (isSelected) {
        target.stroke(0, 0, 100); // White in HSB
        target.strokeWeight(3);
      } else {
        target.stroke(0, 0, 40); // Grey
        target.strokeWeight(1);
      }
      target.ellipse(0, 0, radius * 2, radius * 2);
    }
    
    target.popMatrix();
  }
  
  // Interaction
  boolean contains(float px, float py) { return dist(px, py, x, y) < radius; }
  boolean onEdge(float px, float py) {
    float d = dist(px, py, x, y);
    return d > radius - 10 && d < radius + 10;
  }
  void mousePressed(float px, float py) {
    if (onEdge(px, py)) { isResizing = true; }
    else if (contains(px, py)) { isDragging = true; dragOffsetX = x - px; dragOffsetY = y - py; }
  }
  void mouseDragged(float px, float py) {
    if (isResizing) { radius = max(20, dist(px, py, x, y)); }
    else if (isDragging) { x = px + dragOffsetX; y = py + dragOffsetY; }
  }
  void mouseReleased() { isDragging = false; isResizing = false; }
  
  // Setters
  void setManualSize(float s) { tShapeSize = s; }
  void setManualRotSpeed(float s) { tRotationSpeed = s; }
  void setManualColor(int c) { tColor = c; }
  void setManualFilled(boolean f) { isFilled = f; }
  void setManualContentPos(float ox, float oy) { tContentX = ox; tContentY = oy; }
  void setManualStrokeWeight(float w) { tStrokeWeightVal = w; }
  
  void setControlMode(int m) { controlMode = m; }
  void setShapeType(int type) { shape.setTargetShape(type); }
  
  void setAutoPosScale(float s) { autoPosScale = s; }
  void setAutoSizeScale(float s) { autoSizeScale = s; }
}