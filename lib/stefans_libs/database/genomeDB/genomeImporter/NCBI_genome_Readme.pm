package NCBI_genome_Readme;

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

use strict;
use warnings;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION



=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class NCBI_genome_Readme.

=cut

sub new {
	my ( $class, $file ) = @_;

	my ($self);

	$self = {};

	bless $self, $class if ( $class eq "NCBI_genome_Readme" );

	if ( defined $file ) {
		$self->readFile($file);
	}
	return $self;
}

sub expected_dbh_type {
	#return 'dbh';
	return "not a database interface";
	#return "database";
}


sub convert_NCBI_date_to_mysql {
	my ( $self, $NCBI_date ) = @_;
	## e.g. '24 March 2008'
	my ( $day, $month, $year ) = ( split( " ", $NCBI_date ) );

	if ( $month =~ m/^\d+$/ ) {
		return undef if ( $month < 1 || $month > 12 );
		return $year.'-0' . $month . "-".$day if ( $month < 10 );
		return "$year-" . $month . "-".$day  if ( $month > 9 );
	}

	my @month = (
		"January",   "February", "March",    "April",
		"May",       "June",     "July",     "August",
		"September", "October",  "November", "December"
	);
	for ( my $i = 0 ; $i < @month ; $i++ ) {
		if ( $month[$i] eq $month ) {
			return $year."-"."0" . ($i + 1) . "-".$day if ( $i < 9 );
			return $year."-" . ($i + 1) . "-".$day  if ( $i > 8 );
		}
	}
	return undef;
}

sub Version {
	my ($self, $build, $version) = @_;
	if ( defined $build ) {
		$self->{data}->{build} = $build;
	}
	if ( defined $version ) {
		$self->{data}->{version} = $version;
	}
	return(  $self->{data}->{build} . "." . $self->{data}->{version} ) if ( defined $self->{data}->{version});
	return $self->{data}->{build};
}

sub ReferenceTag{
	my ( $self, $reference ) = @_;
	$self->{referenceTag} = $reference if ( defined $reference);
	return $self->{referenceTag};
}

sub ReleaseDate{
	my ( $self, $date ) = @_;
	return $self->{data}->{releaseDate}
}

sub readFile {
	my ( $self, $file ) = @_;

	open( IN, "<$file" ) or Carp::confess( "could not open file '$file'\n$!\n");
	## we search for
	## 1. the organism name
	## 2. the version
	## 3. the release date
	## 4. the most interesting dataset (refseq)
	## 5. all possible data sets (not really needed!)

	my ( $data, $header, @values );
	$data->{assemblies} = [];

	$header = 1;
	while (<IN>) {
		chomp $_;
		if ($header) {
			$data->{organism} = $1 if ( $_ =~ m/^Organism: (.+) \(\w/ );
			$data->{build}    = $1 if ( $_ =~ m/^\w+ Build Number: (\d+) *$/ );
			$data->{version}  = $1 if ( $_ =~ m/^Version: (\d+)/ );
			$data->{releaseDate} = $1 if ( $_ =~ m/^Release date: (.+)$/ );
			$header = 0 if ( $_ =~ m/^ *Label.*/ );
		}
		else {
			if ( $_ =~ m/^([\w\d\.]+)[ ]+(.+)$/ ) {
				@values = ( $1, $2);
				push( @{ $data->{assemblies} }, \@values );
				$self->ReferenceTag ($values[0] )
				  unless ( defined $self->{referenceTag} );
			}
			elsif ( $_ =~ m/^                (.+)$/ ) {
				@{ @{ $data->{assemblies} }[ @{ $data->{assemblies} } - 1 ] }[1]
				  .= $1;
			}
			elsif ( defined $self->{referenceTag}) {
				last;
			}
		}
	}
	$data->{releaseDate} =
	  $self->convert_NCBI_date_to_mysql( $data->{releaseDate} );

	$self->{data} = $data;
	return $self->{data};
	## typical file structure:
	#======================================================================
	#Organism: Homo sapiens (human)
	#NCBI Build Number: 36
	#Version: 3
	#Release date: 24 March 2008
	#
	#Freeze date for component genomic sequences: August 2005
	#Freeze date for other genomic sequences: 18 October 2007
	#Freeze date for mRNAs/ESTs used for annotation: 16 October 2007
	#
	#This build consists of a reference assembly for the whole genome,
	#alternate assemblies for the whole genome produced by Celera and by
	#JCVI, plus alternate assemblies for some parts of the genome.
	#
	#Assemblies in NCBI Build 36.3
	#Label           Description
	#-----           -----------
	#reference       Human Genome Sequencing Consortium finished genome,
	#                release 4.
	#Celera          Celera Genomics whole genome shotgun assembly (AADB),
	#                November 2001. This assembly included both WGS and BAC
	#                sequence data.
	#HuRef           J Craig Venter Institute whole genome shotgun assembly
	#                (May 2007) (see http://www.jcvi.org/research/huref/).
	#                This assembly represents a composite haploid version
	#                of the diploid genome sequence from a single
	#                individual (J. Craig Venter).
	#CRA_TCAGchr7v2  The Center for Applied Genomics at the Hospital for
	#                Sick Children (Toronto) chromosome 7 assembly, (April
	#                2004).
	#DR53            DR53 haplotype for the MHC region on chromosome 6.
	#c5_H2           An alternate assembly for part of chromosome 5.
	#c6_COX          An alternate haplotype assembly of the chromosome 6
	#                MHC region based on sequence data from the COX
	#                library.
	#c6_QBL          An alternate haplotype assembly of the chromosome 6
	#                MHC region based on sequence data from the QBL
	#                library.
	#c22_H2          An alternate assembly for part of chromosome 22.
	#
	#======================================================================
}
1;
