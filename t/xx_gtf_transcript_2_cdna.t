#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outpath, $genome_path, @ids, $gtf, );

my $exec = $plugin_path . "/../bin/gtf_transcript_2_cdna.pl";
ok( -f $exec, 'the script has been found' );
$outpath = "$plugin_path/data/output/gtf_transcript_2_cdna";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$genome_path = $plugin_path."/data/";
$gtf = $genome_path."/CTC1.gtf";



@ids = ("ENST00000578441.5", 'ENST00000449476.6' );
my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -outpath " . $outpath 
. " -genome_path " . $genome_path 
. " -ids " . join(' ', @ids )
. " -gtf " . $gtf 
. " -debug";
system( $cmd );

ok ( -d $outpath, "outpath created" );
ok ( -f "$outpath/gtf_transcript_2_cdna.log", 'log file created') ;

system ( "cat $outpath/ENST00000578441.5.fa");
system ( "cat $outpath/ENST00000578537.1.fa");

use stefans_libs::fastaFile();
my $fastaFile = fastaFile->new();
$fastaFile->read_file ( "$plugin_path/data/CTC1.010.fa" );
my $fasta2 = fastaFile->new();

$fastaFile->write_file ( "$plugin_path/data/CTC1_010.fa" );

#system ( "cat $outpath/gtf.xls");
#print "\$exp = ".root->print_perl_var_def($value ).";\n";