
var fs = require('fs');
var path = require('path');
var util = require('util');

var dirs = {
  data: path.resolve( __dirname, './data/' )
};

var meta = [];
var header = ['type','id','place','admin_level','name','population','id_in'].join('\t');
var format = ['%s','%d','%s','%s','%s','%s','%s'].join('\t');

// Loop through all the files in the data directory
fs.readdir( dirs.data, function( err, files ) {

  if( err ) {
    console.error( 'Could not list the directory.', err );
    process.exit( 1 );
  }

  files.forEach( function( file, index ) {

    var fullpath = path.join( dirs.data, file );
    var extension = path.extname(fullpath);

    try {
      var stat = fs.statSync( fullpath );
      if( stat.isFile() && '.geojson' === extension ){
        var geojson = parse(fullpath);
        var i = info(geojson);
        i.file = file;
        console.error( meta.push( i ) );
      }
    }
    catch( e ){
      console.error( 'Error stating file.', e );
    }
  });

  // sort ids numerically ASC
  meta.sort( function( a, b ){
    return a.id - b.id;
  });

  // write out
  console.log( header );
  process.stdout.write( meta.map( serialize ).join( '\n' ) );
});

function serialize( memo ){
  return util.format( format, memo.type, memo.id,
    JSON.stringify( memo.place || '' ),
    memo.level || '',
    JSON.stringify( memo.name || '' ),
    memo.population || '',
    JSON.stringify( memo.is_in || '' )
  );
}

function info( geojson ){

  for( var i=0; i<geojson.features.length; i++ ){

    var feat = geojson.features[i];
    var prop = feat.properties;

    if( !prop || prop.type !== 'relation' ){ continue; }

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
    }
  }

  return {};
}

function parse( path ){
  return JSON.parse( fs.readFileSync( path, 'utf8' ) );
}
