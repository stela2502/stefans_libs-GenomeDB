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
		'slice_length'    => 1e+6,
		'chr_path'        => '',
		'arraySorter'     => arraySorter->new(),
		'header_position' => {
			'seqname'   => 0,
			'source'    => 1,
			'feature'   => 2,
			'start'     => 3,
			'end'       => 4,
			'score'     => 5,
			'strand'    => 6,
			'frame'     => 7,
			'attribute' => 8,
		},
		'default_value' => [],
		'header'        => [
			'seqname', 'source', 'feature', 'start',
			'end',     'score',  'strand',  'frame',
			'attribute',
		],
		'data'         => [],
		'index'        => {},
		'last_warning' => '',
		'subsets'      => {}
	};
	bless $self, $class if ( $class eq "stefans_libs::file_readers::gtf_file" );

	return $self;
}

## two function you can use to modify the reading of the data.

sub pre_process_array {
	my ( $self, $data ) = @_;
	##you could remove some header entries, that are not really tagged as such...
	my $t;
	if ( @$data[0] =~ m/^#/ ) {
		$t = shift(@$data);
		$t =~ s/^#//;
		$self->Add_2_Description($t);
	}
	return 1;
}

=head2 efficient_match_chr_position ( $chr, $start, $end, $max_dist )

match the chromosomal area to the own data and returns the own matching row numbers.

=cut

sub efficient_match_chr_position {
	my ( $self, $chr, $start, $end, $max_dist ) = @_;
	$chr = $self->_checkChr($chr);
	$max_dist ||= 0;
	$end ||= $start;
	local $SIG{__WARN__} = sub { };
	my $rep_pdl = $self->get_pdls_4_chr( $chr, $start );
	if ( ref($rep_pdl) eq "PDL" ) {
		my $t1         = $rep_pdl->slice(',1') <= $end + $max_dist;
		my $t2         = $rep_pdl->slice(',2') >= $start - $max_dist;
		my @intron_ids = list( transpose( which( $t1 + $t2 == 2 ) ) );
		return $self->get_subset_4_PDL_ids( $chr, $start, \@intron_ids );
		return @{ $self->{'subset_4_PDL'}->{$chr}->GetAsArray('line_id') }
		  [@intron_ids];
	}
	return ();
}

=head2 efficient_match_chr_position_plus_one ( $chr, $start, $end, $max_dist )

match the chromosomal area to the own data and returns the own matching row numbers.

=cut

sub efficient_match_chr_position_plus_one {
	my ( $self, $chr, $start, $end, $max_dist ) = @_;
	$end ||= $start;
	my $add = 10e+7;
	$end += $add;
	$max_dist = 0;
	my @return = sort {
		@{ @{ $self->{'data'} }[$a] }[3] <=> @{ @{ $self->{'data'} }[$b] }[3]
	  }    ## order by start
	  $self->efficient_match_chr_position( $chr, $start, $end, $max_dist );
	$end -= $add;
	my @not_match;

	for ( my $i = 0 ; $i < @return ; $i++ ) {
		unless (@{ @{ $self->{'data'} }[ $return[$i] ] }[4] > $start
			and @{ @{ $self->{'data'} }[ $return[$i] ] }[3] < $end )
		{
			## OK the first one is enough
#warn "I have a not matching entry as first entry (1)?? $i\n";
#warn "I return this:".join( "\n",	map { join( "\t", @{@{ $self->{'data'} }[$_]} ) }  @return[0..$i])."\n";
			return @return[ 0 .. $i ];
		}    #else {
		 #	warn "Matching $i $return[$i]:@{@{$self->{'data'}}[$return[$i]]}[4] > $start and @{@{$self->{'data'}}[$return[$i]]}[3] <  $end \n";
		 #}
	}

#warn "ERROR!!!\n"."efficient_match_chr_position_plus_one: all of the ".scalar(@return)." entries did match?!\n";
	## so now I have @return matching hits and shift(@not_match) the closes not matching one
	return (@return);

#warn "efficient_match_chr_position_plus_one($chr, $start, $end, $max_dist ) got '". join("', '", @return)."' (last is +1)\n";
#warn join( "\n",	map { join( "\t", @{@{ $self->{'data'} }[$_]}[1..6] ) } @return )."\n";

	Carp::confess("must not reach this point\n");
}

