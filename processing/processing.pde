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


void DrawWays (String[] csvLines) {
  for (int i = 1; i < csvLines.length; ++i) {
  }
}


void update() {
  ++frame;
}


void setup() {
  size(1366, 1366);
  noSmooth();
  colorMode(RGB, 1.0);
  GetNodes("nodes.csv");
  
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
    DrawNodes(csvLines);
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