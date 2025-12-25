import java.util.ArrayList;

// Layout
int uiWidth = 300;
int previewWidth = 1200;
int previewHeight = 800;

ArrayList<ProjectionWindow> windows;
OutputFrame outputWindow;
ConfigManager configManager;

// UI
ArrayList<Button> buttons = new ArrayList<Button>();
ArrayList<Slider> sliders = new ArrayList<Slider>();

// Global State
boolean applyToAll = false;
boolean uniformAutomation = false;
float globalTime = 0;

// Shared Automation Params
float noiseSpeed = 0.002;
float bpm = 120;
int lastBeatTime = 0;
boolean beatHappened = false;

void settings() {
  size(uiWidth + previewWidth, previewHeight);
}

void setup() {
  surface.setTitle("Scopture Unified Control");
  colorMode(HSB, 360, 100, 100);
  
  windows = new ArrayList<ProjectionWindow>();
  configManager = new ConfigManager(this);
  
  setupUI();
  addWindow();
}

ProjectionWindow getSelectedWindow() {
  synchronized(windows) {
    if (applyToAll && windows.size() > 0) return windows.get(0);
    for (ProjectionWindow w : windows) {
      if (w.isSelected) return w;
    }
    if (windows.size() > 0) return windows.get(0); 
    return null;
  }
}

StateChecker checkMode(int m) {
  return () -> { 
    ProjectionWindow w = getSelectedWindow(); 
    return w != null && w.controlMode == m; 
  };
}

void setupUI() {
  int y = 20;
  int x = 20;
  int spacing = 30;
  
  // 1. File & Window
  buttons.add(new Button("Add Window", x, y, 100, 20, () -> addWindow()));
  buttons.add(new Button("Remove Sel", x + 110, y, 100, 20, () -> removeSelected()));
  y += spacing;
  buttons.add(new Button("Save JSON", x, y, 100, 20, () -> configManager.saveSettings(windows, "layout.json")));
  buttons.add(new Button("Load JSON", x + 110, y, 100, 20, () -> configManager.loadSettings(windows, "layout.json")));
  y += spacing;
  buttons.add(new Button("Open Output", x, y, 210, 20, () -> openOutputWindow()));
  y += spacing + 15;
  
  // 2. Control Source
  buttons.add(new Toggle("Target: Selected", "Target: ALL", x, y, 210, 20, (val) -> applyToAll = val)
    .setActiveCheck(() -> applyToAll));
  y += spacing + 10;
  
  // Mode Selection
  buttons.add(new Button("MODE: Manual", x, y, 70, 20, () -> setControlMode(0)).setActiveCheck(checkMode(0)));
  buttons.add(new Button("Timed", x + 75, y, 65, 20, () -> setControlMode(1)).setActiveCheck(checkMode(1)));
  buttons.add(new Button("Noise", x + 145, y, 65, 20, () -> setControlMode(2)).setActiveCheck(checkMode(2)));
  y += spacing + 10;
  
  // 3. Automation Controls
  buttons.add(new Toggle("Auto: Indep", "Auto: Uniform", x, y, 210, 20, (val) -> uniformAutomation = val)
    .setActiveCheck(() -> uniformAutomation));
  y += spacing;
  
  sliders.add(new Slider("BPM (Timed)", 30, 200, 120, x, y, 210, 20, (val) -> bpm = val)
    .setValueGetter(() -> bpm));
  y += spacing;
  sliders.add(new Slider("Noise Speed", 0, 0.01, 0.002, x, y, 210, 20, (val) -> noiseSpeed = val)
    .setValueGetter(() -> noiseSpeed));
  y += spacing;
  
  // New Multipliers
  sliders.add(new Slider("Auto Pos Mult", 0.0, 5.0, 1.0, x, y, 210, 20, (val) -> setAutoPosScale(val))
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? w.autoPosScale : 1.0; }));
  y += spacing;
  sliders.add(new Slider("Auto Size Mult", 0.0, 2.0, 1.0, x, y, 210, 20, (val) -> setAutoSizeScale(val))
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? w.autoSizeScale : 1.0; }));
  y += spacing + 15;
  
  // 4. Manual Controls (Override targets)
  
  // Shapes
  String[] shapes = {"Dot", "Line", "Tri", "Sqr", "Hex", "Circ", "Rnd"};
  for (int i = 0; i < shapes.length; i++) {
    final int idx = i;
    if (i < 6) {
      buttons.add(new Button(shapes[i], x + (i * 30), y, 28, 20, () -> setShapeType(idx))
        .setActiveCheck(() -> {
          ProjectionWindow w = getSelectedWindow();
          return w != null && w.shape.currentShapeType == idx;
        }));
    } else {
      buttons.add(new Button(shapes[i], x + (i * 30), y, 28, 20, () -> setRandomShape()));
    }
  }
  y += spacing;
  
  // Props
  sliders.add(new Slider("Size", 10, 600, 100, x, y, 210, 20, (val) -> setManualSize(val))
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? w.tShapeSize : 100; }));
  y += spacing;
  
  sliders.add(new Slider("Rot Speed", -0.2, 0.2, 0, x, y, 210, 20, (val) -> setManualRotSpeed(val))
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? w.tRotationSpeed : 0; }));
  y += spacing;
  
  sliders.add(new Slider("Stroke W", 0, 20, 2, x, y, 210, 20, (val) -> setManualStrokeWeight(val))
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? w.tStrokeWeightVal : 2; }));
  y += spacing;
  
  // Color
  buttons.add(new Toggle("Style: Stroke", "Style: Fill", x, y, 100, 20, (val) -> setManualFilled(val))
    .setActiveCheck(() -> { ProjectionWindow w = getSelectedWindow(); return w != null && w.isFilled; }));
    
  buttons.add(new Button("Reset Pos", x + 110, y, 100, 20, () -> setManualContentPos(0,0)));
  y += spacing;
  
  sliders.add(new Slider("Hue", 0, 360, 0, x, y, 210, 20, (val) -> setManualColor())
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? hue(w.tColor) : 0; }));
  y += spacing;
  
  sliders.add(new Slider("Sat", 0, 100, 100, x, y, 210, 20, (val) -> setManualColor())
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? saturation(w.tColor) : 100; }));
  y += spacing;
  
  sliders.add(new Slider("Bri", 0, 100, 100, x, y, 210, 20, (val) -> setManualColor())
    .setValueGetter(() -> { ProjectionWindow w = getSelectedWindow(); return w != null ? brightness(w.tColor) : 100; }));
  y += spacing;
}

