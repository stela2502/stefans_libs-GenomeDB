package stefans_libs::fastaDB;

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
use stefans_libs::root;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like "perldoc perlpod".

=head1 NAME

stefans_libs::fastaFile

=head1 DESCRIPTION

The class fastaFile is used to handle fasta formated sequence files

=head2 depends on

L<::root>

=head2 provides

L<AddFile|"AddFile">

L<Get_SubSeq|"Get_SubSeq">

L<WriteAsFasta|"WriteAsFasta">

L<Name|"Name">

L<Seq|"Seq">

=head1 METHODS

=head2 new

new returns a new object reference of the class fastaFile.

If a valid path to a fasta formated sequence file is ommited as argument this sequence file is read
using the method L<AddFile|"AddFile">.

=cut

sub new {
	my ( $class, $filename, $debug ) = @_;

#warn "fastaDB could use a file with (multiple) fasta Sequences upon startup ($filename)\n" unless ( -f $filename);
	my ( $self, $data );
	$self = {
		debug           => $debug,
		data            => $data,
		entries         => 0,
		accs            => [],
		actual_position => 0
	};

	bless( $self, $class ) if ( $class eq "stefans_libs::fastaDB" );
	if ( defined $filename ) {
	$self->AddFile($filename) if ( -f $filename );
	}
	return $self;
}

=head2 AddFile

AddFile is used to import a fasta formated txt file.

=header3 atributes

[0]: absolute path to the fasta formates sequence file

=header3 return values

1 if success

=cut

sub AddFile {

	my ( $self, $filename ) = @_;

	my ( $seq, $i, $tag );
	$i = 0;
	if ( $filename =~ m/.gz$/) {
		open( IN, "gunzip -c $filename |" ) or die "Konnte $filename nicht öffnen!\n";
	}else {
		open( IN, "<$filename" ) or die "Konnte $filename nicht öffnen!\n";
	}

	while (<IN>) {
		next unless ( $_ =~ m/\w/);
		if ( $_ =~ m/^>(.+)$/ ) {
			if ( defined $tag ) {
				#print "we add the seq $tag, $seq\n";
				$self->addEntry( $tag, $seq );
				$seq = undef;
				$self->{entries}++;
				
			}
			$tag = $1;
		}
		else {
			chomp($_);
			if ($_ =~ m/^([AaGgTtCcNnXx]+)+$/ ){
				$seq = "$seq$1";
				#print "now we have the seq $seq\n";
			}
			else{
				warn "this is not a fasta seq: '$_' but we still use it!\n";
				$seq = "$seq$_";
			}
			
		}
	}
	if ( defined $tag ) {
		$self->addEntry( $tag, $seq );
	}
	
	close(IN);
	print "Sequence infos added!\n" if ( $self->{debug} );
	return 1;
}

sub Reset {
	my ( $self ) = @_;
	$self->{'actual_position'} = 0;
}
sub get_next {
	my ($self) = @_;
	return undef if ( $self->{actual_position} == scalar(@{ $self->{accs} } ) );
	my $acc = @{ $self->{accs} }[ $self->{actual_position}++ ];
	return $acc, $self->_seq($acc) if ( defined $acc );
	return undef, undef;
}

=head2 addEntry

=head3 arguments

[0]: the acc of this entry (unformated string!)

[1]: the nucleotide sequence of the entry (only AGCTN)

=head3 return values

true (dies if the acc is already in the database)

=cut

sub addEntry {
	my ( $self, $acc, $sequence ) = @_;
	$self->{error} = '';
	$self->{error} .= ref($self) . ":addEntry -> Acc $acc has no sequence!\n"
	  unless ($sequence);
	$self->{error} .=
	  ref($self) . ":addEntry -> we need to know the acc of the sequence!\n"
	  unless ( defined $acc );
	$self->_seq($acc, $sequence);
	push( @{ $self->{accs} }, $acc );
	return 1;
}

=head2 Get_SubSeq

=head3 arguments

[0]: position in basepairs where the substring of the seqiuence should start

[1]: position in basepairs where the substring of the seqiuence should end

=head3 return values

the substring of the sequence or the whole sequence if start and end where not defined

=cut

