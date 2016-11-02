package stefans_libs::file_readers::gtf_file;

#  Copyright (C) 2016-11-02 Stefan Lang 

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

use stefans_libs::flexible_data_structures::data_table;
use base 'data_table';

=head1 General description

reads gtf files used to annotate a genome in UCSC space.

From the format description on http://www.ensembl.org/info/website/upload/gff.html

Fields must be tab-separated. Also, all but the final field in each feature line must contain a value; "empty" columns should be denoted with a '.'

    seqname - name of the chromosome or scaffold; chromosome names can be given with or without the 'chr' prefix. Important note: the seqname must be one used within Ensembl, i.e. a standard chromosome name or an Ensembl identifier such as a scaffold ID, without any additional content such as species or assembly. See the example GFF output below.
    source - name of the program that generated this feature, or the data source (database or project name)
    feature - feature type name, e.g. Gene, Variation, Similarity
    start - Start position of the feature, with sequence numbering starting at 1.
    end - End position of the feature, with sequence numbering starting at 1.
    score - A floating point value.
    strand - defined as + (forward) or - (reverse).
    frame - One of '0', '1' or '2'. '0' indicates that the first base of the feature is the first base of a codon, '1' that the second base is the first base of a codon, and so on..
    attribute - A semicolon-separated list of tag-value pairs, providing additional information about each feature.


=cut
sub new {

    my ( $class, $debug ) = @_;
    my ($self);
    $self = {
        'debug'           => $debug,
        'arraySorter'     => arraySorter->new(),
        'header_position' => { 
            'seqname' => 0,
            'source' => 1,
            'feature' => 2,
            'start' => 3,
            'end' => 4,
            'score' => 5,
            'strand' => 6,
            'frame' => 7,
            'attribute' => 8,
        },
        'default_value'   => [],
        'header'          => [
            'seqname',
            'source',
            'feature',
            'start',
            'end',
            'score',
            'strand',
            'frame',
            'attribute',       ],
        'data'            => [],
        'index'           => {},
        'last_warning'    => '',
        'subsets'         => {}
    };
    bless $self, $class if ( $class eq "stefans_libs::file_readers::gtf_file" );

    return $self;
}


## two function you can use to modify the reading of the data.

sub pre_process_array{
	my ( $self, $data ) = @_;
	##you could remove some header entries, that are not really tagged as such...
	my $t;
	if ( @$data[0] =~ m/^#/ ){
		$t = shift ( @$data );
		$t =~ s/^#//;
		$self->Add_2_Description( $t );
	}
	return 1;
}

sub After_Data_read {
	my ($self) = @_;
	## process the atribute into a set of columns
	#gene_id "ENSG00000223972.5"; gene_type "transcribed_unprocessed_pseudogene"; gene_status "KNOWN"; gene_name "DDX11L1"; level 2; havana_gene "OTTHUMG00000000961.2";
	my (@values, $tmp, $helper, $a, @p);
	$helper = data_table->new();
	$helper -> {'string_separator'} = '"';
	$helper -> {'line_separator'} = " ";
	
	for ( my $i = 0; $i < $self->Lines(); $i ++){
		@{@{$self->{'data'}}[$i]}[8] =~ s/;$//;
		$tmp = [ split( /; /, @{@{$self->{'data'}}[$i]}[8])];
		print "And I got these values from the split_line call: ".join(", ",@$tmp)."\n";
		@values = undef;
		for ( $a=0; $a < @$tmp; $a++ ){
			@p = @{$helper->__split_line(@$tmp[$a])};
			push ( @values, $p[1]);
			$self->Add_2_Header ($p[0]) if ( $i == 0);
		}
		push (@{@{$self->{'data'}}[$i]}, @values );
	}
	$self = $self->drop_column ( 'attribute' );
	return $self;
}





1;
