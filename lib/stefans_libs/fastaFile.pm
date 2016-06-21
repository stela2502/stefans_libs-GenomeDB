package fastaFile;

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
	my ( $class, $filename ) = @_;

	my ($self);
	$self = {
		header => undef,
		seq    => undef,
		length => undef
	};

	bless( $self, $class ) if ( $class =~ m/fastaFile/ );
	$self->AddFile($filename) if ( defined $filename );
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

	my ( $seq, $i );
	$i = 0;
	open( IN, "<$filename" ) or die "Konnte $filename nicht öffnen!\n";

	while (<IN>) {
		if ( $_ =~ m/^>([\w\d]*)/ ) {
			if ( defined $self->{header} ) {
				die
"Mehrere Fasta Einträge in einem File => return value == array of fastaFiles!\n";
			}

			$self->Name($1);
		}

		#    if ( $_ =~ m/[agctGACTnN]*/){
		else {
			chop $_;
			$seq = "$seq$_";

			#       print "SeqLine Nr.",$i++,"\n";
		}
		$self->Seq($seq);
	}
	close(IN);
	print "Sequence infos added!\n";
	return 1;
}

sub parseString {
	my ( $self, $string ) = @_;
	my @iupac = (
		'a', 'c', 'g', 't', 'm', 'r', 'w', 's',
		'y', 'k', 'v', 'h', 'd', 'b', 'x', 'n'
	);
	my $str = join ("",@iupac);
	
	$str .= uc($str);
	print "IPUAC bases $str\n";
	$string = join( "", split("\n", $string));
	my ( $seq, $acc);
	$acc = $1 if ( $string =~ m/>([\w\d]+)/ );
	print "We got a acc $acc\n";
	$string =~ s/>$acc//;
	$seq = $1 if ( $string =~ m/^([acgtmrwsykvhdbxnACGTMRWSYKVHDBXN]+)$/);
	print "we got a seq '$seq'\n";
	
	$self->Name($acc);
	$self->Seq($seq);
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
	my ( $self, $start, $end ) = @_;
	my ($seq);

	if ( defined $start ) {
		if ( defined $end ) {
			return substr( $self->Seq, $start, $end - $start );
		}
		else {
			return substr( $self->Seq, $start, length( $self->Seq ) - $start );
		}
	}
	return $self->Seq;
}

=head2 WriteAsFasta

WriteAsFasta wirtes the internal sequence representation in fasta format.

=header3 arguments

[0]: the absolute filename to write the sequence to.

[1]: position in basepairs where the sequence should start

[2]: position in basepairs where the sequence should end


=cut

sub WriteAsFasta {
	my ( $self, $filename, $startSeq, $endSeq ) = @_;

	my ($seq);

	open( OUT, ">$filename" ) or die "Konnte File $filename nicht anlegen!\n";

	print OUT ">", $self->Name(), "\n";
	$seq = $self->Get_SubSeq( $startSeq, $endSeq );

	for ( my $start = -1 ; $start < length($seq) ; $start += 60 ) {
		print OUT substr( $seq, $start + 1, 60 ), "\n";
	}
	print "Sequence written as $filename in FASTA format\n";
	return 1;
}

=head2 Name

Name is a wrapper around the fasta idetification string.

It returns the fasta idetification string if it is defined.

=cut

sub Name {
	my ( $self, $name ) = @_;
	$self->{header} = $name if ( defined $name );
	return $self->{header};
}

=head2 Seq

Name is a wrapper around the fasta seqeunce.

It returns the fasta seqeunce if it is defined.

=cut

sub Seq {
	my ( $self, $seq ) = @_;
	if ( defined $seq ){
		if ( $seq =~ m/^[nNxXAaCcGgTtWwRrMmSsYyKkVvHhDdBb]+$/){
			$self->{'seq'} = $seq ;
		}
		else {
			Carp::confess( ref($self)."::Seq -> we have got a not usable sequence $seq\n");
		}
	}
	return $self->{'seq'};
}

1;
