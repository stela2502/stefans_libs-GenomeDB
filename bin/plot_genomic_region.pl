#! /usr/bin/perl -w

#  Copyright (C) 2012-10-31 Stefan Lang

#  This program is free software; you can redistribute it
#  and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation;
#  either version 3 of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1 plot_genomic_region.pl

This script can plot any genomic information you want to.

To get further help use 'plot_genomic_region.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;

use stefans_libs::database::genomeDB;
use stefans_libs::plot::genomePlot;
use stefans_libs::plot::plottable_gbFile;
use stefans_libs::file_readers::bedGraph_file;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,    $debug,           $database, $organism,
	$version, @additional_data, @colors,   $chromosome,
	$start,   $end,             $outfile,  @genes
);

Getopt::Long::GetOptions(
	"-organism=s"           => \$organism,
	"-version=s"            => \$version,
	"-additional_data=s{,}" => \@additional_data,
	"-colors=s{,}"          => \@colors,
	"-chromosome=s"         => \$chromosome,
	"-start=s"              => \$start,
	"-end=s"                => \$end,
	"-outfile=s"            => \$outfile,
	"-genes=s{,}"           => \@genes,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $organism ) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version ) {
	$warn .= "the cmd line switch -version is undefined!\n";
}
unless ( defined $additional_data[0] ) {
	$error .= "the cmd line switch -additional_data is undefined!\n";
}
unless ( defined $colors[0] ) {
	$error .= "the cmd line switch -colors is undefined!\n";
}
## there should be two different possibilities:
## (1) look for a chromosomal region $chromosome, $start, $end
## (2) look for a given gene $genes
if ( defined $genes[0] ) {
	if ( -f $genes[0] ) {
		open( IN, "<$genes[0]" )
		  or die "I could not open the genes file '$genes[0]'\n$!\n";
		my @temp;
		while (<IN>) {
			chomp($_);
			push( @temp, split( /\s+/, $_ ) );
		}
		shift(@temp) unless ( defined $temp[0] );
		@genes = @temp;
	}
}
else {
	unless ( defined $chromosome ) {
		$error .= "the cmd line switch -chromosome is undefined!\n";
	}
	unless ( defined $start ) {
		$error .= "the cmd line switch -start is undefined!\n";
	}
	unless ( defined $end ) {
		$error .= "the cmd line switch -end is undefined!\n";
	}
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	print helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	return "
 $errorMessage
 command line switches for plot_genomic_region.pl

   -organism        :the organism tag for the genome to use
   -version         :the genome version to use
   -additional_data :additional data apart from the genomic information
                     here you can add bed files, bedGraph files or ROI names
                     All values, which are no files will be interpreted as ROI_Table 
   -colors          :a list of colors for the different datasets
   
   -chromosome  :the chromosome you are interested in
   -start       :start in bp
   -end         :end in bp
   
   -outfile  :the outfile (this script will create a SVG file and a log file)
   
   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/plot_genomic_region.pl';
$task_description .= " -organism $organism" if ( defined $organism );
$task_description .= " -version $version"   if ( defined $version );
$task_description .=
  " -additional_data '" . join( "' '", @additional_data ) . "'"
  if ( defined $additional_data[0] );
$task_description .= " -colors '" . join( "' '", @colors ) . "'"
  if ( defined $colors[0] );
$task_description .= " -chromosome $chromosome" if ( defined $chromosome );
$task_description .= " -start $start"           if ( defined $start );
$task_description .= " -end $end"               if ( defined $end );
$task_description .= " -outfile $outfile"       if ( defined $outfile );

## Do whatever you want!
open( LOG, ">$outfile.log" )
  or die "I could not create the  log file '$outfile.log'\n$!\n";
print LOG $task_description . "\n";
close(LOG);

my ( $figure, $gbFiles_table, $chr_region, @gbFile_IDs );

## initialize the plotting device
$figure = stefans_libs_plot_genomePlot->new();
$figure->GenomeInterface( genomeDB->new( variable_table->getDBH() )
	  ->GetDatabaseInterface_for_Organism_and_Version( $organism, $version ) );

## get the chromosomal region
$gbFiles_table =
  genomeDB->new( variable_table->getDBH() )
  ->GetDatabaseInterface_for_Organism_and_Version( $organism, $version )
  ->get_rooted_to('gbFilesTable');

my ( $hash, $used_gbFile_IDs, $chr, $s, $e );

if ( defined $genes[0] ) {
	## I need to get the chr, start and end for each gene and put that into a hash
	foreach my $gene (@genes) {
		my $gbFeatures = $figure->{'genome'}->get_Columns(
			{
				'search_columns' => [
					ref( $figure->{'genome'} ) . '.start',
					ref( $figure->{'genome'} ) . '.end',
					ref( $figure->{'genome'} ) . '.gbFile_id'
				]
			},
			{ 'name' => $gene, 'tag' => 'gene' }
		);
		foreach my $array (@$gbFeatures) {
			$used_gbFile_IDs->{ @$array[2] } = 1;
			( $chr, $s, $e ) =
			  $figure->{'genome'}->get_chr_calculator->gbFile_2_chromosome(
				@$array[2],
				$start - 2000,
				$end + 2000
			  );
			$hash->{$gene} = { 'chr' => $chr, 'start' => $s, 'end' => $e };
			$hash->{$gene}->{'chr_region'} =
			  $figure->{'genome'}->get_chromosomal_region( $chr, $s, $e )
			  ;
		}
	}
	@gbFile_IDs = keys(%$used_gbFile_IDs);
}
else {
	$chr_region =
	  $figure->{'genome'}->get_chromosomal_region( $chromosome, $start, $end );
	foreach ( $figure->{'genome'}
		->get_chr_calculator->Chromosome_2_gbFile( $chromosome, $start, $end ) )
	{
		push( @gbFile_IDs, @$_[0] );
	}
}

my ($data);
for ( my $i = 0 ; $i < @additional_data ; $i++ ) {
	$data = $additional_data[$i];
	my $obj;
	if ( -f $data ) {
		if ( $data =~ m/bed$/ ) {
			$obj = stefans_libs_file_readers_bed_file->new();
			$obj->read_file($data);
		}
		elsif ( $data =~ m/bedGraph$/ ) {
			$obj = stefans_libs_file_readers_bedGraph_file->new();
			$obj->read_file($data);
		}
		else {
			## OK some strange file ending - but I expect the default to be a bed file
			$obj = stefans_libs_file_readers_bed_file->new();
			$obj->read_file($data);
		}
	}
	else {
		$obj =
		  $gbFiles_table->Connect_2_result_ROI_table()
		  ->get_ROI_as_bed_file(
			{ 'tag' => $data, 'gbFile_id' => \@gbFile_IDs } );
	}
	$figure->AddDataset( $obj, $colors[$i], $data );
}

if ( defined $genes[0] ) {
	foreach my $gene ( keys %$hash ) {
		print "\n\nI plot this gbFile part:".$hash->{$gene}->{'chr_region'}->getAsGB()."\n\n";
		$figure->plot(
			{
				'gbFile'     => $hash->{$gene}->{'chr_region'},
				'chromosome' => $hash->{$gene}->{'chromosome'},
				'start'      => $hash->{$gene}->{'start'},
				'end'        => $hash->{$gene}->{'end'},
				'outfile'    => $outfile.".$gene",
			}
		);
	}
}
else {
$figure->plot(
	{
		'gbFile'     => $chr_region,
		'chromosome' => $chromosome,
		'start'      => $start,
		'end'        => $end,
		'outfile'    => $outfile,
	}
);
}
