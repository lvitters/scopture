import java.util.ArrayList;

public class OutputFrame extends PApplet {
  int w, h;
  ArrayList<ProjectionWindow> windows;
  
  // Animation State References (local copies or access to parent? 
  // It's better if the parent passes updated windows, but windows store their own state.
  // The 'update' is called in main loop. Here we just draw.
  
  public OutputFrame(int _w, int _h, ArrayList<ProjectionWindow> _windows) {
    w = _w;
    h = _h;
    windows = _windows;
  }
  
  public void settings() {
    size(w, h, P2D); // Standard projector resolution usually
  }
  
  public void setup() {
    surface.setTitle("Output Projection");
    colorMode(HSB, 360, 100, 100);
  }
  
  public void draw() {
    background(0);
    
    // We assume 'windows' are updated in the main sketch.
    // We just draw them here.
    
    synchronized(windows) {
      for (ProjectionWindow w : windows) {
        // Draw decorations ONLY if one of the transformation modes is active
        boolean showDecorations = w.isKeystoning || w.isResizable || w.isDraggable;
        w.draw(this.g, showDecorations);
      }
    }
  }
}