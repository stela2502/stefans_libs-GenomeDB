#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok 'stefans_libs::file_readers::gtf_file' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ($test_object, $value, $exp, @values);
$test_object = stefans_libs::file_readers::gtf_file -> new();
is_deeply ( ref($test_object) , 'stefans_libs::file_readers::gtf_file', 'simple test of function stefans_libs::file_readers::gtf_file -> new()' );

$value = $test_object->AddDataset ( {             'seqname' => 0,
            'source' => 1,
            'feature' => 2,
            'start' => 3,
            'end' => 4,
            'score' => 5,
            'strand' => 6,
            'frame' => 7,
            'attribute' => 'gene_id "GAFFER"; something_else "1 2 3"; and_more "nothing"', } );
is_deeply( $value, 1, "we could add a sample dataset");

#print "\$exp = ".root->print_perl_var_def( [ split(/[\t\n]/,$test_object->AsString() )] ).";\n";
$exp = [ '#', '0', '1', '2', '3', '4', '5', '6', '7', 'gene_id "GAFFER"; something_else "1 2 3"; and_more "nothing"' ];
is_deeply ( [ split(/[\t\n]/,$test_object->AsString() )] , $exp, "data read as expected (test)" );

#$test_object->After_Data_read();

my $infile = "$plugin_path/data/test.gtf";

$test_object = stefans_libs::file_readers::gtf_file -> new();
$test_object->read_file($infile);
$test_object->After_Data_read();
print "\$exp = ".root->print_perl_var_def( $test_object->get_line_asHash(0) ).";\n";

# A handy help if you do not know what you should expect
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

