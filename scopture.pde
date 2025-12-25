import java.util.ArrayList;

// Layout Constants
int uiWidth = 300;
int previewWidth = 1200;
int previewHeight = 800;

ArrayList<ProjectionWindow> windows;
OutputFrame outputWindow;
ConfigManager configManager;

// UI Elements
ArrayList<Button> buttons = new ArrayList<Button>();
ArrayList<Slider> sliders = new ArrayList<Slider>();

// UI State
boolean applyToAll = false;
boolean editStroke = false;

// Animation State
float globalTime = 0;
float animSpeed = 0.02;     
float animIntensity = 0.0;  
int animMode = 0;           
boolean autoTimedEvents = false;
boolean syncDynamics = false;

// Event Toggles
boolean allowModeSwitch = true;
boolean allowShapeSwitch = true;
boolean allowColorSwitch = true;

// BPM & Event State
float bpm = 120;
int lastBeatTime = 0;
int totalBeats = 0;

// Event Logic
int eventInterval = 1; // Fire every 1 beat by default

int nextModeSwitch = 1;
int modeBeatCounter = 0;

int nextShapeSwitch = 1;
int shapeBeatCounter = 0;

int nextColorSwitch = 1;
int colorBeatCounter = 0;

void settings() {
  size(uiWidth + previewWidth, previewHeight); // 1500 x 800
}

void setup() {
  surface.setTitle("Scopture Control & Preview");
  windows = new ArrayList<ProjectionWindow>();
  configManager = new ConfigManager(this);
  
  setupUI();
  
  addWindow();
}

void setupUI() {
  int y = 20;
  int x = 20;
  int spacing = 30;
  
  // --- File & Window Mgmt ---
  buttons.add(new Button("Add Window", x, y, 100, 20, () -> addWindow()));
  buttons.add(new Button("Remove Sel", x + 110, y, 100, 20, () -> removeSelected()));
  y += spacing;
  
  buttons.add(new Button("Save JSON", x, y, 100, 20, () -> configManager.saveSettings(windows, "layout.json")));
  buttons.add(new Button("Load JSON", x + 110, y, 100, 20, () -> configManager.loadSettings(windows, "layout.json")));
  y += spacing;
  
  // --- Output Window ---
  buttons.add(new Button("Open Output", x, y, 210, 20, () -> openOutputWindow()));
  y += spacing + 10;
  
  // --- Targeting ---
  buttons.add(new Toggle("Target: Selected", "Target: All", x, y, 210, 20, (val) -> applyToAll = val));
  y += spacing + 10;
  
  // --- Base Properties ---
  String[] shapes = {"Dot", "Line", "Tri", "Sqr", "Hex", "Circ"};
  for (int i = 0; i < shapes.length; i++) {
    final int shapeType = i;
    buttons.add(new Button(shapes[i], x + (i * 35), y, 30, 20, () -> applyShape(shapeType)));
  }
  y += spacing;
  
  sliders.add(new Slider("Size", 10, 300, 100, x, y, 210, 20, (val) -> applySize(val)));
  y += spacing;
  sliders.add(new Slider("Rotation", 0, TWO_PI, 0, x, y, 210, 20, (val) -> applyRotation(val)));
  y += spacing;
  sliders.add(new Slider("Stroke W", 0, 20, 2, x, y, 210, 20, (val) -> applyStrokeWeight(val)));
  y += spacing;
  
  // Color
  y += 10;
  buttons.add(new Toggle("Edit: Fill", "Edit: Stroke", x, y, 210, 20, (val) -> editStroke = val));
  y += spacing;
  
  sliders.add(new Slider("Red", 0, 255, 255, x, y, 210, 20, (val) -> applyColor()));
  y += spacing;
  sliders.add(new Slider("Green", 0, 255, 255, x, y, 210, 20, (val) -> applyColor()));
  y += spacing;
  sliders.add(new Slider("Blue", 0, 255, 255, x, y, 210, 20, (val) -> applyColor()));
  y += spacing;
  sliders.add(new Slider("Alpha", 0, 255, 100, x, y, 210, 20, (val) -> applyColor()));
  y += spacing + 10;
  
  buttons.add(new Button("Randomize All", x, y, 210, 20, () -> randomizeAll()));
  y += spacing + 20;
  
  // --- Dynamics ---
  buttons.add(new Button("Static", x, y, 50, 20, () -> animMode = 0));
  buttons.add(new Button("Noise", x + 55, y, 50, 20, () -> animMode = 1));
  buttons.add(new Button("Wave X", x + 110, y, 50, 20, () -> animMode = 2));
  buttons.add(new Button("Wave Y", x + 165, y, 50, 20, () -> animMode = 3));
  y += spacing;
  
  sliders.add(new Slider("Speed", 0, 0.1, 0.02, x, y, 210, 20, (val) -> animSpeed = val));
  y += spacing;
  sliders.add(new Slider("Intensity", 0, 2.0, 0.0, x, y, 210, 20, (val) -> animIntensity = val));
  y += spacing;
  
  buttons.add(new Toggle("Sync: Independent", "Sync: Uniform", x, y, 210, 20, (val) -> syncDynamics = val));
  y += spacing;
  
  sliders.add(new Slider("BPM", 1, 200, 120, x, y, 210, 20, (val) -> bpm = val));
  y += spacing;
  
  // Event Choices
  buttons.add(new Toggle("Events: Shape [X]", "Events: Shape [O]", x, y, 100, 20, (val) -> allowShapeSwitch = val));
  buttons.add(new Toggle("Events: Mode [X]", "Events: Mode [O]", x + 110, y, 100, 20, (val) -> allowModeSwitch = val));
  y += spacing;
  buttons.add(new Toggle("Events: Color [X]", "Events: Color [O]", x, y, 100, 20, (val) -> allowColorSwitch = val));
  buttons.add(new Button("Manual Trigger", x + 110, y, 100, 20, () -> triggerEvent(3)));
  y += spacing;
    
  buttons.add(new Toggle("Timed Events: OFF", "Timed Events: ON", x, y, 210, 20, (val) -> autoTimedEvents = val));
}

