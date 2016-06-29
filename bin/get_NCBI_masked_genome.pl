#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-06-28 Stefan Lang

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

    get_NCBI_masked_genome.pl
       -organism_name       :<please add some info!>
       -outdir       :<please add some info!>
       -releaseDate       :<please add some info!>
       -version       :<please add some info!>
       -referenceTag       :<please add some info!>
       -noDownload       :<please add some info!>


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Download and install the masked genome version from NCBI. The unmasked sequence has to be already installed for this to work.

  To get further help use 'get_NCBI_masked_genome.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::database::genomeDB::genomeImporter;
use stefans_libs::fastaDB;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, $organism_name, $outdir, $releaseDate, $version, $referenceTag, $noDownload);

Getopt::Long::GetOptions(
	 "-organism_name=s"    => \$organism_name,
	 "-outdir=s"    => \$outdir,
	 "-releaseDate=s"    => \$releaseDate,
	 "-version=s"    => \$version,
	 "-referenceTag=s"    => \$referenceTag,
	 "-noDownload"    => \$noDownload,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $organism_name) {
	$error .= "the cmd line switch -organism_name is undefined!\n";
}
unless ( defined $outdir) {
	$error .= "the cmd line switch -outdir is undefined!\n";
}
unless ( defined $releaseDate) {
	$error .= "the cmd line switch -releaseDate is undefined!\n";
}
unless ( defined $version) {
	$error .= "the cmd line switch -version is undefined!\n";
}
unless ( defined $referenceTag) {
	$error .= "the cmd line switch -referenceTag is undefined!\n";
}



if ( $help ){
	print helpString( ) ;
	exit;
}

if ( $error =~ m/\w/ ){
	helpString($error ) ;
	exit;
}

sub helpString {
	my $errorMessage = shift;
	$errorMessage = ' ' unless ( defined $errorMessage); 
	print "$errorMessage.\n";
	pod2usage(q(-verbose) => 1);
}



my ( $task_description);

$task_description .= 'perl '.$plugin_path .'/get_NCBI_masked_genome.pl';
$task_description .= " -organism_name '$organism_name'" if (defined $organism_name);
$task_description .= " -outdir '$outdir'" if (defined $outdir);
$task_description .= " -releaseDate '$releaseDate'" if (defined $releaseDate);
$task_description .= " -version '$version'" if (defined $version);
$task_description .= " -referenceTag '$referenceTag'" if (defined $referenceTag);
$task_description .= " -noDownload " if ( $noDownload);


## Do whatever you want!

my $genomeImporter = genomeImporter->new();
$genomeImporter->{'databaseDir'} = $outdir;
$genomeImporter->{'noDownload'} = 1 if ( $noDownload );
my @gzipped_fastq_files = @{$genomeImporter -> download_refseq_genome_for_organism ( $organism_name, $version, 1, 'mfa.gz' )->{'gbLibs'}} ;
my $fastaDB = stefans_libs::fastaDB->new();
foreach ( @gzipped_fastq_files ) {
	print "I load the gbfile $_\n";
	$fastaDB->AddFile($_);
	last if ( $debug );
}

my $genomeDB = genomeDB->new();
my $interface = $genomeDB -> GetDatabaseInterface_for_Organism_and_Version ( $organism_name, $version ) ->get_rooted_to('gbFilesTable') ;

my $data_table = $interface ->get_data_table_4_search( {
    	'search_columns' => [$interface->TableName.'.id',$interface->TableName.'.acc'],
    	'where' => [ ['masked_seq_id', '=',  'my_value'] ],
}, 0 );

$data_table->Remove_from_Column_Names ( $interface->TableName."." );

## columns are now id and acc
my $masked_file_id;
my $tmp_path = $genomeImporter->{databaseDir}."/masked_fasta";
my ($fasta_acc, $seq);
system( "mkdir $tmp_path" ) unless ( -d $tmp_path );
foreach my $entry ( @{ $data_table->GetAll_AsHashArrayRef() } ){
	## add the entries to the database!
	($fasta_acc) = $fastaDB->acc_match( $entry->{acc} );
	if ( defined $fasta_acc ){
		## save the fasta sequence only
		$seq = $fastaDB->{'data'}->{$fasta_acc};
		$seq =~ s/[a-z]/N/g;
	#	die "I plan to print the seq $seq\nto the file $tmp_path/$entry->{acc}.fa (orig acc = '$fasta_acc')\n";
		open ( OUT , ">$tmp_path/$entry->{acc}.fa" ) or die $!;
		print OUT $seq;
		close ( OUT );
		
		$masked_file_id = $interface->{'data_handler'}->{'external_files'}-> AddDataset ({
			filename => "$tmp_path/$entry->{acc}.fa",
			filetype => 'text',
			mode => 'text,'
		});
		$interface -> UpdateDataset ( {'id' => $entry->{'id'}, 'masked_seq_id' => $masked_file_id } ) ;
	} 
}

$data_table = $interface ->get_data_table_4_search( {
    	'search_columns' => [ref($interface).'.id', ref($interface).'.acc'],
    	'where' => [ ['masked_seq_id', '=',  'my_value'] ],
}, 0 );
$data_table->Remove_from_Column_Names ( $interface->TableName."." );

warn "I have not gotten masked sequences for these accs: ". join(", ", @{$data_table->GetAsArray('acc')} )."\n" if ( $data_table->Lines() > 0 );

    
