
data dump of openstreetmap boundaries in geojson format

#### what is this?

an export of all the openstreetmap 'relation' elements with a 'boundary:administrative' tag in geojson format.

eg: https://github.com/missinglink/osm-boundaries/blob/master/data/004/266/321/004266321.geojson

#### can I see a summary of what's included?

see `meta.tsv`.

#### how can I search for a specific place?

search the meta data (fast):

```bash
$ grep -i "Prenzlauer Berg" meta.tsv
Prenzlauer Berg	relation	407713	000/407/713/000407713.geojson	10suburb

$ grep -i "united states of america" meta.tsv
United States of America	relation	148838	000/148/838/000148838.geojson	2		
```

search the geojson data (slow):

```bash
$ find data -type f -exec grep -il "Prenzlauer Berg" {} +
data/000/407/713/000407713.geojson
```

#### some tags I want are not in the tsv file, can I add them?

yes, you can edit `meta.js`.

#### when was this produced?

see `last_modified.txt`.

#### how was this produced?

the latest planet.pbf file was downloaded directly from the openstreetmap servers.

the file was parsed using a golang pbf parser, a combination of bitmasks and a leveldb were used to mitigate RAM requirements.

the geojson is then produced using a nodejs process running scripts from https://github.com/tyrasd/osmtogeojson.

#### can I use this data to do point-in-polygon lookups?

there is an included script which can be used to build a spatialite database.

in order to build it yourself you'll need to compile some recent versions of the libs, I uploaded a copy to s3 which you can download and should work fine with older versions of spatialite and sqlite3.

download here (warning: 2GB): http://missinglink.files.s3.amazonaws.com/boundaries.sqlite3.gz

use it like this:

```bash
$ sqlite3 boundaries.sqlite3

sqlite> SELECT load_extension('mod_spatialite');
sqlite> .timer on
sqlite> SELECT * FROM boundary WHERE within( GeomFromText('POINT( 13.402247 52.50952 )', 4326), boundary.geom );

16347|Mitte|9|borough|
16566|Mitte|10|suburb|
51477|Deutschland|2||
62422|Berlin|4|state|
Run Time: real 3.871 user 3.188000 sys 0.680000
```

use the rtree index to speed up query execution ~35x:

```bash
$ sqlite3 boundaries.sqlite3

sqlite> SELECT load_extension('mod_spatialite');
sqlite> .timer on
sqlite> SELECT boundary.* FROM box JOIN boundary on box.id = boundary.id
WHERE ( minX<=13.402247 AND maxX>=13.402247 AND minY<=52.50952 AND maxY>=52.50952 )
AND within( GeomFromText('POINT( 13.402247 52.50952 )', 4326 ), boundary.geom );

51477|Deutschland|2||
16566|Mitte|10|suburb|
62422|Berlin|4|state|
16347|Mitte|9|borough|
Run Time: real 0.113 user 0.116000 sys 0.000000
```

#### how many records are in the sqlite database?

```bash
sqlite> SELECT COUNT(*) FROM boundary;
392355
```

#### can I have the code that produced this?

yes, it's currently not published here but if you want it just ask and I'll publish it.

#### can I submit a pull request?

for the data? no. this repo should be considered read-only, all edits must be made to openstreetmap directly.

for the code? yes, please do.

#### license

```
OpenStreetMap® is open data, licensed under the Open Data Commons Open Database License (ODbL) by the OpenStreetMap Foundation (OSMF).

You are free to copy, distribute, transmit and adapt our data, as long as you credit OpenStreetMap and its contributors. If you alter or build upon our data, you may distribute the result only under the same licence. The full legal code explains your rights and responsibilities.
```

all data in this repository is © OpenStreetMap contributors, the data is available under the Open Database Licence.

see: http://www.openstreetmap.org/copyright