void draw() {
  background(0);
  
  // 1. Draw UI Panel
  noStroke();
  fill(50);
  rect(0, 0, uiWidth, height);
  
  drawUI();
  
  // 2. Logic Update
  globalTime += animSpeed;
  handleBPM();
  
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      w.update(globalTime, animMode, animSpeed, animIntensity, syncDynamics);
    }
  }
  
  // 3. Draw Preview
  pushMatrix();
  translate(uiWidth, 0);
  
  // Optional: Clip to preview area to avoid drawing over UI
  // clip(0, 0, previewWidth, previewHeight); 
  // Processing clip() is sometimes buggy with complex shapes/P3D, but simple here.
  // Instead, we just trust the translation.
  
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      // Pass 'g' (this PApplet's graphics) and 'true' (show decorations)
      w.draw(this.g, true);
    }
  }
  
  popMatrix();
}

void drawUI() {
  fill(255);
  textAlign(LEFT, BASELINE);
  text("Control Panel", 20, 15);
  text("Dynamics Mode: " + getModeName(animMode), 20, height - 20);
  
  for (Button b : buttons) b.draw();
  for (Slider s : sliders) s.draw();
}

String getModeName(int m) {
  if (m == 0) return "Static";
  if (m == 1) return "Noise";
  if (m == 2) return "Wave X";
  if (m == 3) return "Wave Y";
  return "";
}

void openOutputWindow() {
  // Only open if not exists (simplification)
  // Real robustness might check if window is closed, etc.
  if (outputWindow == null) {
    outputWindow = new OutputFrame(previewWidth, previewHeight, windows);
    String[] args = {"OutputFrame"};
    PApplet.runSketch(args, outputWindow);
  }
}

// --- Interaction Logic ---

void mousePressed() {
  if (mouseX < uiWidth) {
    // UI Interaction
    for (Button b : buttons) b.mousePressed(mouseX, mouseY);
    for (Slider s : sliders) s.mousePressed(mouseX, mouseY);
  } else {
    // Preview Interaction
    float px = mouseX - uiWidth;
    float py = mouseY;
    
    boolean clickedBackground = true;
    synchronized(windows) {
      for (int i = windows.size() - 1; i >= 0; i--) {
        ProjectionWindow w = windows.get(i);
        w.mousePressed(px, py);
        if (w.isSelected) {
          clickedBackground = false;
          break; 
        }
      }
      
      if (clickedBackground) {
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
      for (ProjectionWindow w : windows) {
        w.mouseDragged(px, py);
      }
    }
  }
}

void mouseReleased() {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      w.mouseReleased();
    }
  }
}

