class MorphShape {
  // Shape types
  static final int SHAPE_DOT = 0;
  static final int SHAPE_LINE = 1;
  static final int SHAPE_TRIANGLE = 2;
  static final int SHAPE_SQUARE = 3;
  static final int SHAPE_HEXAGON = 4;
  static final int SHAPE_CIRCLE = 5;

  ArrayList<PVector> vertices = new ArrayList<PVector>();
  ArrayList<PVector> targetVertices = new ArrayList<PVector>();
  
  // Configuration
  int vertexCount = 120; 
  float currentSize = 100;
  int currentShapeType = SHAPE_CIRCLE;
  
  // Visual properties
  color strokeColor = color(255);
  color fillColor = color(255, 100);
  float strokeWeightVal = 2;
  float rotation = 0;
  
  MorphShape(float size) {
    this.currentSize = size;
    initVertices();
    setTargetShape(SHAPE_CIRCLE);
    for (int i = 0; i < vertexCount; i++) {
      vertices.set(i, targetVertices.get(i).copy());
    }
  }

  void initVertices() {
    for (int i = 0; i < vertexCount; i++) {
      vertices.add(new PVector());
      targetVertices.add(new PVector());
    }
  }

  void update() {
    for (int i = 0; i < vertexCount; i++) {
      PVector v = vertices.get(i);
      PVector t = targetVertices.get(i);
      v.x = lerp(v.x, t.x, 0.1);
      v.y = lerp(v.y, t.y, 0.1);
    }
  }

  void update(float time, float intensity) {
    update();
  }

  // Draw to the main screen
  void draw() {
    draw(null);
  }

  // Draw to a specific PGraphics buffer
  void draw(PGraphics pg) {
    if (pg != null) {
      pg.pushStyle();
      pg.stroke(strokeColor);
      pg.strokeWeight(strokeWeightVal);
      pg.strokeJoin(ROUND);
      pg.strokeCap(ROUND);
      pg.fill(fillColor);
      pg.pushMatrix();
      pg.rotate(rotation);
      pg.beginShape();
      for (PVector v : vertices) pg.vertex(v.x, v.y);
      pg.endShape(CLOSE);
      pg.popMatrix();
      pg.popStyle();
    } else {
      pushStyle();
      stroke(strokeColor);
      strokeWeight(strokeWeightVal);
      strokeJoin(ROUND);
      strokeCap(ROUND);
      fill(fillColor);
      pushMatrix();
      rotate(rotation);
      beginShape();
      for (PVector v : vertices) vertex(v.x, v.y);
      endShape(CLOSE);
      popMatrix();
      popStyle();
    }
  }

  void setTargetShape(int type) {
    this.currentShapeType = type;
    calculateTargetVertices(type);
  }

  void calculateTargetVertices(int type) {
    float r = currentSize / 2;
    for (int i = 0; i < vertexCount; i++) {
      float progress = (float)i / vertexCount;
      float angle = map(progress, 0, 1, 0, TWO_PI);
      float x = 0, y = 0;
      switch (type) {
        case SHAPE_DOT: x = cos(angle) * 1.5; y = sin(angle) * 1.5; break;
        case SHAPE_LINE: 
          if (progress < 0.5) { x = map(progress, 0, 0.5, -r, r); y = -2; }
          else { x = map(progress, 0.5, 1.0, r, -r); y = 2; }
          break;
        case SHAPE_TRIANGLE:
          // Triangle Corners
          float cx1 = r * cos(PI/6); float cy1 = r * sin(PI/6); // BotRight
          float cx2 = r * cos(5*PI/6); float cy2 = r * sin(5*PI/6); // BotLeft
          float cx3 = 0; float cy3 = -r; // Top
          
          // Start at Midpoint of Right Side (Top to BotRight)
          float sx = lerp(cx3, cx1, 0.5);
          float sy = lerp(cy3, cy1, 0.5);
          
          if (progress < 1.0/6.0) { 
             // Leg 1: Mid-Right to BotRight
             float p = map(progress, 0, 1.0/6.0, 0, 1);
             x = lerp(sx, cx1, p);
             y = lerp(sy, cy1, p);
          } else if (progress < 3.0/6.0) { // Up to 1/2
             // Leg 2: BotRight to BotLeft
             float p = map(progress, 1.0/6.0, 3.0/6.0, 0, 1);
             x = lerp(cx1, cx2, p);
             y = lerp(cy1, cy2, p);
          } else if (progress < 5.0/6.0) { // Up to 5/6
             // Leg 3: BotLeft to Top
             float p = map(progress, 3.0/6.0, 5.0/6.0, 0, 1);
             x = lerp(cx2, cx3, p);
             y = lerp(cy2, cy3, p);
          } else {
             // Leg 4: Top to Mid-Right
             float p = map(progress, 5.0/6.0, 1.0, 0, 1);
             x = lerp(cx3, sx, p);
             y = lerp(cy3, sy, p);
          }
          break;
        case SHAPE_SQUARE:
           if (progress < 0.25) { x = map(progress, 0, 0.25, -r, r); y = -r; }
           else if (progress < 0.5) { x = r; y = map(progress, 0.25, 0.5, -r, r); }
           else if (progress < 0.75) { x = map(progress, 0.5, 0.75, r, -r); y = r; }
           else { x = -r; y = map(progress, 0.75, 1.0, r, -r); }
           break;
        case SHAPE_HEXAGON:
           int side = floor(progress * 6);
           float p = (progress * 6) - side;
           float a1 = map(side, 0, 6, -PI/2, TWO_PI - PI/2);
           float a2 = map(side+1, 0, 6, -PI/2, TWO_PI - PI/2);
           x = lerp(r * cos(a1), r * cos(a2), p);
           y = lerp(r * sin(a1), r * sin(a2), p);
           break;
        case SHAPE_CIRCLE: x = cos(angle - PI/2) * r; y = sin(angle - PI/2) * r; break;
      }
      targetVertices.get(i).set(x, y);
    }
  }
}
