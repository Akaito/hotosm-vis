import java.util.Map;

String[] csvLines;
HashMap<String,Integer> csvColumns = new HashMap<String,Integer>();
float minLat = 0.0f;
float minLon = 0.0f;
float maxLat = 0.0f;
float maxLon = 0.0f;
float myOutputWidth  = 0.0f;
float myOutputHeight = 0.0f;

int frame = 0;


float XFromLon(float lon) {
  float percent = (maxLon - lon) / (maxLon - minLon);
  return percent * myOutputWidth + (width - myOutputWidth) / 2;
}


float YFromLat(float lat) {
  float percent = (maxLat - lat) / (maxLat - minLat);
  return percent * myOutputHeight + (height - myOutputHeight) / 2;
}


void GetNodes (String path) {
  csvLines = loadStrings(path);
  
  // figure out CSV columns
  String[] columnNames = split(csvLines[0], ',');
  for (int i = 0; i < columnNames.length; ++i)
    csvColumns.put(columnNames[i], i);
  
  int latCol = csvColumns.get("lat");
  int lonCol = csvColumns.get("lon");
  int lineCount = csvLines.length;
  for (int i = 1; i < lineCount; ++i) {
    String[] fields = split(csvLines[i], ',');
    float lat = Float.parseFloat(fields[latCol]);
    float lon = Float.parseFloat(fields[lonCol]);
    if (lat < minLat || minLat == 0.0f)
      minLat = lat;
    if (lat > maxLat || maxLat == 0.0f)
      maxLat = lat;
    if (lon < minLon || minLon == 0.0f)
      minLon = lon;
    if (lon > maxLon || maxLon == 0.0f)
      maxLon = lon;
  }
}


void DrawNode (float lat, float lon) {
  float x = XFromLon(lon);
  float y = YFromLat(lat);
  point(x, y);
}


void DrawNodes (String[] csvLines) {
  int isHotosmCol = csvColumns.get("isHotosm");
  int latCol      = csvColumns.get("lat");
  int lonCol      = csvColumns.get("lon");
  
  for (int i = 1; i < csvLines.length; ++i) {
    String[] fields   = split(csvLines[i], ',');
    boolean  isHotosm = fields[isHotosmCol].equals("1");
    if (isHotosm)
      stroke(1, 0, 0);
    else
      stroke(0, 0, 0);
    DrawNode(
      Float.parseFloat(fields[latCol]),
      Float.parseFloat(fields[lonCol])
    );
  }
}


void DrawBuilding (FloatList pointsX, FloatList pointsY, boolean isHotosm) {
  if (isHotosm)
    stroke(0, 0, 1);
  else
    stroke(0, 0, 0.25);
    
  strokeWeight(1);
  beginShape();
  
  int lineCount = pointsX.size();
  for (int i = 0; i < lineCount; ++i) {
    float x = pointsX.get(i);
    float y = pointsY.get(i);
    
    vertex(x, y);
  }
  endShape(CLOSE);
}


//float biggestDistEver = 0.0f;
void DrawPath (FloatList pointsX, FloatList pointsY, boolean isHotosm) {
  if (isHotosm)
    stroke(1, 0, 0);
  else
    stroke(0.25, 0, 0);
    
  strokeWeight(1);
  int lineCount = pointsX.size();
  for (int i = 0; i+1 < lineCount; ++i) {
    float x1 = pointsX.get(i);
    float y1 = pointsY.get(i);
    float x2 = pointsX.get(i+1);
    float y2 = pointsY.get(i+1);
    float distSq = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
    /*
    if (distSq > biggestDistEver) {
      biggestDistEver = distSq;
      println('\t', distSq);
    }
    */
    
    // dumb hack to try and avoid "scribbly" paths with bad nodes/positions 
    if (distSq > 1000.0)
      continue;
    line(x1, y1, x2, y2);
  }
}


void DrawWays (String[] csvLines) {
  int isHotosmCol   = csvColumns.get("isHotosm");
  int latCol        = csvColumns.get("lat");
  int lonCol        = csvColumns.get("lon");
  int wayCol        = csvColumns.get("wayId");
  int isBuildingCol = csvColumns.get("isBuilding");
  int isPathCol     = csvColumns.get("isPath");
  
  int       lastWayId      = 0;
  boolean   lastIsBuilding = false;
  boolean   lastIsPath     = false;
  FloatList pointsX        = new FloatList();
  FloatList pointsY        = new FloatList();
  for (int i = 1; i < csvLines.length; ++i) {
    String[] fields    = split(csvLines[i], ',');
    boolean isHotosm   = fields[isHotosmCol].equals("1");
    boolean isBuilding = fields[isBuildingCol].equals("1");
    boolean isPath     = fields[isPathCol].equals("1");
    int     wayId      = Integer.parseInt(fields[wayCol]);
    float   lat        = Float.parseFloat(fields[latCol]);
    float   lon        = Float.parseFloat(fields[lonCol]);
    
    float x = XFromLon(lon);
    float y = YFromLat(lat);
    
    if (wayId != lastWayId) {
      if (lastIsBuilding) {
        DrawBuilding(pointsX, pointsY, isHotosm);
      }
      else if (lastIsPath) {
        DrawPath(pointsX, pointsY, isHotosm);
      }
      pointsX.clear();
      pointsY.clear();
    }
    
    pointsX.append(x);
    pointsY.append(y);
    
    lastWayId = wayId;
    lastIsBuilding = isBuilding;
    lastIsPath = isPath;
  }
}


void update() {
  ++frame;
}


void setup() {
  //size(2048, 2048);
  size(4096, 4096);
  noSmooth();
  colorMode(RGB, 1.0);
  GetNodes("nodes.csv");
  
  float screenFitScale = min(
    width / (maxLon - minLon),
    height / (maxLat - minLat)
  );
  myOutputWidth = (maxLon - minLon) * screenFitScale;
  myOutputHeight = (maxLat - minLat) * screenFitScale;
}


void draw() {
  // draw osm nodes as points
  if (frame == 0) {
    //DrawNodes(csvLines);
    DrawWays(csvLines);
    
    if (width >= 4096)
      save("output.png");
  }
  
  // draw hotosm nodes over time
  /*
  if (frame > 0 && frame < hotosmCsvLines.length) {
    stroke(1, 0, 1);
    DrawNode(hotosmCsvLines[frame]);
  }
  */
  
  update();
}