package stefans_libs::file_readers::GSEA_Pathways;

#  Copyright (C) 2013-07-23 Stefan Lang

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

#use FindBin;
#use lib "$FindBin::Bin/../lib/";
use strict;
use warnings;
use stefans_libs::flexible_data_structures::data_table;

=for comment

This document is in Pod format.  To read this, use a Pod formatter,
like 'perldoc perlpod'.

=head1 NAME

stefans_libs::file_readers::GSEA_Pathways

=head1 DESCRIPTION

Read GSEA pathways and perform analysis.

=head2 depends on


=cut

=head1 METHODS

=head2 new

new returns a new object reference of the class stefans_libs::file_readers::GSEA_Pathways.

=cut

sub new {

	my ( $class, $file ) = @_;

	my ($self);

	$self = {
		'pathways'   => {},
		'source'     => {},
		'background' => {},
		'max_bad'    => 0,
		'filemap' => {},
	};

	bless $self, $class
	  if ( $class eq "stefans_libs::file_readers::GSEA_Pathways" );
	$self->read_file($file);
	return $self;

}

sub read_file {
	my ( $self, $file ) = @_;
	return $self unless ( -f $file );
	open( IN, "<$file" ) or Carp::confess($!);
	my @temp;
	while (<IN>) {
		chomp($_);
		@temp = split( "\t", $_ );
		next if ($_=~m/^$/);
		#print $_."\n";
		$self->{'pathways'}->{ $temp[0] } = [sort keys %{$self->__genes_2_hash([@temp[ 2 .. ( @temp - 1 ) ]])} ];
		#print "I got the Pathway $temp[0] with these genes: ".join(" ",@{$self->{'pathways'}->{ $temp[0] }})."\n";
		$self->{'source'}->{$temp[0]} = $temp[1];
	}
	close ( IN );
	$self->{'filemap'} = root->filemap($file);
	return $self;
}

sub pathway_name{
	my $self = shift;
	return $self->{'filemap'}->{'filename'};
}

sub write_file {
	my ( $self, $file ) = @_;
	return $self unless ( -f $file );
	open( OUT, ">$file" ) or Carp::confess($!);
	my @temp;
	foreach my $pathway ( keys %{$self->{'pathways'}} ) {
		print OUT "$pathway\t$self->{'source'}->{$pathway}\t".join("\t",@{$self->{'pathways'}->{$pathway}} )."\n";
	}
	close ( OUT);
	return $self;
}

sub AddPathway{
	my ( $self, $pathway, $source, @genes ) =@_;
	
	Carp::confess ( "Sorry, the pathway $pathway is already defined!\n") if ( defined $self->{'pathways'}->{$pathway} );
	if ( ref($genes[0]) eq "ARRAY" ){
		$self->{'pathways'}->{$pathway} = $genes[0];
	}
	else {
		$self->{'pathways'}->{$pathway} = \@genes;
	}
	$self->{'source'}->{$pathway} = $source;
	return $self;
}

sub load_background {
	my ( $self, $bgFile, $homology_hash ) = @_;
	## either a list of gene symbols or a list of pathways with numbers...
	my ( @temp, $mode );
	open( IN, "<$bgFile" ) or die $!;
#	if ( $mode eq 'result' ) {
#		while (<IN>) {
#			chomp($_);
#			@temp = split( /\s+/, $_ );
#			if ( $temp[0] eq "max_bad" ) {
#				$self->{'max_bad'} = $temp[1];
#				next;
#			}
#			$self->{'background'}->{ $temp[0] } = $temp[1];
#		}
#	}
#	else {
		my ( @genes, $hash, $i );
		while (<IN>) {
			chomp($_);
			@temp = split( /\s+/, $_ );
			push( @genes, @temp );
		}
		if ( ref($homology_hash) eq "HASH"){
			@temp = ();
			foreach ( @genes ){
				unless ( defined $homology_hash->{$_} ){
					warn "Gene $_ not in homology hash!\n";
					next;
				}
				push (@temp, $homology_hash->{$_} );
			}
			@genes = @temp;
		}
		$hash = $self->__genes_2_hash( \@genes );
		$self->{'max_bad'} = scalar( keys %$hash );
		foreach my $pathway ( keys %{ $self->{'pathways'} } ) {
			( $self->{'background'}->{$pathway}, $i ) =
			  $self->__genes_in_list( $hash, $self->{'pathways'}->{$pathway} );
		}
#	}
	close ( IN );
	return  $self->{'background'}
}

sub __genes_2_hash {
	my ( $self, $genes ) = @_;
	my $hash;
	foreach (@$genes) {
		next unless ( $_ =~ m/\w/ );
		$hash->{$_} = 1;
	}
	return $hash;
}