sub get_cDNA_4_transcript {
	my ( $self, $id, $seqpath ) = @_;
	$self->{'chr_path'} ||= $seqpath;
	$seqpath ||= $self->{'chr_path'};

	unless ( defined $self->{'exons'} ) {
		$self->{'exons'} = $self->_copy_without_data();
		my $t = $self->createIndex('feature')->{'exon'};
		unless ( ref($t) eq "ARRAY" ) {
			Carp::confess( "Why is the index -> exon not an array??"
				  . root->print_perl_var_def( $self->createIndex('feature') )
				  . "\n" );
		}
		@{ $self->{'exons'}->{'data'} } = @{ $self->{'data'} }[@$t];
	}
	Carp::confess("I need a seqpath as second argument!")
	  unless ( -d $seqpath );
	my $ids = $self->{'exons'}->createIndex('transcript_id')->{$id};
	unless ( defined $ids ) {
		warn "ID $id not found!\n";
		return "";
	}
	## by definition this has to be on exactly one chromosome
	my $chr   = @{ @{ $self->{'exons'}->{'data'} }[ @$ids[0] ] }[0];
	my $gname = @{ @{ $self->{'exons'}->{'data'} }[ @$ids[0] ] }
	  [ $self->{'exons'}->Header_Position('gene_name') ];
	$self->{'fastafiles'} ||= {};
	unless ( defined $self->{'fastafiles'}->{$chr} ) {
		print "read sequence from $chr\n";
		$self->{'fastafiles'}->{$chr} = fastaFile->new();
		if ( -f "$seqpath/$chr.fa" ) {
			$self->{'fastafiles'}->{$chr}->AddFile("$seqpath/$chr.fa");
		}
		elsif ( -f "$seqpath/$chr.fa.gz" ) {
			$self->{'fastafiles'}->{$chr}->AddFile("$seqpath/$chr.fa.gz");
		}

	}
	my $tmp = $self->_copy_without_data();
	push( @{ $tmp->{'data'} }, @{ $self->{'exons'}->{'data'} }[@$ids] );
	$tmp = $tmp->Sort_by( [ [ 'start', 'numeric' ] ] );
	my $seq = '';
	my $ff  = fastaFile->new();

	for ( my $i = 0 ; $i < $tmp->Lines() ; $i++ ) {

		$seq .= $self->{'fastafiles'}->{$chr}
		  ->Get_SubSeq( @{ @{ $tmp->{'data'} }[$i] }[ 3, 4 ] );
	}
	$seq = uc($seq);

	if ( @{ @{ $self->{'data'} }[ @$ids[0] ] }[6] eq "-" ) {
		$seq = $ff->revComplement($seq);
	}
	$ff->Create( "$chr:$id $gname cdna right strand", $seq );
	return $ff->AsFasta();

}

