interface Action { void execute(); }
interface ToggleAction { void execute(boolean val); }
interface SliderAction { void execute(float val); }

class Button {
  String label; float x, y, w, h; Action action;
  Button(String label, float x, float y, float w, float h, Action action) {
    this.label = label; this.x = x; this.y = y; this.w = w; this.h = h; this.action = action;
  }
  void draw() {
    fill(100); stroke(255);
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
  boolean state = false;
  String labelTrue;
  ToggleAction toggleAction;
  Toggle(String labelFalse, String labelTrue, float x, float y, float w, float h, ToggleAction action) {
    super(labelFalse, x, y, w, h, null);
    this.labelTrue = labelTrue;
    this.toggleAction = action;
  }
  void draw() {
    fill(state ? 0 : 100); stroke(255); if(state) fill(0, 100, 0);
    rect(x, y, w, h);
    fill(255); textAlign(CENTER, CENTER);
    text(state ? labelTrue : label, x + w/2, y + h/2);
  }
  void mousePressed(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      state = !state;
      toggleAction.execute(state);
    }
  }
}

class Slider {
  String label; float min, max, value; float x, y, w, h; SliderAction action;
  Slider(String label, float min, float max, float val, float x, float y, float w, float h, SliderAction action) {
    this.label = label; this.min = min; this.max = max; this.value = val;
    this.x = x; this.y = y; this.w = w; this.h = h; this.action = action;
  }
  void draw() {
    fill(80); noStroke();
    rect(x, y, w, h);
    float pos = map(value, min, max, x, x + w);
    fill(150);
    rect(x, y, pos - x, h);
    fill(255);
    rect(pos - 2, y, 4, h);
    textAlign(LEFT, CENTER);
    fill(255);
    text(label + ": " + nf(value, 0, 1), x + 5, y + h/2);
  }
  void mousePressed(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      value = map(mx, x, x + w, min, max);
      action.execute(value);
    }
  }
  void mouseDragged(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      value = map(mx, x, x + w, min, max);
      action.execute(value);
    }
  }
}