void draw() {
  background(0);
  
  // UI Panel
  noStroke(); fill(20); rect(0, 0, uiWidth, height);
  drawUI();
  
  // Update Global Time
  globalTime += 1.0; 
  
  // Handle BPM
  beatHappened = false;
  int beatInterval = int(60000.0 / bpm);
  if (millis() - lastBeatTime >= beatInterval) {
    lastBeatTime = millis();
    beatHappened = true;
  }
  
  // Generate Uniform Props if needed
  float uX=0, uY=0, uSz=0, uRot=0, uStr=0;
  int uCol=0, uShape=0;
  boolean uFill=true;
  
  if (beatHappened && uniformAutomation) {
    uX = random(-1, 1);
    uY = random(-1, 1);
    uSz = random(0, 1); // Normalized
    uRot = random(-0.1, 0.1);
    uCol = color(random(360), random(50, 100), random(50, 100));
    uFill = random(1) > 0.5;
    uStr = random(1, 10);
    uShape = int(random(6));
  }
  
  // Update Windows
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      boolean windowBeat = beatHappened;
      
      if (uniformAutomation && beatHappened && w.controlMode == 1) {
         w.setDirectTargetProperties(uX, uY, uSz, uRot, uCol, uFill, uStr, uShape);
         windowBeat = false; // Prevent internal random trigger
      }
      
      w.update(globalTime, noiseSpeed, windowBeat, uniformAutomation);
    }
  }
  
  // Draw Preview
  pushMatrix();
  translate(uiWidth, 0);
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      w.draw(this.g, true);
    }
  }
  popMatrix();
}