sub After_Data_read {
	my ($self) = @_;
	print "gtf file has been read\n";
	## process the atribute into a set of columns
#gene_id "ENSG00000223972.5"; gene_type "transcribed_unprocessed_pseudogene"; gene_status "KNOWN"; gene_name "DDX11L1"; level 2; havana_gene "OTTHUMG00000000961.2";

	my ( $values, $tmp, $helper, $a, @tmp, @p );
	$helper                       = data_table->new();
	$helper->{'string_separator'} = '"';
	$helper->{'line_separator'}   = "[ =]";
	my $added = {};
	for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {
		@{ @{ $self->{'data'} }[$i] }[8] =~ s/;$//;
		@tmp = split( /; ?/, @{ @{ $self->{'data'} }[$i] }[8] );
		Carp::confess(
			    ref($self)
			  . "::After_Data_read -> line $1 '"
			  . @{ @{ $self->{'data'} }[$i] }[8]
			  . "' could not be split by /; ?/ - please adjust the pattern match\n"
		) unless (@tmp);
		if ( @tmp == 1 ) {
			warn "This is no gtf3 file\n";
			last;
		}
		$values = ();
		for ( $a = 0 ; $a < @tmp ; $a++ ) {
			$tmp[$a] =~ s/"$//;
			@p = $tmp[$a] =~ m/([_\w]*)[ =]"?(.*)/g;
			Carp::confess(
				    ref($self)
				  . "::After_Data_read -> line $1 '"
				  . $tmp[$a]
				  . "' could not be split by /([_\\w]*)[ =]\"?(.*)/ - please adjust the pattern match\n"
				  . @{ @{ $self->{'data'} }[$i] }[8]
				  . "\nThe while table line:\n"
				  . root->print_perl_var_def( $self->get_line_asHash($i) )
				  . ";\n" )
			  unless ( @p > 1 );
			$values->{ $p[0] } = $p[1];
			unless ( $added->{ $p[0] } ) {
				( $added->{ $p[0] } ) = $self->Add_2_Header( $p[0] );
			}
		}
		foreach ( keys %$values ) {
			@{ @{ $self->{'data'} }[$i] }[ $added->{$_} ] = $values->{$_};
		}
		if ( $i % 10000 == 0 ) {
			print "Processed line $i\n"
			  . root->print_perl_var_def( $self->{'header'} )
			  if ( $self->{'debug'} );
		}
	}
	$self->{'__max_header__'} = scalar( @{ $self->{'header'} } );
	$self->drop_column('attribute')
	  if ( defined $self->Header_Position('attribute') );
	$self->drop_all_indecies();
	$self->{'subsets'} = {};
	print "Finished loading the gtf file\n";
	return $self;
}

sub _checkChr {
	my ( $self, $chr ) = @_;
	unless ( $chr =~ m/^chr/ ) {
		return $chr;
	}
	## we use --add-chrname in the hisat2 call
	## and the additional chr has to go
	if ( $chr =~ m/^chr[\dXYxymM]*$/ ) {
		## ok
		return $chr;
	}
	if ( $chr =~ m/^chr(.*)/ ) {
		return $1;
	}
	## OK none of the above things were true
	return $chr;
}

sub get_chr_subID_4_start {
	my ( $self, $chr, $start ) = @_;
	$start ||= 1;
	unless ( defined $self->{'__GeneFreeSplits__'} ) {
		$self->{'__GeneFreeSplits__'} =
		  stefans_libs::file_readers::bed_file->new();
		my $chr_index = $self->createIndex('seqname');
		my @ends      = @{ $self->GetAsArray('end') };
		my ($max);
		foreach my $chr (sort keys %$chr_index ) {
			$max = $self->this_max( @ends[ @{ $chr_index->{$chr} } ] );
			for ( my $i = 0 ; $i < $max + $self->{'slice_length'} ; $i += $self->{'slice_length'} ) {
				push(
					@{ $self->{'__GeneFreeSplits__'}->{'data'} },
					[ $chr, $i, $i + $self->{'slice_length'} -1 ]
				);
			}
		}
	}
	return $self->{'__GeneFreeSplits__'}
	  ->efficient_match_chr_position( $chr, $start );
}

