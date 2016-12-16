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
use stefans_libs::file_readers::bed_file;
use stefans_libs::fastaFile;
use base 'data_table';
use PDL;

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
        'slice_length' => 1e+6,
        'chr_path' => '',
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



sub get_cDNA_4_transcript {
	my ( $self, $id, $seqpath ) = @_;
	$self->{'chr_path'} ||= $seqpath;
	$seqpath ||= $self->{'chr_path'};
	
	unless ( defined $self->{'exons'} ) {
		$self->{'exons'} = $self->_copy_without_data();
		my $t = $self->createIndex('feature')->{'exon'};
		unless ( ref($t) eq "ARRAY") {
			Carp::confess( "Why is the index -> exon not an array??".root->print_perl_var_def(  $self->createIndex('feature') ). "\n");
		}
		@{$self->{'exons'}->{'data'}} = @{$self->{'data'}}[@$t];
	}
	Carp::confess ( "I need a seqpath as second argument!" ) unless ( -d $seqpath) ;
	my $ids = $self->{'exons'}->createIndex ( 'transcript_id' )->{$id };
	unless ( defined $ids ) {
		warn "ID $id not found!\n";
		return "";
	}
	## by definition this has to be on exactly one chromosome
	my $chr = @{@{$self->{'exons'}->{'data'}}[@$ids[0]]}[0];
	my $gname = @{@{$self->{'exons'}->{'data'}}[@$ids[0]]}[ $self->{'exons'}->Header_Position('gene_name')];
	$self->{'fastafiles'} ||= {};
	unless ( defined  $self->{'fastafiles'}->{$chr} ){
		print "read sequence from $chr\n";
		$self->{'fastafiles'}->{$chr} = fastaFile->new();
		if ( -f "$seqpath/$chr.fa" ) {
			$self->{'fastafiles'}->{$chr} -> AddFile("$seqpath/$chr.fa" );
		}elsif ( -f "$seqpath/$chr.fa.gz"){
			$self->{'fastafiles'}->{$chr} -> AddFile("$seqpath/$chr.fa.gz" );
		}
		 
	}
	my $tmp = $self->_copy_without_data();
	push( @{$tmp->{'data'}}, @{$self->{'exons'}->{'data'}}[@$ids] );
	$tmp = $tmp -> Sort_by( [['start', 'numeric']]);
	my $seq = '';
	my $ff = fastaFile->new();
	
	for ( my $i = 0; $i < $tmp->Lines(); $i ++ ) {
		
		$seq .= $self->{'fastafiles'}->{$chr} -> Get_SubSeq ( @{@{$tmp->{'data'}}[$i]}[3,4] );
	}
	$seq = uc($seq);
	
	if ( @{@{$self->{'data'}}[@$ids[0]]}[6] eq "-"){
		$seq = $ff->revComplement( $seq );
	}
	$ff->Create( "$chr:$id $gname cdna right strand", $seq);
	return $ff->AsFasta();
	
}

sub After_Data_read {
	my ($self) = @_;
	print "gtf file has been read\n";
	## process the atribute into a set of columns
	#gene_id "ENSG00000223972.5"; gene_type "transcribed_unprocessed_pseudogene"; gene_status "KNOWN"; gene_name "DDX11L1"; level 2; havana_gene "OTTHUMG00000000961.2";
	my ($values, $tmp, $helper, $a, @p);
	$helper = data_table->new();
	$helper -> {'string_separator'} = '"';
	$helper -> {'line_separator'} = "[ =]";
	my $added = {};
	for ( my $i = 0; $i < $self->Lines(); $i ++){
		@{@{$self->{'data'}}[$i]}[8] =~ s/;$//;
		$tmp = [ split( /; ?/, @{@{$self->{'data'}}[$i]}[8])];
		#print "And I got these values from the split_line call: ".join(", ",@$tmp)."\n";
		$values= ();
		for ( $a=0; $a < @$tmp; $a++ ){
			@p = @{$helper->__split_line(@$tmp[$a])};
			$values ->{$p[0]} = $p[1];
			#print "$p[0] => $p[1]; ";
			unless ( $added->{$p[0]} ){
				#print "I add the column $p[0]\n";
				( $added->{$p[0]} ) = $self->Add_2_Header ($p[0]);
			}
		}
		#warn "\$added = ".root->print_perl_var_def( $added).";\n" if ( $self->{debug});
		
		#die "\n";
		foreach ( keys %$values ) {
			@{@{$self->{'data'}}[$i]}[$added->{$_} ] = $values->{$_};
		}
		if ( $i % 10000 == 0) {
			print "Processed line $i\n". root->print_perl_var_def( $self->{'header'}) 
			 if ( $self->{'debug'} );
		}
	}
	$self->{'__max_header__'} = scalar( @{$self->{'header'}});
	$self = $self->drop_column ( 'attribute' );
	return $self;
}

sub get_chr_subID_4_start {
	my ( $self, $start ) = @_;
	$start ||=1;
	return floor(($start / $self->{'slice_length'}));
}