sub __genes_in_list {
	my ( $self, $gene_hash, $gene_list ) = @_;
	my $i = 0;
	my @genes;
	foreach (@$gene_list) {
		if ( $gene_hash->{$_} ) {
			$genes[ $i++ ] = $_;
		}
	}
	return $i, \@genes;
}

sub analyse_genes {
	my ( $self, $genes ) = @_;
	my $hash = $self->__genes_2_hash($genes);
	my ( $i, $data_table, $gene_count );
	$gene_count = scalar( keys %$hash );
	$data_table = data_table->new();
	foreach (
		'max_count',    'bad_entries', 'matched genes',
		'pathway_name', 'gene list'
	  )
	{
		$data_table->Add_2_Header($_);
	}
	foreach my $pathway ( keys %{ $self->{'pathways'} } ) {
		( $i, $genes ) =
		  $self->__genes_in_list( $hash, $self->{'pathways'}->{$pathway} );
		$data_table->AddDataset(
			{
				'max_count'   => scalar( @{ $self->{'pathways'}->{$pathway} } ),
				'bad_entries' => $self->{'max_bad'} - $i,
				'matched genes' => $i,
				'pathway_name'  => "\\href{".$self->{'source'}->{$pathway}."}{".join(" ",split("_",$pathway))."}",
				'gene list'     => $genes,
			}
		);

	}
	$data_table->define_subset( 'data',
		[ 'max_count', 'bad_entries', 'matched genes', 'pathway_name' ] );
	$data_table->calculate_on_columns(
		{
			'function' => sub {
				if ( $_[2] > 0 ) {
					return sprintf( '%.1E',
					&more_hypergeom( $_[0], $_[1], $gene_count, $_[2], $_[3] )
				);
				}
				return '1.2';
			},
			'data_column'   => 'data',
			'target_column' => 'hypergeometric p value'
		}
	);
	#die "I have created this table:\n".$data_table->AsString();
	$self->{'description'} = "Pathways were analysed using a hypergeometric test implemented in perl.\n".
	"A total of ".$self->Pathway_count(). " Pathways were analysed using a total of $gene_count enriched genes selected from $self->{'max_bad'} total genes.\n";
	return $data_table;
}

sub Pathway_count {
	my ( $self ) = @_;
	return scalar( keys %{$self->{'pathways'}});
}

	# There are m "bad" and n "good" balls in an urn.
	# Pick N of them. The probability of i or more successful selection +s:
	# (m!n!N!(m+n-N)!)/(i!(n-i)!(m+i-N)!(N-i)!(m+n)!)
	#&more_hypergeom( <max good in pathway>, <number of total possible but not selected genes>,<number of draws performed>, <identified genes from this pathway>, <pathway name> )
	
sub more_hypergeom {
	my ( $n, $m, $N, $i, $pathway ) = @_;
	return 1 unless ( defined $n );
	if ( $i > $n ) {
		## This is normaly a deadly problem!
		Carp::confess(
"You must not draw more than the possible amount of things from your urn! $i > $n!!"
		);
		warn
"You claim to have gotten $i hits to a pathway having a max_hit_count of $n.\nI do not belive you and therefore set the result to 2\n";
		return 2;
	}
	Carp::confess("You have an error in the script as $m + $n - $N is below 0! (you draw more balls than are in the urn!)\n")
	  if ( $m + $n - $N < 0 );
	my $p1 = &hypergeom( $n, $m, $N, $i );
	unless ( $i + 2 > $N || $i + 2 > $n ) {
		my $p2 = &hypergeom( $n, $m, $N, $i + 2 );
		return $p1 if ( $p1 > 0.1 );
		return 1 - $p1 if ( $p1 < $p2 );
	}
	return $p1 / 2;
}

sub logfact {
	return gammln( shift(@_) + 1.0 );
}

sub hypergeom {


	my ( $n, $m, $N, $i ) = @_;

	my $loghyp1 =
	  logfact($m) + logfact($n) + logfact($N) + logfact( $m + $n - $N );
	my $loghyp2 =
	  logfact($i) +
	  logfact( $n - $i ) +
	  logfact( $m + $i - $N ) +
	  logfact( $N - $i ) +
	  logfact( $m + $n );
	return exp( $loghyp1 - $loghyp2 );
}

sub gammln {
	my $xx  = shift;
	my @cof = (
		76.18009172947146,   -86.50532032941677,
		24.01409824083091,   -1.231739572450155,
		0.12086509738661e-2, -0.5395239384953e-5
	);
	my $y = my $x = $xx;
	my $tmp = $x + 5.5;
	$tmp -= ( $x + .5 ) * log($tmp);
	my $ser = 1.000000000190015;
	for my $j ( 0 .. 5 ) {
		$ser += $cof[$j] / ++$y;
	}
	Carp::confess("Hej we must not have a $x of 0!\n") if ( $x == 0 );
	-$tmp + log( 2.5066282746310005 * $ser / $x );
}

1;
