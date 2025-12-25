class ProjectionWindow {
  // Window Properties (Direct control)
  float x, y;
  float radius;
  
  // Content Target Properties (Morphing/Lerping)
  float tContentX = 0, tContentY = 0; // Offset from center
  float tShapeSize;
  float tRotation = 0;
  int tColor = color(255);
  boolean isFilled = true; // true = fill, false = stroke
  float tStrokeWeight = 2; // Only used if !isFilled
  
  // Content Current Properties
  float cContentX = 0, cContentY = 0;
  float cShapeSize;
  float cRotation = 0;
  int cColor = color(255);
  float cStrokeWeight = 2;
  
  // Automation State
  // 0 = Manual (Static/User Controlled)
  // 1 = Timed Events (Reacts to onBeat)
  // 2 = Continuous (Drifts via noise)
  int automationMode = 0; 
  
  // Interaction
  boolean isDragging = false;
  boolean isResizing = false;
  boolean isSelected = false;
  float dragOffsetX, dragOffsetY;
  
  MorphShape shape;
  int id;
  float seed;
  float timeOffset; // For noise diversity
  
  // Lerp Speed
  float lerpSpeed = 0.05;
  
  // Animation Modulators (Existing Wobble/Dynamics)
  float animOffsetX, animOffsetY;
  
  // Masking Buffers
  PGraphics pg;
  PGraphics pgMask;
  
  ProjectionWindow(int id, float x, float y, float radius) {
    this.id = id;
    this.x = x; this.y = y;
    this.radius = radius;
    
    this.tShapeSize = radius * 1.5; 
    this.cShapeSize = tShapeSize;
    
    this.shape = new MorphShape(cShapeSize);
    this.seed = random(1000);
    this.timeOffset = random(10000);
    
    // Init colors
    shape.fillColor = cColor;
    shape.strokeColor = cColor;
    shape.strokeWeightVal = cStrokeWeight;
    
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

  void update(float globalTime, int dynamicsMode, float speed, float intensity, boolean sync) {
    
    // 1. Handle Continuous Automation
    if (automationMode == 2) {
      float nSpeed = speed * 0.5; // Slower drift for properties
      float t = globalTime * nSpeed + timeOffset;
      
      // Drift Size
      float nSize = noise(t); 
      tShapeSize = map(nSize, 0, 1, radius * 0.5, radius * 2.5);
      
      // Drift Rotation
      float nRot = noise(t + 100);
      tRotation = map(nRot, 0, 1, 0, TWO_PI * 2);
      
      // Drift Position (Content Offset)
      float nX = noise(t + 200);
      float nY = noise(t + 300);
      float limit = radius * 0.5;
      tContentX = map(nX, 0, 1, -limit, limit);
      tContentY = map(nY, 0, 1, -limit, limit);
      
      // Drift Color
      float nR = noise(t + 400);
      float nG = noise(t + 500);
      float nB = noise(t + 600);
      tColor = color(nR * 255, nG * 255, nB * 255, alpha(tColor)); // Keep current alpha? Or drift alpha too?
    }
    
    // 2. LERP Content Properties towards Targets
    cContentX = lerp(cContentX, tContentX, lerpSpeed);
    cContentY = lerp(cContentY, tContentY, lerpSpeed);
    cShapeSize = lerp(cShapeSize, tShapeSize, lerpSpeed);
    cRotation = lerp(cRotation, tRotation, lerpSpeed);
    cStrokeWeight = lerp(cStrokeWeight, tStrokeWeight, lerpSpeed);
    cColor = lerpColor(cColor, tColor, lerpSpeed);
    
    checkBuffers();
    
    // 3. Calculate Dynamics (Wobble/Shake) - kept from previous version
    float effectiveSeed = sync ? 0 : seed;
    float mod = 0;
    float posXMod = 0;
    float posYMod = 0;
    
    switch (dynamicsMode) {
      case 0: break;
      case 1: // Noise
        mod = noise(effectiveSeed + globalTime * speed) - 0.5;
        posXMod = noise(effectiveSeed + 1000 + globalTime * speed) - 0.5;
        posYMod = noise(effectiveSeed + 2000 + globalTime * speed) - 0.5;
        break;
      case 2: // Wave X
        float phaseX = map(x, 0, width, 0, TWO_PI);
        float waveVal = sin(phaseX + globalTime * speed * 5);
        mod = waveVal * 0.5;
        posYMod = waveVal * 0.5;
        break;
      case 3: // Wave Y
        float phaseY = map(y, 0, height, 0, TWO_PI);
        float waveValY = sin(phaseY + globalTime * speed * 5);
        mod = waveValY * 0.5;
        posXMod = waveValY * 0.5;
        break;
    }
    
    // 4. Apply Dynamics
    animOffsetX = posXMod * radius * intensity * 2.0;
    animOffsetY = posYMod * radius * intensity * 2.0;
    
    float sizeVar = 1.0 + (mod * intensity * 2.0);
    shape.currentSize = cShapeSize * sizeVar;
    shape.calculateTargetVertices(shape.currentShapeType);
    
    shape.rotation = cRotation + (mod * TWO_PI * intensity);
    
    // Update Shape Colors
    if (isFilled) {
      shape.fillColor = cColor;
      shape.strokeColor = color(0, 0); // No stroke
      shape.strokeWeightVal = 0;
    } else {
      shape.fillColor = color(0, 0); // No fill
      shape.strokeColor = cColor;
      shape.strokeWeightVal = cStrokeWeight;
    }
    
    shape.update();
  }
  
  void update() { shape.update(); }
  
  void draw() {
    draw(null, true);
  }

  void draw(PGraphics context, boolean drawDecorations) {
    PGraphics target = (context == null) ? g : context;

    pg.beginDraw();
    pg.background(0, 0); 
    pg.pushMatrix();
    // Translate to Center + Animation Offset + Content Offset
    pg.translate(pg.width/2 + animOffsetX + cContentX, pg.height/2 + animOffsetY + cContentY);
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
        target.stroke(0, 255, 255);
        target.strokeWeight(3);
      } else {
        target.stroke(100);
        target.strokeWeight(1);
      }
      target.ellipse(0, 0, radius * 2, radius * 2);
    }
    
    target.popMatrix();
  }
  
  boolean contains(float px, float py) {
    return dist(px, py, x, y) < radius;
  }
  
  boolean onEdge(float px, float py) {
    float d = dist(px, py, x, y);
    return d > radius - 10 && d < radius + 10;
  }
  
  void mousePressed(float px, float py) {
    if (onEdge(px, py)) {
      isResizing = true;
      isSelected = true;
    } else if (contains(px, py)) {
      isDragging = true;
      dragOffsetX = x - px;
      dragOffsetY = y - py;
      isSelected = true;
    } else {
      isSelected = false;
    }
  }
  
  void mouseDragged(float px, float py) {
    if (isResizing) {
      float d = dist(px, py, x, y);
      radius = max(20, d);
    } else if (isDragging) {
      x = px + dragOffsetX;
      y = py + dragOffsetY;
    }
  }
  
  void mouseReleased() {
    isDragging = false;
    isResizing = false;
  }
  
  // Setters
  void setShapeType(int type) { shape.setTargetShape(type); }
  void setShapeSize(float s) { tShapeSize = s; }
  void setRotation(float r) { tRotation = r; }
  void setColor(color c) { tColor = c; }
  void setFilled(boolean filled) { isFilled = filled; }
  void setStrokeWeight(float w) { tStrokeWeight = w; }
  void setContentOffset(float ox, float oy) { tContentX = ox; tContentY = oy; }
  void setAutomationMode(int mode) { automationMode = mode; }
}