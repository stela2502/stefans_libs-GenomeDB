package seq_contig;

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
use PerlIO::gzip;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::gbFile

=head1 DESCRIPTION

package used to access the NCBI seq_contig.md.gz file

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class seq_contig.

=cut

sub new {
	my ( $class, $file ) = @_;

	my ($self);

	$self = {
		counter  => 0,
		hashKeys => undef,
		data     => []
	};

	bless $self, $class if ( $class eq "seq_contig" );

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

sub readLines {
	my ($self) = @_;
	return scalar( @{ $self->{data} } );
}

sub parse_order {
	my ( $self, $order, $space, $referenceTag ) = @_;
	return undef unless ( defined $space );
	my ( $chr, $start );
	$self->{hashKeys} = [
		split(
			/\s+/,
'tax_id chromosome      chr_start       chr_stop        orientation     feature_name    feature_id      feature_type    group_label     weight'
		)
	];
	foreach (@$order) {
		unless ( $chr eq @$_[0] ) {
			$chr   = @$_[0];
			$start = 1;
		}
		push(
			@{ $self->{data} },
			[
				1,
				@$_[0],    #chromosome
				$start,
				$start + @$_[2],
				'+', @$_[1], @$_[1], $referenceTag, $referenceTag, 1
				,
			]
		);
		$start += @$_[2] + $space ;
	}
}

sub write_file {
	my ( $self, $filename ) = @_;
	open ( OUT, ">$filename") or die "I could not create the outfile '$filename'\n$!\n";
	print  '#'.join("\t",@{$self->{hashKeys}})."\n";
	for ( my $i = 0; $i <@{$self->{'data'}}; $i ++ ){
		print OUT join("\t", @{@{$self->{'data'}}[$i]})."\n";
	}
	close ( OUT );
}

sub readFile {
	my ( $self, $file ) = @_;
	#return 1 if ( @{ $self->{data} } > 0 );
	
	## #tax_id chromosome      chr_start       chr_stop        orientation     feature_name    feature_id      feature_type    group_label     weight
	## 9606	Y	1	1	+	start	-	CONTIG	Celera	-2
	print ref($self) . ":I can open this file? '$file'\n"
	  if ( $self->{'debug'} );
	open( IN, "<:gzip", "$file" ) or die "could not open file $file \n $!\n";
	$self->{data} = [];
	while (<IN>) {
		chomp $_;
		if ( $_ =~ m/^#(.+)/ ) {
			$self->{hashKeys} = [ split( "\t", $1 ) ];
			next;
		}
		my $dataset = [ split( "\t", $_ ) ];
		unless ( $self->makeHash($dataset)->{'chromosome'} =~ m/\|/ ) {
			push( @{ $self->{data} }, $dataset );
		}
	}
	close(IN);
	print "I have opened the file '$file' and obtained "
	  . scalar( @{ $self->{'data'} } )
	  . " entries.\n";
	return 1;
}

sub makeHash {
	my ( $self, $data ) = @_;
	my $return = {};
	for ( my $i = 0 ; $i < @{ $self->{hashKeys} } ; $i++ ) {
		$return->{ @{ $self->{hashKeys} }[$i] } = @$data[$i];
	}
	return $return;
}

sub getNext {
	my ($self) = @_;
	my ( $return, $data );
	if ( $self->{'counter'} < @{ $self->{data} } ) {
		$data = $self->{data}[ $self->{'counter'}++ ];
		return $self->makeHash($data);
	}
	return undef;
}

sub getPrevious {
	my ($self) = @_;
	my ( $return, $data );
	if ( $self->{'counter'} > 0 ) {
		$data = $self->{data}[ $self->{'counter'} - 2 ];
		$self->{'counter'} -= 2;
		for ( my $i = 0 ; $i < @{ $self->{hashKeys} } ; $i++ ) {
			$return->{ @{ $self->{hashKeys} }[$i] } = @$data[$i];
		}
		return $return;
	}
	return undef;

}

1;
