#! /usr/bin/perl -w

#  Copyright (C) 2008 Stefan Lang

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

=head1 exportROIs_as_simple_fastaDB.pl

This script exports the ROIs, that can be created by using the HMM modules in connection with NimbelGene ChIP on chip data to fetch the underlying sequence and export it as simple fasta DB that can be read my MDscan.

To get further help use 'exportROIs_as_simple_fastaDB.pl -help' at the comman line.

=cut

use Getopt::Long;
use stefans_libs::flexible_data_structures::data_table;
use stefans_libs::database::genomeDB;
use stefans_libs::database::LabBook;
use stefans_libs::database::system_tables::workingTable;

use strict;
use warnings;

my $VERSION = 'v1.0';

my (
	$help,        $debug,       $database,
	$ROI_tag,     @ROI_ids,     $genome_organism_tag,
	@search_tags, $max_regions, $outfile,
	$minLength,   $masked,      $ROI_name,
	$sort,        $LabBook_id,  $LabBook_entry_id,
	$workload_id,
);

Getopt::Long::GetOptions(
	"-ROI_tag=s"             => \$ROI_tag,
	"-ROI_name=s"            => \$ROI_name,
	"-ROI_ids=s{,}"          => \@ROI_ids,
	"-genome_organism_tag=s" => \$genome_organism_tag,
	"-search_tags=s{,}"      => \@search_tags,
	"-outfile=s"             => \$outfile,
	'-minLength=s'           => \$minLength,
	"-max_regions=s"         => \$max_regions,
	"-masked"                => \$masked,
	"-LabBook_id=s"          => \$LabBook_id,
	"-LabBook_entry_id=s"    => \$LabBook_entry_id,
	"-workload_id=s"         => \$workload_id,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $ROI_tag ) {
	$warn .= "the cmd line switch -ROI_tag is undefined!\n";
}
unless ( defined $ROI_ids[0] ) {
	$warn .= "the cmd line switch -ROI_ids is undefined!\n";
}
unless ( defined $search_tags[0] ) {
	$warn .=
	  "you cold create a order in the dataset by specifying -search_tags !\n";
}
else {
	$sort = [];
	foreach my $info (@search_tags) {
		my $hash;
		$hash = { 'matching_str' => $1, 'test' => $2 }
		  if ( $info =~ m/^(.*);(.*)$/ );
		unless ( defined($hash) ) {
			$error .= "we can not parse the sort_tag $info";
			next;
		}
		unless ( "lexical numeric antiNumeric" =~ m/$hash->{'test'}/ ) {
			$error .= "we can not parse the sort_tag $info";
			next;
		}
		push( @$sort, $hash );
	}
}
unless ( defined $minLength ) {
	$warn .=
"you could specifiy a -minLength that woiuld exclude ROIs below a certain length from the analysis!\n"
	  . "\tas you have not specified one I have set that to the minimum of 10bp\n";
	$minLength = 10;
}
unless ( defined $ROI_tag || defined $ROI_ids[0] || defined $ROI_name ) {
	$warn = '';
	$error .= "you need to specify either -ROI_ids, -ROI_tag or -ROI_name\n";
}
unless ( defined $genome_organism_tag ) {
	$error .= "the cmd line switch -genome_organism_tag is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}

unless ( defined $max_regions ) {
	$warn .=
	  'You could add only the first -max_regions to the output if you want!';
	$max_regions = 100e10;
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
 command line switches for exportROIs_as_simple_fastaDB.pl

   -ROI_tag             :the tag of the ROI that you want to select
   -ROI_ids             :the ROI_ids that you want to select (separated by ' ')
   -ROI_name            :the ROI name you are interested in         
   -search_tags         :the search_tags are a complictaed datastructure, that you can use 
                         to order the ROIs. Usage of this value implies, that the ROIs have some stored information!
                         One search_tag looks like that: \"<matching str>;<numeric||antiNumeric||lexical>\"
                         The <matching string> will be used to identfy the ROI_tag and the other value specifies a sort order.
   -genome_organism_tag :the genome string where the ROIs are stored to
   -outfile             :where to write the sime fastaDB to

   -help           :print this help
   -debug          :verbose output
   

";
}

## now we set up the logging functions....

my (
	$task_description, $genomeDB,         $interface,
	$seq,              $ROI_obj,          $data_table,
	$info,             @additional_infos, $ROI_Tags
);

## and add a working entry

$task_description .= 'exportROIs_as_simple_fastaDB.pl';
$task_description .= " -ROI_tag $ROI_tag" if ( defined $ROI_tag );
$task_description .= " -ROI_name $ROI_name" if ( defined $ROI_name );
$task_description .= ' -ROI_ids ' . join( ' ', @ROI_ids )
  if ( defined $ROI_ids[0] );
$task_description .= " -genome_organism_tag $genome_organism_tag"
  if ( defined $genome_organism_tag );
$task_description .= " -outfile $outfile" if ( defined $outfile );
$task_description .= " -search_tags " . join( " ", @search_tags )
  if ( defined $search_tags[0] );
$task_description .= " -max_regions  $max_regions";
$task_description .= " -masked" if ($masked);
my ( $job_id, $temp_dir, $orig_outfile );

$genomeDB = genomeDB->new();

if ( defined $workload_id ) {
	## this script was called from the database!
	## the outfile does not contain a pathn information!
	my $workload_table = workingTable->new( variable_table->getDBH() );
	( $job_id, $temp_dir ) = $workload_table->get_TempPath_4_id($workload_id);
	$orig_outfile = $outfile;
	$outfile      = "$temp_dir/$outfile";
	$interface    =
	  $genomeDB->GetDatabaseInterface_for_genomeID(
		{ 'organism_tag' => $genome_organism_tag } );

}
else {
	open( OUT, ">$outfile.log" )
	  or die "could not create logfile '$outfile.log'\n$!\n";
	print OUT "$task_description\n";
	close(OUT);
	$interface =
	  $genomeDB->getGenomeHandle_for_dataset(
		{ 'organism_tag' => $genome_organism_tag } );
}

$interface = $interface->get_rooted_to('ROI_table');

print "Log written to $outfile.log\n" unless ( defined $workload_id );

if ( defined $ROI_tag ) {
	$data_table = $interface->get_data_table_4_search(
		{
			'search_columns' => [
				ref($interface) . '.gbFile_id',
				ref($interface) . '.name',
				ref($interface) . '.start',
				ref($interface) . '.end',
				ref($interface) . '.gbString',
			],
			'where' => [ [ ref($interface) . '.tag', '=', 'my_value' ] ],
			'order_by' => ref($interface) . '.gbFile_id',
		},
		$ROI_tag
	);
}
elsif ( defined $ROI_name ) {
	$data_table = $interface->get_data_table_4_search(
		{
			'search_columns' => [
				ref($interface) . '.gbFile_id',
				ref($interface) . '.name',
				ref($interface) . '.start',
				ref($interface) . '.end',
				ref($interface) . '.gbString',
			],
			'where' => [ [ ref($interface) . '.name', '=', 'my_value' ] ],
			'order_by' => ref($interface) . '.gbFile_id',
		},
		$ROI_name
	);
}
else {
	Carp::confess(
		"sorry - only the option 'ROI_tag' is supported at the moment!\n");
}
if ( defined $search_tags[0] ) {
	Carp::confess(
		"sorry - only the option 'ROI_tag' is supported at the moment!\n");
}
Carp::confess(
	"The search '$interface->{'complex_search'}' did not give any results!\n")
  unless ( $data_table->Lines() > 0 );
$data_table->Remove_from_Column_Names( ref($interface) . '.' );

#print $data_table->AsString();
my ( $gbFile_id, $gbFile );
my $interface_feature =
  $genomeDB->getGenomeHandle_for_dataset(
	{ 'organism_tag' => $genome_organism_tag } );
$interface =
  $genomeDB->getGenomeHandle_for_dataset(
	{ 'organism_tag' => $genome_organism_tag } );
$interface = $interface->get_rooted_to('gbFilesTable');

open( OUT, ">$outfile" ) or die "could not create outfile $outfile\n";
my $chr_calculator = $interface ->get_chr_calculator();
my ( $chr,$chr_start,$chr_end);
for ( my $i = 0 ; $i < $data_table->Lines() ; $i++ ) {
	print "'" . join( "', '", @{ @{ $data_table->{'data'} }[$i] } ) . "'\n";
	if ($masked) {
		$gbFile =
		  $interface_feature->get_masked_gbFile_for_gbFile_id(
			@{ @{ $data_table->{'data'} }[$i] }[0] )
		  unless ( @{ @{ $data_table->{'data'} }[$i] }[0] == $gbFile_id );
	}
	else {
		$gbFile =
		  $interface->getGbfile_obj_for_id(
			@{ @{ $data_table->{'data'} }[$i] }[0] )
		  unless ( @{ @{ $data_table->{'data'} }[$i] }[0] == $gbFile_id );
	}

	$gbFile_id = @{ @{ $data_table->{'data'} }[$i] }[0];
	## the new acc should be ChrXY:start-end
	( $chr,$chr_start,$chr_end) = $chr_calculator-> gbFile_2_chromosome ( $gbFile_id, @{@{$data_table->{'data'}}[$i]}[2], @{@{$data_table->{'data'}}[$i]}[3]);
	print OUT ">$chr:$chr_start-$chr_end\n"
	  . $gbFile->Get_SubSeq(
		@{ @{ $data_table->{'data'} }[$i] }[2],
		@{ @{ $data_table->{'data'} }[$i] }[3]
	  )
	  . "\n";
}
close(OUT);
print "Data written to $outfile\n" unless ( defined $workload_id );

## this might be usefull for the database call

if ( defined $workload_id ) {
	my $LabBook =
	  LabBook->new( variable_table->getDBH() )
	  ->get_LabBook_Instance($LabBook_id);
	my $data = $LabBook->get_data_table_4_search(
		{
			'search_columns' => [
				ref($LabBook) . ".text",
				ref($LabBook) . ".header1",
				ref($LabBook) . ".header2",
				ref($LabBook) . ".header3",
				ref($LabBook) . ".experiment_id",
				ref($LabBook) . ".creation_date"
			],
			'where' => [ [ ref($LabBook) . ".id", '=', 'my_value' ], ],
		},
		$LabBook_entry_id
	);
	## Probably we did not get a usefull result here - then I need to create a new LabBook entry!
	unless ( $data->Lines() ) {
		$LabBook_entry_id = $LabBook->AddDataset(
			{
				'text' => 'I have exported the ROIs for the tag '
				  . "'$ROI_tag' and/or the ROI_name '$ROI_name'.\n"
				  . "The resulting file is named '$orig_outfile' and has been linked to this LabBook entry.",
				'header1' => 'Database Script Calls',
				'header2' => 'exportROIs_as_simple_fastaDB',
				'header3' => root->Today()
			}
		);
	}
	else {
		$LabBook_entry_id = $LabBook->UpdateDataset(
			{
				'id'   => @{ @{ $data->{'data'} }[0] }[0],
				'text' => @{ @{ $data->{'data'} }[0] }[1] . "\n\n"
				  . 'I have exported the ROIs for the tag '
				  . "'$ROI_tag' and/or the ROI_name '$ROI_name'.\n"
				  . "The resulting file is named '$orig_outfile' and has been linked to this LabBook entry.",
			}
		);
	}
	$LabBook->AddFile(
		{
			'comment' =>
			  "ROIs for the tag '$ROI_tag' and/or the ROI_name '$ROI_name'. "
			  . root->Today(),
			'file'       => $outfile,
			'labBook_id' => $LabBook_id,
			'entry_id'   => $LabBook_entry_id
		}
	);
}