void keyPressed() {
  if (key == 's') {
    configManager.saveSettings(windows, "layout.json");
  }
  if (key == 'l') {
    configManager.loadSettings(windows, "layout.json");
  }
}

// --- Application Logic Helpers ---

void handleBPM() {
  int beatInterval = int(60000.0 / bpm); 
  if (millis() - lastBeatTime >= beatInterval) {
    lastBeatTime = millis();
    totalBeats++;
    if (autoTimedEvents) {
      onBeat();
    }
  }
}

void onBeat() {
  modeBeatCounter++;
  shapeBeatCounter++;
  colorBeatCounter++;
  
  if (allowModeSwitch && modeBeatCounter >= eventInterval) {
    triggerEvent(1); 
    modeBeatCounter = 0;
  }
  
  if (allowShapeSwitch && shapeBeatCounter >= eventInterval) {
    triggerEvent(0); 
    shapeBeatCounter = 0;
  }
  
  if (allowColorSwitch && colorBeatCounter >= eventInterval) {
    triggerEvent(2); 
    colorBeatCounter = 0;
  }
}

void triggerEvent(int type) {
  if (type == 3) type = int(random(3));
  
  if (type == 0) {
    int sType = int(random(6));
    synchronized(windows) {
      for (ProjectionWindow w : windows) w.setShapeType(sType);
    }
  } else if (type == 1) {
    animMode = int(random(4));
  } else if (type == 2) {
    color c = color(random(255), random(255), random(255), 150);
    float size = random(50, 150);
    float rot = random(TWO_PI);
    synchronized(windows) {
      for (ProjectionWindow w : windows) {
        w.setFillColor(c);
        w.setShapeSize(size);
        w.setRotation(rot);
      }
    }
  }
}

void addWindow() {
  synchronized(windows) {
    int id = windows.size();
    float defaultRadius = 100;
    // Center relative to Preview Area
    PVector pos = calculateOnionPosition(id, defaultRadius * 2.1);
    float cx = previewWidth / 2;
    float cy = previewHeight / 2;
    windows.add(new ProjectionWindow(id, cx + pos.x, cy + pos.y, defaultRadius));
  }
}

PVector calculateOnionPosition(int index, float spacing) {
  if (index == 0) return new PVector(0, 0);
  
  int ring = 1;
  int count = 1; 
  
  while (index >= count + ring * 6) {
    count += ring * 6;
    ring++;
  }
  
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
      if (windows.get(i).isSelected) {
        windows.remove(i);
      }
    }
  }
}

void applyShape(int type) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setShapeType(type);
    }
  }
}

void applySize(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setShapeSize(val);
    }
  }
}

void applyRotation(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setRotation(val);
    }
  }
}

void applyStrokeWeight(float val) {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) w.setStrokeWeight(val);
    }
  }
}

void applyColor() {
  // Access sliders by index. Ensure order matches setupUI!
  // Sliders: 0=Size, 1=Rot, 2=StrW, 3=R, 4=G, 5=B, 6=A
  // NOTE: This is fragile if setupUI changes order.
  // Better to look them up or store references.
  // For now, based on setupUI:
  // sliders[0] = Size
  // sliders[1] = Rotation
  // sliders[2] = Stroke W
  // sliders[3] = Red
  // sliders[4] = Green
  // sliders[5] = Blue
  // sliders[6] = Alpha
  
  float r = sliders.get(3).value;
  float g = sliders.get(4).value;
  float b = sliders.get(5).value;
  float a = sliders.get(6).value;
  color c = color(r, g, b, a);
  
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
      if (applyToAll || w.isSelected) {
        if (editStroke) {
          w.setStrokeColor(c);
        } else {
          w.setFillColor(c);
        }
      }
    }
  }
}

void randomizeAll() {
  synchronized(windows) {
    for (ProjectionWindow w : windows) {
       w.setShapeType(int(random(6)));
       w.setShapeSize(random(20, 200));
       w.setRotation(random(TWO_PI));
       w.setFillColor(color(random(255), random(255), random(255), random(100, 200)));
    }
  }
}