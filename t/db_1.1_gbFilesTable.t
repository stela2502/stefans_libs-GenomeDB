#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::gbFile;
use Test::More tests => 4;
BEGIN { use_ok 'stefans_libs::database::genomeDB' }


my $gbFilesTable = gbFilesTable -> new(variable_table::getDBH('root', "geneexpress" ));
is_deeply ( ref($gbFilesTable) , 'gbFilesTable', 'simple test of function gbFilesTable -> new()' );

## test for new

my ( $value, @values);

## test for new

## test for TableName

my $genomeDB = genomeDB->new( variable_table::getDBH( ));
$gbFilesTable = $genomeDB->GetDatabaseInterface_for_Organism_and_Version ( 'hu_genome', '36.3');
$gbFilesTable = $gbFilesTable -> get_rooted_to ( 'gbFilesTable');

is_deeply ( $gbFilesTable->TableName(), "hu_genome_36_3_gbFilesTable", "table base name is created correctly");

my $filename = "../t/data/hu_genome/originals/NT_113968.1.gb";
$filename = "t/data/hu_genome/originals/NT_113968.1.gb" if ( -f "t/data/hu_genome/originals/NT_113968.1.gb" );
unless ( -f $filename) { system ( "ls -lh" ); }

my $gbFile = gbFile->new($filename);
$gbFile ->{'features'} = []; ## this database does not read all the features....
$gbFile->{feature_locations} = {};
$gbFile ->{'path'} = $gbFile ->{'filename'} =undef;  ## nore does it know the path or filename...
$gbFile ->{'header'}->{'gbText'} = [split("\n", $gbFile ->{'header'}->{'gbText'})];
$value = $gbFilesTable->getGbfile_obj_for_acc( 'NT_113968.1' );
$value ->{'header'}->{'gbText'} = [split("\n", $value ->{'header'}->{'gbText'})];
is_deeply ($value, $gbFile, "I got the same file from the database and the local file!" );





