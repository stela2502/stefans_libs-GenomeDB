#! /usr/bin/perl
use strict;
use warnings;
use stefans_libs::root;

use Test::More tests => 14;
use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, @files, $outfile, );

my $exec = $plugin_path . "/../bin/Picard_metrix2table.pl";
ok( -f $exec, 'the script has been found' );
my $outpath = "$plugin_path/data/output/Picard_metrix2table";
if ( -d $outpath ) {
	system("rm -Rf $outpath");
}

$outfile = $outpath."/SummaryTable.xls";

@files = ( map{ "$plugin_path/data/picard/$_"}
	"SRR2077088_hisat.sorted_picard_metrix.txt",
	"SRR2077089_hisat.sorted_picard_metrix.txt",
	"SRR2077090_hisat.sorted_picard_metrix.txt",
	"SRR2077091_hisat.sorted_picard_metrix.txt",
	"SRR2077092_hisat.sorted_picard_metrix.txt",
	"SRR2077093_hisat.sorted_picard_metrix.txt",
	"SRR2077094_hisat.sorted_picard_metrix.txt",
	"SRR2077095_hisat.sorted_picard_metrix.txt",
	"SRR2077096_hisat.sorted_picard_metrix.txt",
	"SRR2077097_hisat.sorted_picard_metrix.txt",
);


foreach my $file ( @files ) {
	ok ( -f $file, "file $file" );
}


my $cmd =
    "perl -I $plugin_path/../lib  $exec "
  . " -files "
  . join( ' ', @files )
  . " -outfile "
  . $outfile
  . " -debug";
system($cmd );

my $data_table = data_table->new( {no_doubble_cross=>1,'filename'=>$outfile} );
ok( $data_table->Rows() == 10 , "10 rows in result table" );

is_deeply( $data_table->GetAsArray('filename'), \@files, "filename column contains all files in the right order" );

#print "\$exp = ".root->print_perl_var_def($data_table->GetAsArray('ESTIMATED_LIBRARY_SIZE') ).";\n";
$exp = [ '8026872', '15110538', '431970', '11893186', '14508057', '7438790', '11153843', '501092', '8531211', '1762321' ];

is_deeply( $data_table->GetAsArray('ESTIMATED_LIBRARY_SIZE'), $exp, "ESTIMATED_LIBRARY_SIZE collected" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";
