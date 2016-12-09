
data dump of openstreetmap boundaries in geojson format

#### what is this?

an export of all the openstreetmap 'relation' elements with a 'boundary:administrative' tag in geojson format.

eg: https://github.com/missinglink/osm-boundaries/blob/master/data/4266321.geojson

#### can I see a summary of what's included?

see `meta.tsv`.

#### how can I search for a specific place?

search the meta data (fast):

```bash
$ grep -i "Prenzlauer Berg" meta.tsv
relation	407713	"suburb"	10	"Prenzlauer Berg"		""
```

search the geojson data (slow):

```bash
$ find data -type f -exec grep -il "Prenzlauer Berg" {} +
data/407713.geojson
```

#### some tags I want are not in the tsv file, can I add them?

yes, you can edit `meta.js`.

#### when was this produced?

see `last_modified.txt`.

#### how was this produced?

the latest planet.pbf file was downloaded directly from the openstreetmap servers.

the file was parsed using a golang pbf parser, a combination of bitmasks and a leveldb were used to mitigate RAM requirements.

the geojson is then produced using a nodejs process running scripts from https://github.com/tyrasd/osmtogeojson.

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
