
var fs = require('fs');
var path = require('path');
var util = require('util');

var meta = [];
var header = ['type','id','place','admin_level','name','population','id_in'].join('\t');
var format = ['%s','%d','%s','%s','%s','%s','%s'].join('\t');

// find all geojson files recursively
function walk( dir ){
  var results = [];
  var list = fs.readdirSync( dir );
  list.forEach( function( file ){
    var fullpath = path.join( dir, file );
    var stat = fs.statSync( fullpath );
    if( !stat ){ return; }
    if( stat.isFile() && '.geojson' === path.extname( fullpath ) ){ results.push( fullpath ); }
    else if( stat.isDirectory() ){ results = results.concat( walk( fullpath ) ); }
  });
  return results;
}

// parse each geojson file and extract meta data
walk( path.resolve( __dirname, './data/' ) ).forEach( function( file ){
  // console.error( file );
  var geojson = parse( file );
  var i = info( geojson );
  i.file = file;
  meta.push( i );
});

// sort ids numerically ASC
meta.sort( function( a, b ){
  return a.id - b.id;
});

// write out
console.log( header );
process.stdout.write( meta.map( serialize ).join( '\n' ) );

// serialize meta data memo
function serialize( memo ){
  return util.format( format, memo.type, memo.id,
    JSON.stringify( memo.place || '' ),
    memo.level || '',
    JSON.stringify( memo.name || '' ),
    memo.population || '',
    JSON.stringify( memo.is_in || '' )
  );
}

// extract info from geojson feature
function info( feat ){

  var prop = feat.properties;
  if( !prop || prop.type !== 'relation' ){ return {}; }

  var tags = prop.tags || {};
  if( !tags.hasOwnProperty('admin_level') ){
    console.error( 'missing admin_level' );
  }

  return {
    type: prop.type,
    id: parseInt( prop.id, 10 ),
    place: tags.place,
    level: tags.admin_level,
    name: tags.name,
    population: tags.population,
    is_in: tags.is_in
  };
}

// json parser
function parse( path ){
  return JSON.parse( fs.readFileSync( path, 'utf8' ) );
}
