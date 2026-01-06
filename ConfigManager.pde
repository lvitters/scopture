class ConfigManager {
  PApplet parent;
  
  ConfigManager(PApplet p) {
    this.parent = p;
  }
  
  void saveSettings(ArrayList<ProjectionWindow> windows, String filename) {
    synchronized(windows) {
      JSONArray jsonWindows = new JSONArray();
      
      for (int i = 0; i < windows.size(); i++) {
        ProjectionWindow w = windows.get(i);
        JSONObject obj = new JSONObject();
        obj.setInt("id", w.id);
        obj.setFloat("x", w.x); 
        obj.setFloat("y", w.y); 
        obj.setFloat("radius", w.radius);
        
        jsonWindows.setJSONObject(i, obj);
      }
      
      parent.saveJSONArray(jsonWindows, filename);
      PApplet.println("Saved settings to " + filename);
    }
  }
  
  void loadSettings(ArrayList<ProjectionWindow> windows, String filename) {
    synchronized(windows) {
      try {
        JSONArray jsonWindows = parent.loadJSONArray(filename);
        if (jsonWindows == null) {
           PApplet.println("File not found or empty: " + filename);
           return;
        }
        windows.clear();
        
        for (int i = 0; i < jsonWindows.size(); i++) {
          JSONObject obj = jsonWindows.getJSONObject(i);
          int id = obj.getInt("id");
          float x = obj.getFloat("x");
          float y = obj.getFloat("y");
          float r = obj.getFloat("radius");
          
          ProjectionWindow w = new ProjectionWindow(id, x, y, r);
          windows.add(w);
        }
        PApplet.println("Loaded settings from " + filename);
      } catch (Exception e) {
        PApplet.println("Could not load settings: " + e.getMessage());
      }
    }
  }
}