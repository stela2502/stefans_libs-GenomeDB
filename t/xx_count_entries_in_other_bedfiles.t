#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;
use Test::More tests => 7;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $outfile, $infile, @mapp_to, );

my $exec = $plugin_path . "/../bin/count_entries_in_other_bedfiles.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/count_entries_in_other_bedfiles";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$infile = "$plugin_path/data/input.bed";
ok( -f $infile, "infile $infile" );
foreach ( 1, 2, 3 ) {
	$mapp_to[ $_ - 1 ] = "$plugin_path/data/merge_to_$_.bed";
	ok( -f $infile, "mapp_to $_ " . $mapp_to[ $_ - 1 ] );
}

$outfile = "$outpath/output.xls";

my $cmd =
    "perl -I $plugin_path/../lib  $exec "
  . " -outfile "
  . $outfile
  . " -infile "
  . $infile
  . " -mapp_to "
  . join( ' ', @mapp_to )
  . " -debug";
my $start = time;
system($cmd );
my $duration = time - $start;
print "Execution time: $duration s\n";

my $file = data_table->new( { filename => $outfile } );

#print "\$exp = " . root->print_perl_var_def( $file->{'data'} ) . ";\n";

$exp = [
	[ 'chr1', '100',  '200',  '', '1', '1', '1' ],
	[ 'chr1', '500',  '600',  '', '1', '1', '1' ],
	[ 'chr1', '900',  '1000', '', '1', '0', '1' ],
	[ 'chr1', '1500', '1600', '', '1', '1', '0' ]
];

is_deeply( $file->{'data'}, $exp, "data" );

#print "\$exp = ".root->print_perl_var_def( $file->{'header'} ).";\n";

$exp = [
	'chromosome', 'start',      'end', 'name',
	'merge_to_1', 'merge_to_2', 'merge_to_3'
];
is_deeply( $file->{'header'}, $exp, "header" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
