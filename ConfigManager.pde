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
        obj.setInt("controlMode", w.controlMode);
        
        JSONObject shapeObj = new JSONObject();
        shapeObj.setInt("type", w.shape.currentShapeType);
        
        // Save Targets (Manual settings)
        shapeObj.setFloat("size", w.tShapeSize); 
        shapeObj.setFloat("rotSpeed", w.tRotationSpeed);
        shapeObj.setInt("color", w.tColor); 
        shapeObj.setBoolean("isFilled", w.isFilled);
        shapeObj.setFloat("strokeWeight", w.tStrokeWeightVal);
        shapeObj.setFloat("contentX", w.tContentX);
        shapeObj.setFloat("contentY", w.tContentY);
        shapeObj.setFloat("autoPosScale", w.autoPosScale);
        shapeObj.setFloat("autoSizeScale", w.autoSizeScale);
        
        obj.setJSONObject("shape", shapeObj);
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
          
          if (obj.hasKey("controlMode")) w.controlMode = obj.getInt("controlMode");
          
          if (obj.hasKey("shape")) {
            JSONObject shapeObj = obj.getJSONObject("shape");
            w.setShapeType(shapeObj.getInt("type"));
            
            w.tShapeSize = shapeObj.getFloat("size");
            w.tRotationSpeed = shapeObj.getFloat("rotSpeed");
            if (shapeObj.hasKey("color")) w.tColor = shapeObj.getInt("color");
            if (shapeObj.hasKey("isFilled")) w.isFilled = shapeObj.getBoolean("isFilled");
            w.tStrokeWeightVal = shapeObj.getFloat("strokeWeight");
            w.tContentX = shapeObj.getFloat("contentX");
            w.tContentY = shapeObj.getFloat("contentY");
            if (shapeObj.hasKey("autoPosScale")) w.autoPosScale = shapeObj.getFloat("autoPosScale");
            if (shapeObj.hasKey("autoSizeScale")) w.autoSizeScale = shapeObj.getFloat("autoSizeScale");
            
            // Snap currents
            w.shapeSize = w.tShapeSize;
            w.rotationSpeed = w.tRotationSpeed;
            w.cColor = w.tColor;
            w.strokeWeightVal = w.tStrokeWeightVal;
            w.contentX = w.tContentX;
            w.contentY = w.tContentY;
            
            w.shape.calculateTargetVertices(w.shape.currentShapeType);
            for(int k=0; k<w.shape.vertexCount; k++) {
               w.shape.vertices.set(k, w.shape.targetVertices.get(k).copy());
            }
          }
          
          windows.add(w);
        }
        PApplet.println("Loaded settings from " + filename);
      } catch (Exception e) {
        PApplet.println("Could not load settings: " + e.getMessage());
      }
    }
  }
}