#! /usr/bin/perl -w

#  Copyright (C) 2012-10-25 Stefan Lang

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

=head1 relink_files_fasta_to_database.pl

This tool has been necessary after a hard disk crash. I have lost all genome fasta files biut not the genome database and therefore it was easier for me to re-create the link to the fasta files than to re-import the whole genome database.

To get further help use 'relink_files_fasta_to_database.pl -help' at the comman line.

=cut

use Getopt::Long;
use strict;
use warnings;
use PerlIO::gzip;
use stefans_libs::database::genomeDB;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @fasta_gz_files, $organism_tag, $organism_version);

Getopt::Long::GetOptions(
	 "-fasta_gz_files=s{,}"    => \@fasta_gz_files,
	 "-organism_tag=s"    => \$organism_tag,
	 "-organism_version=s"    => \$organism_version,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $fasta_gz_files[0]) {
	$error .= "the cmd line switch -fasta_gz_files is undefined!\n";
}
unless ( defined $organism_tag) {
	$error .= "the cmd line switch -organism_tag is undefined!\n";
}
unless ( defined $organism_version) {
	$error .= "the cmd line switch -organism_version is undefined!\n";
}


if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	print helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
 	return "
 $errorMessage
 command line switches for relink_files_fasta_to_database.pl

   -fasta_gz_files       :<please add some info!> you can specify more entries to that
   -organism_tag       :<please add some info!>
   -organism_version       :<please add some info!>

   -help           :print this help
   -debug          :verbose output
   

"; 
}


my ( $task_description);

$task_description .= 'perl '.root->perl_include().' '.$plugin_path .'/relink_files_fasta_to_database.pl';
$task_description .= ' -fasta_gz_files '.join( ' ', @fasta_gz_files ) if ( defined $fasta_gz_files[0]);
$task_description .= " -organism_tag $organism_tag" if (defined $organism_tag);
$task_description .= " -organism_version $organism_version" if (defined $organism_version);

my $genomeDB = genomeDB -> new( variable_table->getDBH() );

my $genome_interface = $genomeDB -> GetDatabaseInterface_for_Organism_and_Version ( $organism_tag, $organism_version );
Carp::confess ( "You need to use the script get_NCBI_genome.pl to import a new genome.") unless ( ref($genome_interface) eq "gbFeaturesTable" );
## now I need to get the gi information for all the necessary gbFiles
$genome_interface = $genome_interface->get_rooted_to ( "gbFilesTable" );
my $data_table = $genome_interface-> get_data_table_4_search( {
	'search_columns' => ['header', 'seq_id'], 'where' => [] }, );

## the path to stiore the files is here: $genome_interface->{'data_handler'}->{'external_files'}->{'data_path'}
my ($gi_to_file, $temp);
for ( my $i = 0; $i < $data_table->Lines(); $i ++ ){
	if ( @{@{$data_table->{'data'}}[$i]}[0] =~m/\nVERSION\s+N[CT]_\d+.\d+\s+GI:(\d+)/ ){
		$gi_to_file->{$1} = $genome_interface->{'data_handler'}->{'external_files'}->{'data_path'}."/".@{@{$data_table->{'data'}}[$i]}[1].".dta";
		print $genome_interface->{'data_handler'}->{'external_files'}->{'data_path'}."/".@{@{$data_table->{'data'}}[$i]}[1].".dta\n";
	}
	else {
		Carp::confess ( "Sorry I could not get the GI information from this header:\n".@{@{$data_table->{'data'}}[$i]}[0]."\n in the $i th line of the database result " );
	}
}
#root::print_hashEntries( $gi_to_file, 10, "The gi_to_file hash:");
my ( @temp, $path, @created_files, $i, $seq, $gi );
@temp = split("/", $fasta_gz_files[0] );
pop ( @temp);
$path = join("/", @temp );
$i = 0;
foreach my $flatfile ( @fasta_gz_files ){
	if ( $flatfile =~ m/\.gz$/ ){
		## we have a gzipped file!
		open (IN,"<:gzip", "$flatfile") or die "problem with the >PerlIO::gzip layer ('$flatfile')?\n$!\n";
	}
	else {
		open ( IN, "<$flatfile") or die "can not read the genbank flatfile $flatfile\n";
	}
	while ( <IN> ){
		if ( $_ =~m/>gi.(\d+).ref/ ){
			if ( defined $gi_to_file->{$gi} ) {
				open ( OUT ,">$gi_to_file->{$gi}" ) or die "I could not create the outfile '$gi_to_file->{$gi}'\n$!\n";
				print OUT $seq;
				close ( OUT );
				@created_files[$i++] = $gi_to_file->{$gi};
				$gi_to_file->{$gi} = "done";
			}
			$seq = '';
			$gi = $1;
			next;
		}
		elsif ( ! defined $gi ){
			Carp::confess ( "The match to identify the gi has not worked!\n");
		}
		chomp ( $_ );
		$seq .= $_;
	}
	if ( defined $gi_to_file->{$gi} ) {
		open ( OUT ,">$gi_to_file->{$gi}" ) or die "I could not create the outfile '$gi_to_file->{$gi}'\n$!\n";
		print OUT $seq;
		close ( OUT );
		@created_files[$i++] = $gi_to_file->{$gi};
		$gi_to_file->{$gi} = "done";
		$seq = '';
		$gi = undef;
	}
}
my $i = 0;
foreach ( values %$gi_to_file ) {
	if ( ! $_ eq "done" ){
		warn "file '$_' has not been created!\n" ;
		$i ++;
	}
}



