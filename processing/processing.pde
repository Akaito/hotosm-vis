String[] csvLines;
float minLat = 0.0f;
float minLon = 0.0f;
float maxLat = 0.0f;
float maxLon = 0.0f;
int   myOutputWidth  = 1366;
int   myOutputHeight = 768;

void setup() {
  size(1366, 768);
  csvLines = loadStrings("nodes.csv");
  
  int lineCount = csvLines.length;
  for (int i = 1; i < lineCount; ++i) {
    // 0: timestamp, 1: wayId, 2: nodeId, 3: lat, 4: lon
    String[] fields = split(csvLines[i], ',');
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
}

void draw() {
  // draw nodes as points
  noSmooth();
  
  for (int i = 1; i < csvLines.length; ++i) {
    // 0: timestamp, 1: wayId, 2: nodeId, 3: lat, 4: lon
    String[] fields = split(csvLines[i], ',');
    float latPercent = (maxLat - Float.parseFloat(fields[3])) / (maxLat - minLat);
    float lonPercent = (maxLon - Float.parseFloat(fields[4])) / (maxLon - minLon);
    float x = latPercent * myOutputWidth;
    float y = lonPercent * myOutputHeight;

    point(x, y);
  }
}