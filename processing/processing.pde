String[] hotosmCsvLines;
String[] nothotosmCsvLines;
float minLat = 0.0f;
float minLon = 0.0f;
float maxLat = 0.0f;
float maxLon = 0.0f;
int   myOutputWidth  = 1366;
int   myOutputHeight = 768;

int frame = 0;

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
    float latPercent = (maxLat - Float.parseFloat(fields[3])) / (maxLat - minLat);
    float lonPercent = (maxLon - Float.parseFloat(fields[4])) / (maxLon - minLon);
    float x = latPercent * myOutputWidth;
    float y = lonPercent * myOutputHeight;

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
}


void draw() {
  // draw osm nodes as points
  if (frame == 0) {
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