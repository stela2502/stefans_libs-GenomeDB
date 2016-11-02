#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $bed_file, $organism, $outfile, $version, $feature_name, $feature_tag, $max_distance, );

my $exec = $plugin_path . "/../bin/annotate_bed_like_file.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/annotate_bed_like_file";
if ( -d $outpath ) {
	#system("rm -Rf $outpath");
}
$outfile = $outpath."/annnotation_test_w_gene_info.bed";


warn "This script does only work if the working database contains the NCBI genome H_sapiens ANNOTATION_RELEASE.106\n";

$bed_file = $plugin_path."/data/annotation_test.bed";
$organism = "H_sapiens";
$version = 'ANNOTATION_RELEASE.106';
$max_distance = '500';

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -bed_file " . $bed_file 
. " -organism " . $organism 
#. " -with_header " # or not?
. " -outfile " . $outfile 
. " -version " . $version 
#. " -feature_name " . $feature_name 
#. " -feature_tag " . $feature_tag 
. " -max_distance " . $max_distance 
. " -debug";

system ( $cmd );

ok ( -f $outfile, "The outfile was created" );

my $bed_obj = stefans_libs_file_readers_bed_file->new();
$bed_obj->read_file( $outfile);
print $bed_obj->AsString();

#print "\$exp = ".root->print_perl_var_def($value ).";\n