sub get_pdls_4_chr {
	my ( $self, $chr, $start ) = @_;
	my ($data);
	$self->{'PDL'} ||={};
	$self->{'PDL'}->{$chr} ||= [];
	$self->{'subset_4_PDL'} ||= {};
	$self->{'subset_4_PDL'}->{$chr} ||= [];
	unless ( $self->Header_Position('line_id') ){
		$self->add_column('line_id', [ 0..($self->Rows()-1)] );
	}
	unless ( defined $self->{'subsetter'} ) {
		my @col_ids = $self -> define_subset( 'matcher', ['seqname', 'start', 'end']);
		$self->{'subsetter'} = stefans_libs::file_readers::bed_file ->new();
		for ( my $i = 0; $i < $self->Lines(); $i ++) {
			push ( @{$self->{'subsetter'}->{'data'}}, [@{@{$self->{'data'}}[$i]}[@col_ids]] );
		}
	} 
	my $chr_id = $self->get_chr_subID_4_start( $start );
	#Carp::confess ( $self->AsString() );
	unless ( defined @{$self->{'PDL'}->{$chr}}[$chr_id] ) {
		print "I create the PDL for chr $chr\n";
		
		my ($regions_start, $region_end );
		$regions_start = $chr_id * $self->{'slice_length'} -10;
		$region_end = ($chr_id+1) * $self->{'slice_length'} +10;
		@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id] = $self->_copy_without_data();
		@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id]->{'data'} = [ 
			@{$self->{'data'}}[$self->{'subsetter'}->efficient_match_chr_position( $chr,$regions_start, $region_end )] 
		];
		
		#print "I create the PDL for chr $chr and id $chr_id and got ".@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id]->Lines()." lines back\n";
		if ( @{$self->{'subset_4_PDL'}->{$chr}}[$chr_id]->Rows == 0 ){
			@{$self->{'PDL'}->{$chr}}[$chr_id] = '';
			return ();
		}
		#print "I got ". $self->{'PDL'}->{$chr}->Rows. " entries for chr $chr\n".join("\t", @{@{$self->{'PDL'}->{$chr}->{'data'}}[0]})."\n";
	
		@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id] -> add_column ( 'INDEX', [0..(@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id]->Rows()-1)]);
		@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id] -> define_subset ( 'PDL', [ 'INDEX','start','end', 'line_id']);
		@{$self->{'PDL'}->{$chr}}[$chr_id] = @{$self->{'subset_4_PDL'}->{$chr}}[$chr_id] -> GetAsObject('PDL')->GetAsPDL();
	}
	return @{$self->{'PDL'}->{$chr}}[$chr_id] ;
}

sub read_file {
	 my ( $self, $filename, $lines ) = @_;
	 return undef unless ( -f $filename );
	 if ( -f $filename.".xls" ) {
	 	my $data_table = data_table->new();
	 	$data_table -> read_file ( $filename.".xls" ,$lines);
	 	$self->Add_2_Header(  $data_table->{'header'}  );
	 	$self->{'data'} = $data_table->{'data'};
	 }
	 else {
	 	$self->SUPER::read_file( $filename, $lines );
	 }
	 return $self;
}

sub print_as_table {
	my ( $self,$outfile ) = @_;
	my @temp;
	@temp = split( "/", $outfile );
	pop(@temp);
	mkdir( join( "/", @temp ) ) unless ( -d join( "/", @temp ) );
	unless ( $outfile =~ m/xls$/ ) {
		$outfile .= ".xls";
	}
	open( OUT, " >$outfile" )
	  or Carp::confess(
		ref($self)
		  . "::print2file -> I can not create the outfile '$outfile'\n$!\n" );
		my $str = '';
	my @default_values;
	my @line;
	foreach my $description_line ( @{ $self->{'description'} } ) {
		$description_line =~ s/\n/\n#/g;
		$str .= "#$description_line\n";
	}
	$str .= '#' unless ( $self->{'no_doubble_cross'} );
	$str .= $self->SUPER::__header_as_string();
	@default_values = $self->getAllDefault_values();
	$self->Max_Header() = scalar( @{ $self->{'header'} } )
	  unless ( defined $self->Max_Header() );
	foreach my $data ( @{ $self->{'data'} } ) {
		@line = @$data;
		for ( my $i = 0 ; $i < $self->Max_Header() ; $i++ ) {
			unless ( defined $line[$i] ) {
				$line[$i] = $default_values[$i];
			}
			$line[$i] = '"' . $line[$i] . '"'
			  if ( $self->__col_format_is_string($i) );
		}
		$str .= join( $self->line_separator(), @line ) . "\n";
	}
	print OUT $str;
	close(OUT);
	print "all data written to '$outfile'\n";
	return $outfile;
}


sub get_subset_4_PDL_ids {
	my ( $self, $chr,$start, $ids ) = @_;
	my $chr_id = $self->get_chr_subID_4_start( $start );
	return @{@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id]->GetAsArray('line_id')}[@$ids] ;
}

1;
