#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-06-27 Stefan Lang

  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public License 
  as published by the Free Software Foundation; 
  either version 3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License 
  along with this program; if not, see <http://www.gnu.org/licenses/>.

=head1  SYNOPSIS

    annotate_bed_like_file.pl
       -bed_file      :the input bed like file (chr start stop as first three tab separated columns)
       -with_header   :use this if the table contains a column header (and is therefore bed like not bed)
       -outfile       :the outfile
       
       -organism      :genome data is stored in the database for this organism (e.g. H_sapiens)
       -version       :and this version (e.g. 'ANNOTATION_RELEASE.106')
       
       -max_distance  :all features in an area of <max_distance> bp are considered
       -feature_tag   :which features to report (none == all!)
       -feature_name  :some specific feature name? optional
       -promoter      :match to the putative promoter of a feature (0 to -3kb)
       -first_exon    :match to the first exon of each feature


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Annotates a bed like file (chr start end as first three columns) with genome information.

  To get further help use 'annotate_bed_like_file.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::database::genomeDB;
use stefans_libs::file_readers::bed_file;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,         $debug,       $database, $bed_file,
	$with_header,  $outfile,     $organism, $version,
	$max_distance, $feature_tag, $promoter,$first_exon, $feature_name
);

Getopt::Long::GetOptions(
	"-bed_file=s"     => \$bed_file,
	"-with_header"    => \$with_header,
	"-outfile=s"      => \$outfile,
	"-organism=s"     => \$organism,
	"-version=s"      => \$version,
	"-max_distance=s" => \$max_distance,
	"-feature_tag=s"  => \$feature_tag,
	"-feature_name=s" => \$feature_name,
	"-promoter" => \$promoter,
	"-first_exon" => \$first_exon,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $bed_file ) {
	$error .= "the cmd line switch -bed_file is undefined!\n";
}

# with_header - no checks necessary
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $organism ) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version ) {
	$error .= "the cmd line switch -version is undefined!\n";
}
unless ( defined $max_distance ) {
	$warn .= "the cmd line switch -max_distance is undefined!\n";
	$max_distance = 0;
}
unless ( defined $feature_tag ) {
	$warn .= "the cmd line switch -feature_tag is undefined!\n";
	$feature_tag = 'gene';
}
unless ( defined $feature_name ) {
	$warn .= "the cmd line switch -feature_name is undefined!\n";
}

if ($help) {
	print helpString();
	exit;
}

if ( $error =~ m/\w/ ) {
	helpString($error);
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage );
	print "$errorMessage.\n";
	pod2usage( q(-verbose) => 1 );
}

my ($task_description);

$task_description .= 'perl ' . $plugin_path . '/annotate_bed_like_file.pl';
$task_description .= " -bed_file '$bed_file'" if ( defined $bed_file );
$task_description .= " -with_header" if ($with_header);
$task_description .= " -outfile '$outfile'"   if ( defined $outfile );
$task_description .= " -organism '$organism'" if ( defined $organism );
$task_description .= " -version '$version'"   if ( defined $version );
$task_description .= " -max_distance '$max_distance'"
  if ( defined $max_distance );
$task_description .= " -feature_tag '$feature_tag'" if ( defined $feature_tag );
$task_description .= " -feature_name '$feature_name'"
  if ( defined $feature_name );
$task_description .= " -promoter" if ($promoter);
$task_description .= " -first_exon" if ($first_exon);
  

open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!

my $genomeDB = genomeDB->new( variable_table->getDBH() );
my $interface =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( $organism,
	$version );

my $run_options = {
	'tag' => $feature_tag,
	'name' => $feature_name,
};
$run_options->{'promoter'} = 1 if ( $promoter );
$run_options->{'first_exon'} = 1 if ( $first_exon );
my $genome_bed = $interface->get_as_bed_file($run_options);

my $source_bed;
if ( $with_header ) {
	$source_bed = data_table->new({'filename' => $bed_file} );
	$source_bed->Rename_Column( @{$source_bed->{'header'}}[0], 'chromosome' );
	$source_bed->Rename_Column( @{$source_bed->{'header'}}[1], 'start');
	$source_bed->Rename_Column( @{$source_bed->{'header'}}[2],'end' );
	$source_bed->Rename_Column( @{$source_bed->{'header'}}[3], 'name');
	## hard core class remapping!
	my $self = stefans_libs::file_readers::bed_file->new();
	$self -> Add_2_Header( [@{$source_bed->{'header'}}[4..($source_bed->Columns()-1)]]);
	$self -> {'data'} = $source_bed->{'data'};
	$source_bed = $self;
}else {
	$source_bed = stefans_libs::file_readers::bed_file->new({ 'filename' => $bed_file });
}

my $overlap = $source_bed -> efficient_match ( $genome_bed , 'genome_ids', $max_distance );

## now I can use the overlap column genome_ids that contains all row ids of the genome table of interest!
my ($genome_col) =  $overlap -> Header_Position( 'genome_ids' );
my $names_col = $source_bed->Add_2_Header('feature_names');
my $ids_col = $source_bed->Add_2_Header('feature_ids');
my $start_col = $source_bed->Add_2_Header('feature_start');
my $stop_col = $source_bed->Add_2_Header('feature_stop');

my ( @genomeIDs );

sub add_to_col {
	my ( $row, $col, $value ) = @_;
	@{@{$source_bed->{'data'}}[$row]}[$col] = $value;
}
sub get_from_genome {
	my ( $source_col, @ids ) = @_;
	return join(" // ", @{$genome_bed->GetAsArray($source_col)}[@ids] );
}

## genome:
#chr1    17369   17436   MIR6859-1       "GeneID:102466751";"miRBase:MI0022705"
#chr1    30366   30503   MIR1302-2       "GeneID:100302278";"HGNC:35294";"miRBase:MI0006363"

print join("\t",@{$source_bed->{'header'}})."\n".$source_bed ->AsTestString();

for ( my $i = 0; $i < $source_bed->Rows(); $i ++ ) {
	if (@{@{@{$overlap->{'data'}}[$i]}[$genome_col]} > 0 ) {
		@genomeIDs = @{@{@{$overlap->{'data'}}[$i]}[$genome_col]};
		&add_to_col( $i, $start_col, &get_from_genome( 1, @genomeIDs ) );
		&add_to_col( $i, $stop_col, &get_from_genome( 2, @genomeIDs ) );
		&add_to_col( $i, $names_col, &get_from_genome( 3, @genomeIDs ) );
		&add_to_col( $i, $ids_col, &get_from_genome( 4, @genomeIDs ) );
		#print "The array content for line $i: ". join(", ",@{@{@{$overlap->{'data'}}[$i]}[4]})."\n";
	}else {
		&add_to_col( $i, $start_col, '---' );
		&add_to_col( $i, $stop_col, '---' );
		&add_to_col( $i, $names_col, '---' );
		&add_to_col( $i, $ids_col, '---' );
	}
	
}

$source_bed = $source_bed -> drop_column ('genome_ids');
print $source_bed ->AsTestString();

if ( $with_header ) {
	my $self = data_table->new();
	$self -> Add_2_Header($source_bed->{header});
	$self ->{'data'} = $source_bed->{'data'};
	$self ->write_file ( $outfile );
}else {
	$source_bed->write_file ( $outfile );
}


#print $overlap ->AsTestString();
#print "The array content for line 0: ". join(", ",@{@{@{$overlap->{'data'}}[0]}[4]})."\n";


