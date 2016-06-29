#! /usr/bin/perl -w

#  Copyright (C) 2013-10-17 Stefan Lang

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

=head1 get_chromosomal_sequence.pl

Get the sequence for a region in the chromosome.

To get further help use 'get_chromosomal_sequence.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use stefans_libs::database::genomeDB;
use stefans_libs::file_readers::bed_file;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @region, $outfile, $organism, $version,
	$masked );

Getopt::Long::GetOptions(
	"-region=s{,}" => \@region,
	"-outfile=s"   => \$outfile,
	"-organism=s"  => \$organism,
	"-version=s"   => \$version,
	"-masked"      => \$masked,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $region[0] ) {
	$error .= "the cmd line switch -region is undefined!\n";
}elsif ( -f $region[0] ) {
	my $tmp = stefans_libs_file_readers_bed_file ->new({'filename' => $region[0]} );
	@region = @{$tmp->CHR_key()};
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $organism ) {
	$error .= "the cmd line switch -organism is undefined!\n";
}
unless ( defined $version ) {
	warn "You get data for the last version in the database\n";
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
 command line switches for get_chromosomal_sequence.pl

   -region       :the regions as 'chr:start-end' strings or one bed file
   -outfile      :the outfile containing the fasta database
   -organism     :the organism to get the sequences from
   -version      :the version of the genome
   -masked       :use the masked data

   -help           :print this help
   -debug          :verbose output
   

";
}

my ($task_description);

$task_description .= 'perl '
  . root->perl_include() . ' '
  . $plugin_path
  . '/get_chromosomal_sequence.pl';
$task_description .= ' -region ' . join( ' ', @region )
  if ( defined $region[0] );
$task_description .= " -outfile $outfile"   if ( defined $outfile );
$task_description .= " -organism $organism" if ( defined $organism );
$task_description .= " -version $version"   if ( defined $version );
$task_description .= " -masked "            if ($masked);

open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!
my ( $gbFile_id, $gbFile, $genomeDB );
$genomeDB = genomeDB->new(variable_table->getDBH());
my $interface_feature =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( $organism,
	$version );

my $interface =
  $genomeDB->GetDatabaseInterface_for_Organism_and_Version( $organism,
	$version );
$interface = $interface->get_rooted_to('gbFilesTable');

$interface -> Connect_2_REPEAT_ROI_table() if ( $masked );

my $chr_calculator = $interface->get_chr_calculator();
open ( OUT , ">$outfile") or die "I could not create the outfile $outfile\n$!\n";

my ( $chr, $chr_start, $chr_end, @data, $str );
$gbFile_id = '';
foreach my $region (@region) {
	$region =~ s/,//;
	( $chr, $chr_start, $chr_end ) = split( /[\s:-]/, $region );
	@data = $chr_calculator->Chromosome_2_gbFile( $chr, $chr_start, $chr_end );
	$str = '';
	foreach my $array (@data) {
		print "I process the region $region\n";
		unless ( @$array[0] == $gbFile_id  ){
			$gbFile =
			  $interface->getGbfile_obj_for_id( @$array[0] )
			  unless ( @$array[0] == $gbFile_id );
			$gbFile_id = @$array[0];
		}
		$str .= $gbFile->Get_SubSeq( @$array[1], @$array[2]);
	}
	print OUT ">$region\n"
	  . $str . "\n";
}
close(OUT);
print "Data written to $outfile\n";
