#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

use stefans_libs::flexible_data_structures::data_table;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $data_table = data_table->new();
my ( $exp, $value, @values, $temp );
my $includes = "-I " . join( " -I ", @INC );
my $path     = $plugin_path . "/data";
my $outpath  = "$path/output";

#system("rm -R $path/output ");
mkdir($path)    unless ( -d $path );
mkdir($outpath) unless ( -d $outpath );

foreach ("$outpath/Summary_Table.xls") {
	unlink($_) if ( -f $_ );
}

my @infiles;
foreach (
	qw(B/Tables/0000.xls
	C/GeneListA/Tables/0000.xls
	C/GeneListB/Tables/0000.xls
	A/Tables/0000.xls)
  )
{
	ok( -f "$outpath/$_", "infile $_" );
	push( @infiles, "$outpath/$_" );
}

system(
	    "perl $includes $plugin_path/../bin/create_summary_table.pl "
	  . " -infiles  "
	  . join( " ", @infiles )
	  . " -outfile $outpath/Summary_Table"

	  #	  . " > /dev/null 2> /dev/null"
);

foreach (
	qw(
	Summary_Table.xls
	Summary_Table.log
	)
  )

{
	is_deeply( -f "$outpath/$_", 1, "outfile $_" );
}
$data_table->read_file("$outpath/Summary_Table.xls");
#print "\$exp = "
#  . root->print_perl_var_def( [ split( /[\t]/, $data_table->AsString() ) ] )
#  . ";\n";
$exp = [ '#Pathway', 'mean p value', 'times identified', 'B output', 'GeneListA C', 'GeneListB C', 'A output
\href{some other web pageGCK}{negative pathway}', '1.0E-03', '1', '1.0E-03', 'n.s.', 'n.s.', 'n.s.
\href{some web page}{positive pathway with a ridiculousely long name that is really hard to get into a table}', '4.8E-03', '3', 'n.s.', '3.4E-03', '7.5E-03', '3.4E-03
' ];

is_deeply( [ split( /[\t]/, $data_table->AsString() ) ],
	$exp, 'The right results' );
#print "\$exp = " . root->print_perl_var_def( $data_table->{'data'} ) . ";\n";
$exp = [ [ '\href{some other web pageGCK}{negative pathway}', '1.0E-03', '1', '1.0E-03', 'n.s.', 'n.s.', 'n.s.' ], [ '\href{some web page}{positive pathway with a ridiculousely long name that is really hard to get into a table}', '4.8E-03', '3', 'n.s.', '3.4E-03', '7.5E-03', '3.4E-03' ] ];

is_deeply ($data_table->{'data'}, $exp, "Right values" );

#print "\$exp = " . root->print_perl_var_def( $value ) . ";\n";
