String[] hotosmCsvLines;
String[] nothotosmCsvLines;
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


String[] GetNodes (String path) {
  String[] result = loadStrings(path);
  
  int lineCount = result.length;
  for (int i = 1; i < lineCount; ++i) {
    // 0: timestamp, 1: wayId, 2: nodeId, 3: lat, 4: lon
    String[] fields = split(result[i], ',');
    float lat = Float.parseFloat(fields[3]);
    float lon = Float.parseFloat(fields[4]);
    if (lat < minLat || minLat == 0.0f)
      minLat = lat;
    if (lat > maxLat || maxLat == 0.0f)
      maxLat = lat;
    if (lon < minLon || minLon == 0.0f)
      minLon = lon;
    if (lon > maxLon || maxLon == 0.0f)
      maxLon = lon;
  }
  
  return result;
}


void DrawNode (String csvLine) {
  // 0: timestamp, 1: wayId, 2: nodeId, 3: lat, 4: lon
    String[] fields = split(csvLine, ',');
    float lat = Float.parseFloat(fields[3]);
    float lon = Float.parseFloat(fields[4]);
    float x = XFromLon(lon);
    float y = YFromLat(lat);
    
    point(x, y);
}


void DrawNodes (String[] csvLines) {
  for (int i = 1; i < csvLines.length; ++i) {
    DrawNode(csvLines[i]);
  }
}


void update() {
  ++frame;
}


void setup() {
  size(1366, 768);
  noSmooth();
  colorMode(RGB, 1.0);
  hotosmCsvLines    = GetNodes("nodes-hotosm.csv");
  nothotosmCsvLines = GetNodes("nodes-not-hotosm.csv");
  
  float screenFitScale = min(
    width / (maxLon - minLon),
    height / (maxLat - minLat)
  );
  print(minLon, maxLon, screenFitScale, '\n');
  print(minLat, maxLat, '\n');
  myOutputWidth = (maxLon - minLon) * screenFitScale;
  myOutputHeight = (maxLat - minLat) * screenFitScale;
  //myOutputWidth = 1366; myOutputHeight = 786;
}


void draw() {
  // draw osm nodes as points
  if (frame == 0) {
    // draw border
    stroke(0, 0, 0.5);
    stroke(0, 0, 0);
    DrawNodes(nothotosmCsvLines);
    stroke(1, 0, 1);
    DrawNodes(hotosmCsvLines);
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