void drawUI() {
  fill(255); textAlign(LEFT, BASELINE);
  text("Unified Controls", 20, 15);
  for (Button b : buttons) b.draw();
  for (Slider s : sliders) s.draw();
}

void openOutputWindow() {
  if (outputWindow == null) {
    outputWindow = new OutputFrame(previewWidth, previewHeight, windows);
    PApplet.runSketch(new String[]{"OutputFrame"}, outputWindow);
  }
}

// --- COMMANDS ---

void setControlMode(int mode) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setControlMode(mode);
    }
  }
}

void setShapeType(int type) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setShapeType(type);
    }
  }
}

void setRandomShape() {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setShapeType(int(random(6)));
    }
  }
}

void setManualSize(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setManualSize(val);
    }
  }
}

void setManualRotSpeed(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setManualRotSpeed(val);
    }
  }
}

void setManualStrokeWeight(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setManualStrokeWeight(val);
    }
  }
}

void setManualFilled(boolean val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setManualFilled(val);
    }
  }
}

void setManualContentPos(float x, float y) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setManualContentPos(x, y);
    }
  }
}

void setManualColor() {
  // Sliders: 
  // 0:BPM, 1:NoiseSpeed, 2:PosMult, 3:SizeMult
  // 4:Size, 5:RotSpeed, 6:StrW
  // 7:Hue, 8:Sat, 9:Bri
  
  float h = sliders.get(7).value;
  float s = sliders.get(8).value;
  float b = sliders.get(9).value;
  color c = color(h, s, b);
  
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setManualColor(c);
    }
  }
}

void setAutoPosScale(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setAutoPosScale(val);
    }
  }
}

void setAutoSizeScale(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setAutoSizeScale(val);
    }
  }
}

void addWindow() {
  synchronized(windows) {
    int id = windows.size();
    float r = 100;
    PVector pos = calculateOnionPosition(id, r * 2.1);
    windows.add(new ProjectionWindow(id, previewWidth/2 + pos.x, previewHeight/2 + pos.y, r));
  }
}

PVector calculateOnionPosition(int index, float spacing) {
  if (index == 0) return new PVector(0, 0);
  int ring = 1; int count = 1; 
  while (index >= count + ring * 6) { count += ring * 6; ring++; }
  int ringIndex = index - count;
  int itemsInRing = ring * 6;
  float angleStep = TWO_PI / itemsInRing;
  float angle = ringIndex * angleStep;
  float radius = ring * spacing;
  return new PVector(cos(angle) * radius, sin(angle) * radius);
}

void removeSelected() {
  synchronized(windows) {
    for (int i = windows.size() - 1; i >= 0; i--) {
      if (windows.get(i).isSelected) windows.remove(i);
    }
  }
}

// --- INTERACTION ---

void mousePressed() {
  if (mouseX < uiWidth) {
    for (Button b : buttons) b.mousePressed(mouseX, mouseY);
    for (Slider s : sliders) s.mousePressed(mouseX, mouseY);
  } else {
    float px = mouseX - uiWidth;
    float py = mouseY;
    boolean clickedAnyWindow = false;
    
    synchronized(windows) {
      for (int i = windows.size() - 1; i >= 0; i--) {
        ProjectionWindow w = windows.get(i);
        if (w.contains(px, py) || w.onEdge(px, py)) {
           w.isSelected = !w.isSelected;
           if (w.isSelected) w.mousePressed(px, py);
           clickedAnyWindow = true;
           break; 
        }
      }
      
      if (!clickedAnyWindow) {
         for (ProjectionWindow w : windows) w.isSelected = false;
      }
    }
  }
}

void mouseDragged() {
  if (mouseX < uiWidth) {
    for (Slider s : sliders) s.mouseDragged(mouseX, mouseY);
  } else {
    float px = mouseX - uiWidth;
    float py = mouseY;
    synchronized(windows) {
      for (ProjectionWindow w : windows) w.mouseDragged(px, py);
    }
  }
}

void mouseReleased() {
  synchronized(windows) { for (ProjectionWindow w : windows) w.mouseReleased(); }
}