sub Get_SubSeq {
	my ( $self, $acc, $start, $end ) = @_;
	my ($seq);
	$start-- if ( $start > 0 );
	$end--   if ( $end > 1 );

	if ( defined $self->_seq($acc) ) {
		if ( defined $end && defined $start ) {
			return substr( $self->_seq($acc), $start, $end - $start );
		}
		elsif ( defined $start && !defined $end ) {
			return substr( $self->_seq($acc), 0, $end );
		}
		elsif ( defined $end && !defined $start ) {
			return
			  substr( $self->_seq($acc), $start,
				length( $self->Seq ) - $start );
		}
		else {
			return $self->_seq($acc);
		}
	}
	else {
		root::print_hashEntries( $self, 2, "No sequence entry for acc $acc?" );
		die "No sequence entry for acc $acc\n";
	}
	return undef;
}

sub _addArray {
	my ( $self, $array ) = @_;
	die
"we need an array of arrays that stores the fasta informations, not ( $array )\n"
	  unless ( ref($array) eq "ARRAY" && ref( @$array[0] ) eq "ARRAY" );
	my $second;
	foreach $second (@$array) {
		$self->addEntry( @$second[0], @$second[1] );
	}
	return 1;
}

=head2 WriteAsFasta

WriteAsFasta wirtes the internal sequence representation in fasta format.

=header3 arguments

[0]: the absolute filename to write the sequence to.

[1]: position in basepairs where the sequence should start

[2]: position in basepairs where the sequence should end


=cut

sub WriteAsFastaDB {
	my ( $self, $filename, $startSeq, $endSeq ) = @_;

	my ( $seq, $data );

	open( OUT, ">$filename" ) or die "Konnte File $filename nicht anlegen!\n";
	print OUT $self->getAsFastaDB();
	close OUT ;
	print "DB written as $filename in FASTA format\n" if ( $self->{debug} );
	return 1;
}

sub getAsFastaDB{
	my ( $self ) =@_;
	my $str = '';
	my $seq;
	foreach my $tag ( @{ $self->{accs} } ) {
		$seq = $self->{'data'}->{$tag};
		if ( length($seq) == 0 ){
			print "I have no seq for the acc $tag\n";
			next;
		}
		$str .= ">$tag\n";
		for ( my $start = -1 ; $start < length($seq) ; $start += 60 ) {
			$str .=  substr( $seq, $start + 1, 60 ). "\n";
		}
	}
	return $str;
}

sub get_oligoID{
	my ( $self, $acc) = @_;
	return 0 unless ( defined $acc);
	my $i = 0;
	my $local_acc;
	foreach $local_acc ( @{$self->{'accs'}}){
		$i++;
		return $i if ( $acc eq $local_acc);
	}
	return undef;
}

sub length_for_acc {
	my ( $self, $acc ) = @_;
	unless ( defined $acc ){
		warn ref($self), ": length_for_acc - we got no acc - you get an array contining all length data\n" if( $self->{'debug'});
		return map{ length( $self->_seq($_) ) }@{$self->{'accs'}};
	}
	my $l;
	unless ( length( $self->_seq($acc) ) > 0 ) {
		die "the acc $acc was not found in this dataset! (", ref($self), ")\n";
	}
	return length( $self->_seq($acc) );
}

sub _seq {
	my ( $self, $acc, $seq ) = @_;
	Carp::confess( ref($self),
":_seq -> a severe error - you wnat to search for a fasta entry without a name of the entry!\n"
	)  unless ( defined $acc );

	$acc =~ s/lcl\|//;
	if ( defined $seq ) {
		$self->{error} .=
		  ref($self) . ":addEntry -> Acc $acc already exists in the database!\n"
		  if ( defined $self->{data}->{$acc} );
		$self->{data}->{$acc} = $seq;
	}
	elsif ( !defined $self->{data}->{$acc} ) {
		Carp::confess(
		root::get_hashEntries_as_string( $self, 3,
			"the acc $acc was not found in this dataset! (" . $self . ")" ) );

	}

	return $self->{data}->{$acc};
}

sub exists{
	my ($self, $acc) = @_;
	return defined $self->{data}->{$acc};
}

sub acc_match{
	my ($self, $acc) = @_;
	my @accs = (keys %{$self->{data}});
	return grep (/$acc/, @accs)  ;
}

sub getAsFasta {
	my ( $self, $acc ) = @_;
	my ( $seq, @return );

	$seq = $self->_seq($acc);
	push( @return, ">$acc" );

	for ( my $start = -1 ; $start < length($seq) ; $start += 60 ) {
		push( @return, substr( $seq, $start + 1, 60 ) );
	}
	return join( "\n", @return );
}

1;
