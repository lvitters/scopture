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
        obj.setFloat("x", w.tX); // Save Target X
        obj.setFloat("y", w.tY); // Save Target Y
        obj.setFloat("radius", w.tRadius); // Save Target Radius
        
        JSONObject shapeObj = new JSONObject();
        shapeObj.setInt("type", w.shape.currentShapeType);
        shapeObj.setFloat("size", w.tShapeSize); // Save Target Size
        shapeObj.setFloat("rotation", w.tRotation); // Save Target Rotation
        shapeObj.setInt("strokeColor", w.tStrokeColor); // Save Target Stroke
        shapeObj.setInt("fillColor", w.tFillColor); // Save Target Fill
        shapeObj.setFloat("strokeWeight", w.tStrokeWeight);
        
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
          
          if (obj.hasKey("shape")) {
            JSONObject shapeObj = obj.getJSONObject("shape");
            w.setShapeType(shapeObj.getInt("type"));
            w.setShapeSize(shapeObj.getFloat("size"));
            w.setRotation(shapeObj.getFloat("rotation"));
            w.setStrokeColor(shapeObj.getInt("strokeColor"));
            w.setFillColor(shapeObj.getInt("fillColor"));
            w.setStrokeWeight(shapeObj.getFloat("strokeWeight"));
            
            // Force update of currents to match loaded targets immediately?
            // Or let them lerp?
            // Usually load -> snap.
            w.cX = w.tX; w.cY = w.tY;
            w.cRadius = w.tRadius;
            w.cShapeSize = w.tShapeSize;
            w.cRotation = w.tRotation;
            w.cFillColor = w.tFillColor;
            w.cStrokeColor = w.tStrokeColor;
            w.cStrokeWeight = w.tStrokeWeight;
            
            // Update shape immediately
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