sub GeneFreeSplits {
	my ( $self, $split_feature ) = @_;
	$split_feature ||= 'gene';
	if ( defined $self->{'__GeneFreeSplits__'} ) {
		return $self->{'__GeneFreeSplits__'};
	}
	$self->{'__GeneFreeSplits__'} = stefans_libs::file_readers::bed_file->new();
#$self->add_column( 'line_id', [ 0 .. ( $self->Rows() - 1 ) ] );
	my $genes =
	  $self->select_where( 'feature', sub { $_[0] eq $split_feature } );
	$genes->{'slice_length'} = $self->{'slice_length'};
	if ( $genes->Lines() == 0 ) {
		Carp::confess(
			    "the gtf file does not contain the feature '$split_feature'\n"
			  . "I can not device a perfect split based on a none exisiting efature\n"
		);
	}
	my $chr_index = $self->createIndex('seqname');
	my @ends      = @{ $self->GetAsArray('end') };
	my ( $max, $next_start, $last_start );
	foreach my $chr (sort keys %$chr_index ) {
		$max        = $self->this_max( @ends[ @{ $chr_index->{$chr} } ] );
		$last_start = 0;
	  POSITION:
		for (
			my $i = $self->{'slice_length'} ;
			$i < $max + $self->{'slice_length'} ;
			$i += $self->{'slice_length'}
		  )
		{
			$next_start = $genes->goOn( $chr, $last_start, $i, $max, $self );
			unless ( defined $next_start ) {
$last_start = @{ @{ $self->{'__GeneFreeSplits__'}->{'data'} }
				  [ $self->{'__GeneFreeSplits__'}->Lines() - 1 ] }[2] +1;
				next POSITION;
			}
			while ( defined $next_start ) {
				$next_start =
				  $genes->goOn( $chr, $last_start, $next_start + 51, $max, $self );
			}
			$last_start = @{ @{ $self->{'__GeneFreeSplits__'} ->{'data'} }
				  [ $self->{'__GeneFreeSplits__'}->Lines() - 1 ] }[2] +1;
		}
	}
	## I need to drop the 'line_id' column in the $self->{'__GeneFreeSplits__'}
	#$self->{'__GeneFreeSplits__'}->drop_column('line_id');
	return $self->{'__GeneFreeSplits__'};
}

sub goOn {
	my ( $self, $chr, $start, $pos, $max_pos, $add ) = @_;
	$start ||= 0;
	#print "We try to find the first matches: $chr, $start, $pos, $max_pos\n";
	my @ids = $self->efficient_match_chr_position( $chr, $pos - 50, $pos + 50 );
	#print "And we do pass the efficient match\n";
	if ( scalar(@ids) == 0 ) {
		## take that?
		#print "And we can in fact use this!\n";
		$pos = $max_pos if ( $pos > $max_pos );
		push( @{ $add->{'__GeneFreeSplits__'}->{'data'} }, [ $chr, $start, $pos -1 ] );
		return undef;
	}
	my $r = $self->this_max( $self->get_chr_end_4_ids( @ids ) )
	  ;    ## the most likely next empty place.
	if ( $r == 0 ) {
		## what a crap"!
		die "I have the ids "
		  . join( ", ", @ids )
		  . " translating to starts at "
		  . join( ", ", $self->get_chr_end_4_ids( @ids ) )
		  . " an I still get a max as $r??\n";
	}
	return $r;
}

sub get_chr_end_4_ids {
	my ( $gtf, @lines ) = @_;
	return 0 unless ( scalar(@lines) );
	return map {
		if ( defined $_ ) {
			print "mapper line identified $_: "
			  . join( ";", @{ @{ $gtf->{'data'} }[$_] } ) . "\n";
			@{ @{ $gtf->{'data'} }[$_] }[4];
		}
	} @lines;
}

sub this_max {
	my $self = shift;
	my $max  = 0;
	map { $max = $_ if ( $max < $_ ) } @_;
	return $max;
}

