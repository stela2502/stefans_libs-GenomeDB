#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 2;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outpath, @options, $infile, );

my $exec = $plugin_path . "/../bin/spike_in_to_chromosomes.pl";
ok( -f $exec, 'the script has been found' );
$outpath = "$plugin_path/data/output/spike_in_to_chromosomes";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$infile = $plugin_path."/data/cms_095047.txt";
ok( -f $infile, "infile exists");

@options = ( 'name_pos', '0', 'seq_pos', '4' );

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
. " -outpath " . $outpath 
. " -options " . join(' ', @options )
. " -infile " . $infile 
. " -debug  2 > /dev/null";
system( $cmd );

opendir ( DIR, $outpath ) or die "could not open the outpath $outpath\n$!\n";
$value = [grep ( /^E/, readdir(DIR) )];
closedir(DIR);
#print "\$exp = ".root->print_perl_var_def($value ).";\n";

$exp = [ 'ERCC-00002.fa', 'ERCC-00003.fa', 'ERCC-00004.fa', 'ERCC-00009.fa', 'ERCC-00012.fa', 'ERCC-00013.fa', 'ERCC-00014.fa', 'ERCC-00016.fa', 'ERCC-00017.fa', 'ERCC-00019.fa', 'ERCC-00022.fa', 'ERCC-00024.fa', 'ERCC-00025.fa', 'ERCC-00028.fa', 'ERCC-00031.fa', 'ERCC-00033.fa', 'ERCC-00034.fa', 'ERCC-00035.fa', 'ERCC-00039.fa', 'ERCC-00040.fa', 'ERCC-00041.fa', 'ERCC-00042.fa', 'ERCC-00043.fa', 'ERCC-00044.fa', 'ERCC-00046.fa', 'ERCC-00048.fa', 'ERCC-00051.fa', 'ERCC-00053.fa', 'ERCC-00054.fa', 'ERCC-00057.fa', 'ERCC-00058.fa', 'ERCC-00059.fa', 'ERCC-00060.fa', 'ERCC-00061.fa', 'ERCC-00062.fa', 'ERCC-00067.fa', 'ERCC-00069.fa', 'ERCC-00071.fa', 'ERCC-00073.fa', 'ERCC-00074.fa', 'ERCC-00075.fa', 'ERCC-00076.fa', 'ERCC-00077.fa', 'ERCC-00078.fa', 'ERCC-00079.fa', 'ERCC-00081.fa', 'ERCC-00083.fa', 'ERCC-00084.fa', 'ERCC-00085.fa', 'ERCC-00086.fa', 'ERCC-00092.fa', 'ERCC-00095.fa', 'ERCC-00096.fa', 'ERCC-00097.fa', 'ERCC-00098.fa', 'ERCC-00099.fa', 'ERCC-00104.fa', 'ERCC-00108.fa', 'ERCC-00109.fa', 'ERCC-00111.fa', 'ERCC-00112.fa', 'ERCC-00113.fa', 'ERCC-00116.fa', 'ERCC-00117.fa', 'ERCC-00120.fa', 'ERCC-00123.fa', 'ERCC-00126.fa', 'ERCC-00130.fa', 'ERCC-00131.fa', 'ERCC-00134.fa', 'ERCC-00136.fa', 'ERCC-00137.fa', 'ERCC-00142.fa', 'ERCC-00143.fa', 'ERCC-00144.fa', 'ERCC-00145.fa', 'ERCC-00147.fa', 'ERCC-00148.fa', 'ERCC-00150.fa', 'ERCC-00154.fa', 'ERCC-00156.fa', 'ERCC-00157.fa', 'ERCC-00158.fa', 'ERCC-00160.fa', 'ERCC-00162.fa', 'ERCC-00163.fa', 'ERCC-00164.fa', 'ERCC-00165.fa', 'ERCC-00168.fa', 'ERCC-00170.fa', 'ERCC-00171.fa' ];

is_deeply( $value, $exp, "all outfiles created" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";