#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outdir, $version, $organism_name, $referenceTag, $releaseDate, $noDownload, );

my $exec = $plugin_path . "/../bin/get_NCBI_masked_genome.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/get_NCBI_masked_genome";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec.pl "
. " -outdir " . $outdir 
. " -version " . $version 
. " -organism_name " . $organism_name 
. " -referenceTag " . $referenceTag 
. " -releaseDate " . $releaseDate 
. " -noDownload " . $noDownload 
. " -debug";
#print "\$exp = ".root->print_perl_var_def($value ).";\n