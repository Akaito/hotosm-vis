README
======

Render OpenStreetMap features in different colors, depending on if they're part of a particular HOTOSM project or not.

![Sample Output](https://codesaru.com/hotosm.png)

## How to Use

1. ./get-stuff.py
	Download a few MB of data and cache stuff off locally, trying to be gentle with the APIs being used.
2. mkdir processing/data
3. sqlite3 data/sqlite.db < query-nodes.sql
	Output a CSV into the processing/data directory.
4. Use the processing IDE to open the script in the processing directory, and run it.
5. Take a look at processing/Output.png

## Copyright

OpenStreetMap and its contributors hold the copyright on most or all of the data being retrieved to be used by this project.

