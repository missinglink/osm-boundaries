#!/bin/bash
# set -e;
export LC_ALL=en_US.UTF-8;

# location of this file in filesystem
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd );

# location of sqlite database file
DB="$DIR/boundaries.sqlite3";

# note: this required you compile the latest version of libspatialite
# see: https://www.gaia-gis.it/fossil/libspatialite/tktview?name=74ba14876c

# note: this requires that sqlite3 is compiled with the json1 extension
# example: ./configure --enable-json1;

# set up a new database
function setup(){
  sqlite3 $DB <<SQL
SELECT load_extension('/usr/local/lib/mod_spatialite');
SELECT InitSpatialMetaData(1);
CREATE TABLE boundary (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  level INTEGER,
  place TEXT
);
SELECT AddGeometryColumn('boundary', 'geom', 4326, 'GEOMETRY', 'XY', 1);
CREATE VIRTUAL TABLE box USING rtree(
   id INTEGER NOT NULL PRIMARY KEY,
   minX REAL, maxX REAL,
   minY REAL, maxY REAL
);
SQL
}

# json - print a json property from file
# $1: geojson path: eg. '/tmp/test.geojson'
# $2: property to extract: eg. '$.geometry'
function json(){
  sqlite3 $DB <<SQL
SELECT load_extension('/usr/local/lib/mod_spatialite');
WITH file AS ( SELECT readfile('$1') as json )
SELECT json_extract( (SELECT json FROM file), '$2' );
SQL
}

# index - add a geojson polygon to the database
# $1: geojson path: eg. '/tmp/test.geojson'
function index(){
  echo $1;
  sqlite3 $DB <<SQL
SELECT load_extension('/usr/local/lib/mod_spatialite');
WITH file AS ( SELECT readfile('$1') AS json )
INSERT INTO boundary ( id, name, level, place, geom )
VALUES (
  json_extract((SELECT json FROM file), '$.properties.id'),
  json_extract((SELECT json FROM file), '$.properties.tags.name'),
  json_extract((SELECT json FROM file), '$.properties.tags.admin_level'),
  json_extract((SELECT json FROM file), '$.properties.tags.place'),
  SetSRID( GeomFromGeoJSON( json_extract((SELECT json FROM file), '$.geometry') ), 4326 )
);
SQL
}

# bboxify - create the rtree index required by the 'pipfast' function
function bboxify(){
  sqlite3 $DB <<SQL
SELECT load_extension('/usr/local/lib/mod_spatialite');
INSERT INTO box ( id, minX, maxX, minY, maxY )
SELECT id, MbrMinX(geom), MbrMaxX(geom), MbrMinY(geom), MbrMaxY(geom)
FROM boundary;
SQL
}

# index_all - add all geojson polygons in $1 to the database
# $1: data path: eg. '/tmp/polygons'
function index_all(){
  find "$1" -type f -name '*.geojson' -print0 | while IFS= read -r -d $'\0' file; do
    index $file;
  done
}

# pip - point-in-polygon test
# $1: longitude: eg. '151.5942043'
# $2: latitude: eg. '-33.013441'
function pip(){
  sqlite3 $DB <<SQL
SELECT load_extension('/usr/local/lib/mod_spatialite');
SELECT * FROM boundary
WHERE within( GeomFromText('POINT( $1 $2 )', 4326 ), boundary.geom );
SQL
}

# pipfast - point-in-polygon test optimized with an rtree index
# $1: longitude: eg. '151.5942043'
# $2: latitude: eg. '-33.013441'
function pipfast(){
  sqlite3 $DB <<SQL
SELECT load_extension('/usr/local/lib/mod_spatialite');
SELECT * FROM box JOIN boundary on box.id = boundary.id
WHERE ( minX<=$1 AND maxX>=$1 AND minY<=$2 AND maxY>=$2 )
AND within( GeomFromText('POINT( $1 $2 )', 4326 ), boundary.geom );
SQL
}

# setup;
# index_all "$DIR/data";
# bboxify;

# berlin test data
# index '/data/boundaries/data/000/016/347/000016347.geojson';
# index '/data/boundaries/data/000/016/566/000016566.geojson';
# index '/data/boundaries/data/000/051/477/000051477.geojson';
# index '/data/boundaries/data/000/062/422/000062422.geojson';
# pip '13.402247' '52.50952';
# bboxify;
# pipfast '13.402247' '52.50952';

# 16347|Mitte|9|borough|
# 16566|Mitte|10|suburb|
# 51477|Deutschland|2||
# 62422|Berlin|4|state|
