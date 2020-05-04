#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2018-02-09 Stefan Lang

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

=head1 CREATED BY
   
   binCreate.pl from git@github.com:stela2502/Stefans_Lib_Esentials.git commit 2b3dac48125abf3cf3d1c692eb96a10f20faf457
   

=head1  SYNOPSIS

    createArtificialTransgenesChromosome.pl
       -fasta     :<please add some info!> you can specify more entries to that
       -gb       :<please add some info!>
       -outfile       :<please add some info!>


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  This script takes a list of transgene fasta files and a 'random' genome shotgun genebank file to create an atrificial chromosome including all transgenes interspersed into the shotgun genome.

  To get further help use 'createArtificialTransgenesCromosome.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::database::genomeDB::genbank_flatfile_db;
use stefans_libs::fastaDB;
use stefans_libs::file_readers::gtf_file;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';


my ( $help, $debug, $database, @fasta, $gb, $outfile);

Getopt::Long::GetOptions(
       "-fasta=s{,}"    => \@fasta,
	 "-gb=s"    => \$gb,
	 "-outfile=s"    => \$outfile,

	 "-help"             => \$help,
	 "-debug"            => \$debug
);

my $warn = '';
my $error = '';

unless ( defined $fasta[0]) {
	$error .= "the cmd line switch -fasta is undefined!\n";
}
unless ( defined $gb) {
	$error .= "the cmd line switch -gb is undefined!\n";
}
unless ( defined $outfile) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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

$task_description .= 'perl '.$plugin_path .'/createArtificialTransgenesCromosome.pl';
$task_description .= ' -fasta "'.join( '" "', @fasta ).'"' if ( defined $fasta[0]);
$task_description .= " -gb '$gb'" if (defined $gb);
$task_description .= " -outfile '$outfile'" if (defined $outfile);



use stefans_libs::Version;
my $V = stefans_libs::Version->new();
my $fm = root->filemap( $outfile );
mkdir( $fm->{'path'}) unless ( -d $fm->{'path'} );

open ( LOG , ">$outfile.log") or die $!;
print LOG '#library version '.$V->version( 'stefanl_libs-GenomeDB' )."\n";
print LOG $task_description."\n";
close ( LOG );

## initialize the data:

my $genbank_flatfile_db = genbank_flatfile_db->new({'tempPath' => "/tmp/genomeData/" });
my $fastaDB = stefans_libs::fastaDB->new();

map { $fastaDB->AddFile($_) } @fasta;
$genbank_flatfile_db -> loadFlatFile( $gb );

## initialize output

my $result = fastaFile->new();
my $gtf_file = stefans_libs::file_readers::gtf_file->new();

## add the first part
my $fillers = $genbank_flatfile_db -> getInfo_as_data_table();
print $fillers->AsString();
$result->Seq( $genbank_flatfile_db->get_gbFile_obj_for_version( @{@{$fillers->{'data'}}[0]}[0] )->Sequence( ) );

my ($start_tg, $GeneID) ;
my $i =0;
my ( $transgene_Name, $transgene_seq );
my $start_id =  99999999999;
while (( $transgene_Name, $transgene_seq ) = $fastaDB->get_next() ) {
	unless ( defined $transgene_Name) {last};
	$start_tg = length($result->Seq());
	$result->Seq( $result->Seq(). $transgene_seq );
	#'seqname', 'source', 'feature', 'start','end',     'score',  'strand',  'frame','attribute'
	$GeneID = "ENSMUSG".( $start_id - $i++ );
	my $entry = {
		'seqname' =>'chrT', 
		'source' => 'UserSpec', 
		'feature' => 'gene', 
		'start' => $start_tg, 
		'end' => $start_tg+length($transgene_seq),
		'score' =>'.',
		'strand' => '+',
		'frame' => '.',
		'attribute' => "gene_id \"$GeneID.1\"; transcript_id \"$GeneID.1\";"
			. " gene_type \"protein_coding\"; gene_name \"$transgene_Name\"; transcript_type \"protein_coding\";"
			. " transcript_name \"$transgene_Name"."_1\"; level 2; transcript_support_level \"1\";"
	};
	$gtf_file->AddDataset( $entry );
	$entry->{'feature'} = 'transcript';
	$gtf_file->AddDataset( $entry );
	$entry->{'feature'} = 'exon';
	$gtf_file->AddDataset( $entry );
	## and now add the separating spacer
	$result->Seq( $result->Seq(). $genbank_flatfile_db->get_gbFile_obj_for_version( @{@{$fillers->{'data'}}[$i]}[0] )->Sequence( ) );
}
$result->Name( 'chrT' );
$outfile .= '.fa' unless ( $outfile =~m/\.fa$/);
$result->WriteAsFasta( $outfile );
$outfile =~s/\.fa$/.gtf/;
open ( OUT, ">$outfile" ) or die "I could not create the gtf file '$outfile'\n$!\n";
map { print OUT join("\t", @{$_}) ."\n" } @{$gtf_file->{'data'}};

print "Done\n";



