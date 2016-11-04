#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-11-02 Stefan Lang

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

    annotate_bed_with_gtf_genome.pl
       -infile    :one or more infiles
       -outfile   :one or more outfile (please same number like infiles)
       -gtf       :the gtf formated genome information (e.g. gencode.v24.annotation.gtf)
       -options   :gtf_feature gene (select the gtf feature you want to map against)
                   gtf_feature "" to force the usage of all entries


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  annotates a bed file using a gtf formated genome annotation.

  To get further help use 'annotate_bed_with_gtf_genome.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::file_readers::gtf_file;
use stefans_libs::file_readers::bed_file;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my ( $help, $debug, $database, @infiles, @outfiles, $gtf, $options, @options );

Getopt::Long::GetOptions(
	"-infile=s{,}"  => \@infiles,
	"-outfile=s{,}" => \@outfiles,
	"-gtf=s"        => \$gtf,
	"-options=s{,}" => \@options,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( -f $infiles[0] ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}
unless ( defined $outfiles[0] ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
}
unless ( defined $gtf ) {
	$error .= "the cmd line switch -gtf is undefined!\n";
}
unless ( defined $options[0] ) {
	$error .= "the cmd line switch -options is undefined!\n";
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

### initialize default options:

#$options->{'n'} ||= 10;

###

my ($task_description);

$task_description .=
  'perl ' . $plugin_path . '/annotate_bed_with_gtf_genome.pl';
$task_description .= ' -infile "' . join( '" "', @infiles ) . '"';
$task_description .= ' -outfile "' . join( '" "', @outfiles ) . '"';
$task_description .= " -gtf '$gtf'" if ( defined $gtf );
$task_description .= ' -options "' . join( '" "', @options ) . '"'
  if ( defined $options[0] );

for ( my $i = 0 ; $i < @options ; $i += 2 ) {
	$options[ $i + 1 ] =~ s/\n/ /g;
	$options->{ $options[$i] } = $options[ $i + 1 ];
}
###### default options ########
#$options->{'something'} ||= 'default value';
$options->{'gtf_feature'} = 'gene' unless ( defined $options->{'gtf_feature'} );
##############################
open( LOG, ">$outfiles[0].log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!
my $gtf_file = stefans_libs::file_readers::gtf_file->new();
print "Starting to read the gtf file\n";
$gtf_file->read_file($gtf);

$gtf_file =
  $gtf_file->select_where( 'feature',
	sub { $_[0] eq $options->{'gtf_feature'} } )
  unless ( $options->{'gtf_feature'} eq "" );

my $gtf_file_anno = $gtf_file->drop_column('attribute');

map { $gtf_file_anno->Rename_Column( $_, 'gtf_' . $_ ) }
	  @{ $gtf_file_anno->{'header'} };
	  
for ( my $fi = 0 ; $fi < @infiles ; $fi++ ) {
	my $infile  = $infiles[$fi];
	my $outfile = $outfiles[$fi];
	unless ( defined $outfile) {
		$outfile = root->filemap($infile);
		$outfile = $outfile->{'path'}."/".$outfile->{'filename_core'}.".annotated.xls";
	}
	my $bed_file = stefans_libs::file_readers::bed_file->new();
	$bed_file->read_file($infile);

	print "Starting to match the entries\n";

	my $overlap = $bed_file->efficient_match( $gtf_file, 'genome_ids', 1 );


	my @colIDs = $overlap->Add_2_Header( $gtf_file_anno->{'header'} );

## so in the overlap column line_id now contains a list of matched genome rows
	my ($line_id) = $overlap->Header_Position('genome_ids');
	for ( my $i = 0 ; $i < $overlap->Lines() ; $i++ ) {
		if ( ref( @{ @{ $overlap->{'data'} }[$i] }[$line_id] ) eq "ARRAY" ) {
			@{ @{ $overlap->{'data'} }[$i] }[@colIDs] =
			  &table_2_array( $gtf_file_anno,
				@{ @{ $overlap->{'data'} }[$i] }[$line_id] );
		}
		else {
			@{ @{ $overlap->{'data'} }[$i] }[ $colIDs[0] ] =
			  @{ @{ $overlap->{'data'} }[$i] }[$line_id];
		}
		unless ( @{ @{ $overlap->{'data'} }[$i] }[ $colIDs[0] ] ) {
			@{ @{ $overlap->{'data'} }[$i] }[ $colIDs[0] ] = 'no match';
		}
	}

	$overlap = $overlap->drop_column('genome_ids');

	my $data_table = data_table->new();
	$data_table->Add_2_Header( $overlap->{'header'} );
	$data_table->{'data'} = $overlap->{'data'};
	print $data_table->AsString() if ($debug);

	print "Analysis saved as file " . $data_table->write_file($outfile) . "\n";
}

sub table_2_array {
	my ( $table, $rows ) = @_;
	my @return;
	foreach ( @{ $table->{'header'} } ) {
		push( @return, join( " // ", @{ $table->GetAsArray($_) }[@$rows] ) );
	}
	return @return;
}
