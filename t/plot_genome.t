#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use Digest::MD5;

use FindBin;
my $plugin_path = "$FindBin::Bin";

BEGIN { use_ok 'stefans_libs::database::genomeDB' }
BEGIN { use_ok 'stefans_libs::plot::genomePlot' }
BEGIN { use_ok 'stefans_libs::plot::plottable_gbFile' }
use stefans_libs::file_readers::bedGraph_file;
my ( $value, $exp, @values );
my $figure = stefans_libs_plot_genomePlot->new();
is_deeply( ref($figure), 'stefans_libs_plot_genomePlot', 'create the object' );

## I am going to plot the data from chrY:90..10090
## and am going to add several data types to this plot (all either in bed or bedGraph format)

## Initialize the plotting interface
$figure->GenomeInterface( genomeDB->new( variable_table->getDBH() )
	  ->GetDatabaseInterface_for_Organism_and_Version( 'hu_genome', '36.3' ) );

## Now I need to define a number of areas to plot
## And populate the areas with data
## 1: green information from the ROI database
my $gbFiles_table =
  genomeDB->new( variable_table->getDBH() )
  ->GetDatabaseInterface_for_Organism_and_Version( 'hu_genome', '36.3' )
  ->get_rooted_to('gbFilesTable');

## check whether I could get the chromosomal region
my $chr_region =
  $figure->{'genome'}->get_chromosomal_region( 'Y', 132000, 135000 );
my $str = '';
foreach ( @{ $chr_region->Features() } ) {
	$str .= $_->getAsGB() if ( $_->Tag() eq "gene" );
}
$str = [ split( "\n", $str ) ];
$exp = [
	'     gene            132991..160020',
	'                     /db_xref="GeneID:55344"',
	'                     /db_xref="HGNC:23148"',
	'                     /gene="PLCXD1"',
'                     /note="Derived by automated computational analysis using',
'                     gene prediction method: BestRefseq. Supporting evidence',
	'                     includes similarity to: 1 mRNA"'
];

is_deeply( $str, $exp, 'Got the right chromosomal region' );

#print "\$exp = " . root->print_perl_var_def($str) . ";\n";

$figure->AddDataset(
	$gbFiles_table->Connect_2_result_ROI_table()->get_ROI_as_bed_file(
		{ 'name' => [ '(CCCTAA)n', 'TAR1' ], 'tag' => 'repeat' }
	),
	'green', 'the repeat regions'
);
## 2: red information from a bed file
my $bed_file = stefans_libs_file_readers_bed_file->new();
$bed_file->read_file("$plugin_path/data/temp_data_red.bed");
$figure->AddDataset( $bed_file, 'red', 'A bed file in red' );

## 3: blue information from a bedGraph file
my $bedGraph_file = stefans_libs::file_readers::bedGraph_file->new();
$bedGraph_file->read_file("$plugin_path/data/temp_data_blue.bedGraph");
$figure->AddDataset( $bedGraph_file, 'blue', 'a bedGraph in blue' );
## After that the figure should be free ready to become plotted!
$figure->plot(
	{
		'gbFile'     => $chr_region,
		'chromosome' => 'chrY',
		'start'      => 132500,
		'end'        => 135000,
		'outfile'    => "$plugin_path/data/output_figure.now.svg"
	}
);

is_deeply(
	&md5sum(
"plugin_path/data/output_figure.now.svg"
	),
	&md5sum(
"plugin_path/data/output_figure.OK.svg"
	),
	'figure looks acceptable'
);
print
"You can check the output figure '$plugin_path/data/output_figure.now.svg'\ninkscape $plugin_path/data/output_figure.now.svg\n";

#print "\$exp = ".root->print_perl_var_def($value ).";\n";

sub md5sum {
	my ($file) = @_;
	my $digest = "";
	eval {
		open( FILE, $file ) or die "Can't find file $file\n";
		my $ctx = Digest::MD5->new;
		$ctx->addfile(*FILE);
		$digest = $ctx->hexdigest;
		close(FILE);
	};
	if ($@) {
		print $@;
		return "";
	}
	return $digest;
}
