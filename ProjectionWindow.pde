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
  
  // Keystone
  boolean isKeystoning = false;
  PVector[] corners = new PVector[4]; // TL, TR, BR, BL relative to x,y
  int activeCorner = -1;
  
  // Interaction
  boolean isDragging = false;
  boolean isResizing = false;
  boolean isSelected = false;
  boolean isDraggable = false; // Dragging Guard
  boolean isResizable = false; // Resizing Guard
  long lastSelectionTime = 0;
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
    
    resetCorners();
    checkBuffers();
  }
  
  void resetCorners() {
    corners[0] = new PVector(-radius, -radius);
    corners[1] = new PVector(radius, -radius);
    corners[2] = new PVector(radius, radius);
    corners[3] = new PVector(-radius, radius);
  }
  
  void checkBuffers() {
    int requiredSize = (int)(radius * 2 + 20);
    if (pg == null || pg.width != requiredSize) {
      pg = createGraphics(requiredSize, requiredSize);
      pg.beginDraw();
      pg.colorMode(HSB, 360, 100, 100);
      pg.endDraw();
      
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

  PVector getInterpolatedPoint(float u, float v) {
    // Bilinear interpolation between the 4 corners
    PVector top = PVector.lerp(corners[0], corners[1], u);
    PVector bottom = PVector.lerp(corners[3], corners[2], u);
    return PVector.lerp(top, bottom, v);
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
    
    // Draw Selection Ring into the buffer so it warps with keystone
    if (drawDecorations) {
       pg.beginDraw();
       pg.noFill();
       if (isSelected) {
         if (isResizable) {
           pg.stroke(0, 100, 100); // Red
           pg.strokeWeight(8);
         } else if (isDraggable) {
           pg.stroke(210, 100, 100); // Blue
           pg.strokeWeight(8);
         } else if (isKeystoning) {
           pg.stroke(120, 100, 100); // Green
           pg.strokeWeight(8);
         } else {
           // White for Neutral Selection
           pg.stroke(0, 0, 100); 
           pg.strokeWeight(4); 
         }
       } else {
         pg.stroke(0, 0, 40); // Grey
         pg.strokeWeight(1);
       }
       pg.ellipse(pg.width/2, pg.height/2, radius * 2, radius * 2);
       pg.endDraw();
    }
    
    target.pushMatrix();
    target.translate(x, y);
    
    // Keystoned Draw with Subdivision to fix affine artifacts
    target.noStroke();
    target.fill(255);
    
    int steps = 20; // 20x20 grid
    target.beginShape(QUAD);
    target.texture(pg);
    
    for (int i = 0; i < steps; i++) {
      for (int j = 0; j < steps; j++) {
        float u0 = (float)i / steps;
        float u1 = (float)(i + 1) / steps;
        float v0 = (float)j / steps;
        float v1 = (float)(j + 1) / steps;
        
        // Calculate 4 corners of this cell
        PVector p00 = getInterpolatedPoint(u0, v0);
        PVector p10 = getInterpolatedPoint(u1, v0);
        PVector p11 = getInterpolatedPoint(u1, v1);
        PVector p01 = getInterpolatedPoint(u0, v1);
        
        // Texture coords
        float tU0 = u0 * pg.width;
        float tU1 = u1 * pg.width;
        float tV0 = v0 * pg.height;
        float tV1 = v1 * pg.height;
        
        target.vertex(p00.x, p00.y, tU0, tV0);
        target.vertex(p10.x, p10.y, tU1, tV0);
        target.vertex(p11.x, p11.y, tU1, tV1);
        target.vertex(p01.x, p01.y, tU0, tV1);
      }
    }
    target.endShape();
    
    if (drawDecorations) {
      // Draw Keystone Handles (Screen space, not warped)
      if (isKeystoning && isSelected) {
        target.fill(120, 100, 100); // Bright Green
        target.noStroke();
        for (PVector c : corners) {
          target.ellipse(c.x, c.y, 18, 18);
        }
      }
    }
    
    target.popMatrix();
  }
  
  // Interaction
  boolean contains(float px, float py) { 
    if (isKeystoning && isSelected) {
       for (PVector c : corners) {
         if (dist(px - x, py - y, c.x, c.y) < 20) return true;
       }
    }
    return dist(px, py, x, y) < radius; 
  }
  boolean onEdge(float px, float py) {
    float d = dist(px, py, x, y);
    return d > radius - 10 && d < radius + 10;
  }
  
  void toggleKeystone() {
     isKeystoning = !isKeystoning; 
  }
  
  void mousePressed(float px, float py) {
    if (mouseButton != LEFT) return; // Only LEFT button allowed
    
    // 1. Keystone Handles (Highest Priority)
    if (isKeystoning && isSelected) {
      float relX = px - x;
      float relY = py - y;
      for (int i = 0; i < 4; i++) {
        if (dist(relX, relY, corners[i].x, corners[i].y) < 20) {
          activeCorner = i;
          return; 
        }
      }
    }
    
    // Check if inside window
    if (contains(px, py)) {
      // 2. Resize Mode
      if (isResizable) {
        isResizing = true;
        // Don't return, allow logic to proceed? No, one action per click.
        return;
      }
      
      // 3. Drag Mode
      if (isDraggable) {
        isDragging = true;
        dragOffsetX = x - px;
        dragOffsetY = y - py;
      }
    }
  }
  
  void mouseDragged(float px, float py) {
    if (activeCorner != -1) {
       corners[activeCorner].x = px - x;
       corners[activeCorner].y = py - y;
    }
    else if (isResizing) { 
      float oldRadius = radius;
      radius = max(20, dist(px, py, x, y)); 
      
      if (oldRadius > 0) {
        float scale = radius / oldRadius;
        // Scale Size
        shapeSize *= scale;
        tShapeSize *= scale;
        
        // Scale Position
        contentX *= scale;
        tContentX *= scale;
        contentY *= scale;
        tContentY *= scale;
        
        // Scale Stroke
        strokeWeightVal *= scale;
        tStrokeWeightVal *= scale;
        
        // Scale Corners
        for(PVector c : corners) c.mult(scale);
      }
      checkBuffers();
    }
    else if (isDragging && isDraggable) { x = px + dragOffsetX; y = py + dragOffsetY; }
  }
  void mouseReleased() { isDragging = false; isResizing = false; activeCorner = -1; }
  
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