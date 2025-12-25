class ProjectionWindow {
  // Target Base Properties (Where we want to be)
  float tX, tY;
  float tRadius;
  float tShapeSize;
  float tRotation = 0;
  color tFillColor = color(255, 100);
  color tStrokeColor = color(255);
  float tStrokeWeight = 2;
  
  // Current Properties (Where we are)
  float cX, cY;
  float cRadius;
  float cShapeSize;
  float cRotation = 0;
  color cFillColor = color(255, 100);
  color cStrokeColor = color(255);
  float cStrokeWeight = 2;
  
  // Interaction
  boolean isDragging = false;
  boolean isResizing = false;
  boolean isSelected = false;
  float dragOffsetX, dragOffsetY;
  
  MorphShape shape;
  int id;
  float seed;
  
  // Lerp Speed
  float lerpSpeed = 0.05;
  
  // Animation Modulators
  float animOffsetX, animOffsetY;
  
  // Masking Buffers
  PGraphics pg;
  PGraphics pgMask;
  
  ProjectionWindow(int id, float x, float y, float radius) {
    this.id = id;
    this.tX = x; this.tY = y;
    this.tRadius = radius;
    this.tShapeSize = radius * 1.5; 
    
    // Init currents
    this.cX = x; this.cY = y;
    this.cRadius = radius;
    this.cShapeSize = tShapeSize;
    
    this.shape = new MorphShape(cShapeSize);
    this.seed = random(1000);
    
    // Init colors
    shape.fillColor = cFillColor;
    shape.strokeColor = cStrokeColor;
    shape.strokeWeightVal = cStrokeWeight;
    
    checkBuffers();
  }
  
  void checkBuffers() {
    // Determine required size (diameter + padding)
    int requiredSize = (int)(cRadius * 2 + 20);
    if (pg == null || pg.width != requiredSize) {
      pg = createGraphics(requiredSize, requiredSize);
      pgMask = createGraphics(requiredSize, requiredSize);
      
      // Update mask
      pgMask.beginDraw();
      pgMask.background(0);
      pgMask.fill(255);
      pgMask.noStroke();
      pgMask.ellipse(requiredSize/2, requiredSize/2, cRadius * 2, cRadius * 2);
      pgMask.endDraw();
    }
  }

  void update(float time, int mode, float speed, float intensity, boolean sync) {
    // 1. LERP Base Properties towards Targets
    cX = lerp(cX, tX, lerpSpeed);
    cY = lerp(cY, tY, lerpSpeed);
    cRadius = lerp(cRadius, tRadius, lerpSpeed);
    cShapeSize = lerp(cShapeSize, tShapeSize, lerpSpeed);
    cRotation = lerp(cRotation, tRotation, lerpSpeed);
    cStrokeWeight = lerp(cStrokeWeight, tStrokeWeight, lerpSpeed);
    
    cFillColor = lerpColor(cFillColor, tFillColor, lerpSpeed);
    cStrokeColor = lerpColor(cStrokeColor, tStrokeColor, lerpSpeed);
    
    checkBuffers();
    
    // 2. Calculate Animation/Noise
    float effectiveSeed = sync ? 0 : seed;
    float mod = 0;
    float colorMod = 0;
    float posXMod = 0;
    float posYMod = 0;
    
    switch (mode) {
      case 0: break;
      case 1: 
        mod = noise(effectiveSeed + time * speed) - 0.5;
        colorMod = noise(effectiveSeed + 500 + time * speed) - 0.5;
        posXMod = noise(effectiveSeed + 1000 + time * speed) - 0.5;
        posYMod = noise(effectiveSeed + 2000 + time * speed) - 0.5;
        break;
      case 2:
        float phaseX = map(cX, 0, width, 0, TWO_PI);
        float waveVal = sin(phaseX + time * speed * 5);
        mod = waveVal * 0.5;
        colorMod = cos(phaseX + time * speed * 5) * 0.5;
        posYMod = waveVal * 0.5;
        break;
      case 3:
        float phaseY = map(cY, 0, height, 0, TWO_PI);
        float waveValY = sin(phaseY + time * speed * 5);
        mod = waveValY * 0.5;
        colorMod = cos(phaseY + time * speed * 5) * 0.5;
        posXMod = waveValY * 0.5;
        break;
    }
    
    // 3. Apply Animation to produce Final Drawing Values
    // Position Offsets (Shape can now freely move, it will be masked)
    animOffsetX = posXMod * cRadius * intensity * 2.0;
    animOffsetY = posYMod * cRadius * intensity * 2.0;
    
    // Size Modulation
    float sizeVar = 1.0 + (mod * intensity * 2.0);
    shape.currentSize = cShapeSize * sizeVar;
    shape.calculateTargetVertices(shape.currentShapeType);
    
    // Rotation
    shape.rotation = cRotation + (mod * TWO_PI * intensity);
    
    // Color
    float alphaVar = 1.0 + (colorMod * intensity);
    float a = alpha(cFillColor) * constrain(alphaVar, 0.2, 1.0);
    shape.fillColor = color(red(cFillColor), green(cFillColor), blue(cFillColor), a);
    shape.strokeColor = cStrokeColor;
    shape.strokeWeightVal = cStrokeWeight;
    
    shape.update();
  }
  
  void update() { shape.update(); }
  
  void draw() {
    draw(null, true);
  }

  void draw(PGraphics context, boolean drawDecorations) {
    // Determine target PGraphics or PApplet
    // Since 'g' is PGraphics, we can use that interface. 
    // If context is null, use the current PApplet's main graphics (g).
    // However, in Processing code, 'g' is available globally within classes usually?
    // No, 'g' belongs to the PApplet. If this class is not an inner class of PApplet, 
    // it technically doesn't see 'g' unless passed or if it uses PApplet functions which delegate to static/global context?
    // Actually, in .pde files, classes are inner classes of the main PApplet by default?
    // - "scopture.pde" compiles to a class. "ProjectionWindow" is usually an inner class.
    // - BUT if it's in a separate tab/file, it's still an inner class of the main sketch class.
    // - HOWEVER, we are drawing from *other* PApplets (OutputFrame). 
    // - 'g' in 'ProjectionWindow' will refer to the MAIN sketch's 'g'.
    // - So we MUST pass the context if we want to draw to a different PApplet.
    
    PGraphics target = (context == null) ? g : context;

    // Draw the shape into the buffer
    pg.beginDraw();
    pg.background(0, 0); // Transparent (0 alpha)
    pg.pushMatrix();
    pg.translate(pg.width/2 + animOffsetX, pg.height/2 + animOffsetY);
    shape.draw(pg);
    pg.popMatrix();
    pg.endDraw();
    
    // Mask it
    pg.mask(pgMask);
    
    target.pushMatrix();
    target.translate(cX, cY);
    
    // Draw the masked shape
    target.imageMode(CENTER);
    target.image(pg, 0, 0);
    
    // Draw Window Boundary (the frame)
    if (drawDecorations) {
      target.noFill();
      if (isSelected) {
        target.stroke(0, 255, 255);
        target.strokeWeight(3);
      } else {
        target.stroke(100);
        target.strokeWeight(1);
      }
      target.ellipse(0, 0, cRadius * 2, cRadius * 2);
    }
    
    target.popMatrix();
  }
  
  boolean contains(float px, float py) {
    return dist(px, py, cX, cY) < cRadius;
  }
  
  boolean onEdge(float px, float py) {
    float d = dist(px, py, cX, cY);
    return d > cRadius - 10 && d < cRadius + 10;
  }
  
  void mousePressed(float px, float py) {
    if (onEdge(px, py)) {
      isResizing = true;
      isSelected = true;
    } else if (contains(px, py)) {
      isDragging = true;
      dragOffsetX = tX - px;
      dragOffsetY = tY - py;
      isSelected = true;
    } else {
      isSelected = false;
    }
  }
  
  void mouseDragged(float px, float py) {
    if (isResizing) {
      float d = dist(px, py, cX, cY);
      tRadius = max(20, d);
    } else if (isDragging) {
      tX = px + dragOffsetX;
      tY = py + dragOffsetY;
    }
  }
  
  void mouseReleased() {
    isDragging = false;
    isResizing = false;
  }
  
  void setShapeType(int type) { shape.setTargetShape(type); }
  void setShapeSize(float s) { tShapeSize = s; }
  void setRotation(float r) { tRotation = r; }
  void setStrokeColor(color c) { tStrokeColor = c; }
  void setFillColor(color c) { tFillColor = c; }
  void setStrokeWeight(float w) { tStrokeWeight = w; }
}