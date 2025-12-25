interface Action { void execute(); }
interface ToggleAction { void execute(boolean val); }
interface SliderAction { void execute(float val); }
interface StateChecker { boolean isActive(); }
interface ValueGetter { float getValue(); }

class Button {
  String label; float x, y, w, h; 
  Action action;
  StateChecker activeCheck; // Optional: If provided, determines visual "pressed/active" state

  Button(String label, float x, float y, float w, float h, Action action) {
    this.label = label; this.x = x; this.y = y; this.w = w; this.h = h; this.action = action;
  }
  
  // Chainable setter for state checker
  Button setActiveCheck(StateChecker check) {
    this.activeCheck = check;
    return this;
  }

  void draw() {
    boolean isActive = (activeCheck != null) ? activeCheck.isActive() : false;
    
    if (isActive) {
      fill(0, 100, 0); // Active Green
      stroke(255);
    } else {
      fill(50); // Inactive Grey
      stroke(150);
    }
    
    rect(x, y, w, h);
    fill(255); textAlign(CENTER, CENTER);
    text(label, x + w/2, y + h/2);
  }
  
  void mousePressed(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
       if (action != null) action.execute();
    }
  }
}

class Toggle extends Button {
  // Toggle doesn't need internal state if it has a StateChecker!
  // But for compatibility with existing code that might not provide one, we keep 'internalState'.
  boolean internalState = false;
  String labelTrue;
  ToggleAction toggleAction;
  
  Toggle(String labelFalse, String labelTrue, float x, float y, float w, float h, ToggleAction action) {
    super(labelFalse, x, y, w, h, null);
    this.labelTrue = labelTrue;
    this.toggleAction = action;
  }
  
  // Override draw to use state
  void draw() {
    // If external checker exists, use it. Else use internal.
    boolean state = (activeCheck != null) ? activeCheck.isActive() : internalState;
    
    if (state) {
      fill(0, 100, 0); // Green/Active
      stroke(255);
    } else {
      fill(50); // Dark/Inactive
      stroke(150);
    }
    
    rect(x, y, w, h);
    fill(255); textAlign(CENTER, CENTER);
    text(state ? labelTrue : label, x + w/2, y + h/2);
  }
  
  void mousePressed(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      // Determine current state to flip it
      boolean currentState = (activeCheck != null) ? activeCheck.isActive() : internalState;
      boolean newState = !currentState;
      
      internalState = newState; // Update internal just in case
      if (toggleAction != null) toggleAction.execute(newState);
    }
  }
}

class Slider {
  String label; float min, max, value; float x, y, w, h; 
  SliderAction action;
  ValueGetter valueGetter; // Optional: Pull value from external source

  Slider(String label, float min, float max, float val, float x, float y, float w, float h, SliderAction action) {
    this.label = label; this.min = min; this.max = max; this.value = val;
    this.x = x; this.y = y; this.w = w; this.h = h; this.action = action;
  }
  
  Slider setValueGetter(ValueGetter getter) {
    this.valueGetter = getter;
    return this;
  }

  void draw() {
    // If getter exists, update value
    if (valueGetter != null) {
      value = valueGetter.getValue();
    }
    
    fill(30); stroke(100);
    rect(x, y, w, h);
    
    float constrainedVal = constrain(value, min, max);
    float pos = map(constrainedVal, min, max, x, x + w);
    
    fill(100); noStroke();
    rect(x, y, pos - x, h);
    
    fill(255);
    rect(pos - 2, y, 4, h);
    
    textAlign(LEFT, CENTER);
    fill(255);
    text(label + ": " + nf(value, 0, 2), x + 5, y + h/2);
  }
  
  void mousePressed(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      updateValue(mx);
    }
  }
  
  void mouseDragged(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      updateValue(mx);
    }
  }
  
  void updateValue(float mx) {
    value = map(mx, x, x + w, min, max);
    if (action != null) action.execute(value);
  }
}