sub get_pdls_4_chr {
	my ( $self, $chr, $start ) = @_;
	my ($data);
	$chr = $self->_checkChr($chr);
	$self->{'PDL'} ||= {};
	$self->{'PDL'}->{$chr} ||= [];
	foreach ( keys %{ $self->{'PDL'} } ) {
		delete( $self->{'PDL'}->{$_} ) unless ( $_ eq $chr );
	}
	$self->{'subset_4_PDL'} ||= {};
	$self->{'subset_4_PDL'}->{$chr} ||= [];
	foreach ( keys %{ $self->{'subset_4_PDL'} } ) {
		delete( $self->{'subset_4_PDL'}->{$_} ) unless ( $_ eq $chr );
	}
	unless ( defined $self->Header_Position('line_id') ) {

		#print "I define my own line_id:\n";
		$self->add_column( 'line_id', [ 0 .. ( $self->Rows() - 1 ) ] );

   #print "\$exp = ".root->print_perl_var_def($self->get_line_as_hash(2)).";\n";
	}
	unless ( defined $self->{'subsetter'} ) {
		my @col_ids =
		  $self->define_subset( 'matcher', [ 'seqname', 'start', 'end' ] );
		$self->{'subsetter'} = stefans_libs::file_readers::bed_file->new();
		for ( my $i = 0 ; $i < $self->Lines() ; $i++ ) {
			push(
				@{ $self->{'subsetter'}->{'data'} },
				[ @{ @{ $self->{'data'} }[$i] }[@col_ids] ]
			);
		}
	}
	my ($chr_id) = $self->get_chr_subID_4_start($chr,$start);

	#print "I got the chr_id $chr_id for the start $start\n";
	#Carp::confess ( $self->AsString() );
	unless ( defined @{ $self->{'PDL'}->{$chr} }[$chr_id] ) {
		my ( $regions_start, $region_end );
		## use the new __GeneFreeSplits__ object
		( $regions_start, $region_end ) =
		  @{ @{ $self->{'__GeneFreeSplits__'}->{'data'} }[$chr_id] }[ 1, 2 ];

		@{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id] =
		  $self->_copy_without_data();

		#warn "I subset to $chr,$regions_start, $region_end \n";
		@{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]->{'data'} = [
			@{ $self->{'data'} }[
			  $self->{'subsetter'}->efficient_match_chr_position(
				  $chr,
				  $regions_start - 1000,
				  $region_end + 1000
			  )
			]
		];

		print
		  "END\nnew mapper/$chr_id for chr $chr:$regions_start-$region_end (n="
		  . @{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]->Rows() . ") ";

 #print $self->{'subsetter'}->AsString(), "\n$chr, $regions_start, $region_end";
		if ( @{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]->Rows == 0 ) {
			@{ $self->{'PDL'}->{$chr} }[$chr_id] = '';
			return ();
		}

		@{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]->add_column(
			'INDEX',
			[
				0 .. (
					@{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]->Rows() - 1 )
			]
		);
		@{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]
		  ->define_subset( 'PDL', [ 'INDEX', 'start', 'end', 'line_id' ] );

#print "The 'PDL' subset contains these columns:",join(", ",@{$self->{'subset_4_PDL'}->{$chr}}[$chr_id]->Header_Position('PDL') )."\n";
#print "This is what should built up the pdl for chr $chr:\n". @{$self->{'subset_4_PDL'}->{$chr}}[$chr_id] -> GetAsObject('PDL')->AsString();
		@{ $self->{'PDL'}->{$chr} }[$chr_id] =
		  @{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]->GetAsObject('PDL')
		  ->GetAsPDL();

#print "I got a object of class". ref(@{$self->{'PDL'}->{$chr}}[$chr_id]). " that can be used to locate genomic areas on $chr\n";

	}
	return @{ $self->{'PDL'}->{$chr} }[$chr_id];
}

sub read_file {
	my ( $self, $filename, $lines ) = @_;
	return undef unless ( -f $filename );
	if ( -f $filename . ".xls" ) {
		my $data_table = data_table->new();
		$data_table->read_file( $filename . ".xls", $lines );
		$self->Add_2_Header( $data_table->{'header'} );
		$self->{'data'} = $data_table->{'data'};
	}
	else {
		$self->SUPER::read_file( $filename, $lines );
	}
	return $self;
}

sub print_as_table {
	my ( $self, $outfile ) = @_;
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
	my ( $self, $chr, $start, $ids ) = @_;
	my $chr_id = $self->get_chr_subID_4_start($chr,$start);
	return
	  @{ @{ $self->{'subset_4_PDL'}->{$chr} }[$chr_id]->GetAsArray('line_id') }
	  [@$ids];
}

1;
