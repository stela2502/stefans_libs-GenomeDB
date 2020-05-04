#! /usr/bin/perl -w

=head1 LICENCE

  Copyright (C) 2016-11-23 Stefan Lang

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

    reformat_bed_gtf_intersect.pl
       -infile      :the outfile from a annotate_bed_with_gtf_genome.pl run
       -names       :should the output be numeric or as string (default numeric)
       
       -priority    :each bed file entry can have multiple hits in the genome annotation.
                     The priority handles the order in which these will be choosen.
                     You can choose between "<gtf_colname>;<value>" or smallest or largest
                     
       -used_cols   :A list of columns that should be kept in the result table
       
       -options     :format: key_1 value_1 key_2 value_2 ... key_n value_n
       
				largest "colA;colB;..." 
				   :select the longest overlapping element additional to the -priority selected one
				    and add the information in a new set of columns
				    preceeded by "longest"
       
       -outfile     :the outfile (a tab separated table)


       -help           :print this help
       -debug          :verbose output
   
=head1 DESCRIPTION

  Reformate a file created by the annotate_bed_with_gtf_genome.pl perl script.

  To get further help use 'reformat_bed_gtf_intersect.pl -help' at the comman line.

=cut

use Getopt::Long;
use Pod::Usage;

use stefans_libs::flexible_data_structures::data_table;

use strict;
use warnings;

use FindBin;
my $plugin_path = "$FindBin::Bin";

my $VERSION = 'v1.0';

my (
	$help,    $debug,   $database, $infile,   $names,
	$options, @options, $outfile,  @priority, @used_cols
);

Getopt::Long::GetOptions(
	"-infile=s"       => \$infile,
	"-names"          => \$names,
	"-options=s{,}"   => \@options,
	"-outfile=s"      => \$outfile,
	"-used_cols=s{,}" => \@used_cols,
	"-priority=s{,}"  => \@priority,

	"-help"  => \$help,
	"-debug" => \$debug
);

my $warn  = '';
my $error = '';

unless ( defined $infile ) {
	$error .= "the cmd line switch -infile is undefined!\n";
}

# names - no checks necessary
unless ( defined $options[0] ) {
	$warn .= "the cmd line switch -options is undefined!\n";
}
unless ( defined $outfile ) {
	$error .= "the cmd line switch -outfile is undefined!\n";
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

$task_description .= 'perl ' . $plugin_path . '/reformat_bed_gtf_intersect.pl';
$task_description .= " -infile '$infile'" if ( defined $infile );
$task_description .= " -names " if ($names);
$task_description .= ' -options "' . join( '" "', @options ) . '"'
  if ( defined $options[0] );
$task_description .= " -outfile '$outfile'" if ( defined $outfile );

for ( my $i = 0 ; $i < @options ; $i += 2 ) {
	$options[ $i + 1 ] =~ s/\n/ /g;
	$options->{ $options[$i] } = $options[ $i + 1 ];
}
###### default options ########
#$options->{'something'} ||= 'default value';

if ( $options->{'largest'} ) {
	my $tmp = [ split( ";", $options->{'largest'} )];
	$options->{'largest'}  = { 'data' => $tmp, 'result' => [map{ "largest $_"} @$tmp], 'n' => scalar(@$tmp) };
}
##############################

	
my $fm = root->filemap($outfile);
unless ( -d $fm->{'path'} ) {
	system("mkdir -p $fm->{'path'}");
}
open( LOG, ">$outfile.log" ) or die $!;
print LOG $task_description . "\n";
close(LOG);

## Do whatever you want!

my $prio_functs;

my ( @line, $of_id, $avail_cols );
open( IN, "<$infile" ) or die "could not open infile '$infile'\n$!\n";

my $data_table = data_table->new();
my ( @orig_cols_names, @orig_col_ids, @gtf_col_name, @gtf_ids, $hash,
	$tmp_table, $best_data );
$of_id = 0;

while (<IN>) {
	chomp($_);
	@line = split( "\t", $_ );
	if ( $_ =~ m/^#/ ) {    ## is header line
		$line[0] =~ s/^#//;
		my $colname;
		for ( my $i = 0 ; $i < @line ; $i++ ) {
			$colname = $line[$i];
			if ( $colname =~ m/^gtf_/ ) {
				push( @gtf_ids,         $i );
				push( @orig_cols_names, $colname );
			}
			else {
				$data_table->Add_2_Header($colname);
				push( @orig_col_ids,    $i );
				push( @orig_cols_names, $colname );
			}
		}
		my $i = 0;
		$avail_cols = { map { $_ => $i++ } @orig_cols_names };
		unless (@used_cols > 0) {
			@used_cols = ( @orig_cols_names[@gtf_ids], 'gtf_length' );
			warn
"command line option -used_cols undefined - I will report all columns!\n";
		}
		$data_table->Add_2_Header( \@used_cols );
		if ( $options->{'largest'} ) {
			$data_table->Add_2_Header( $options->{'largest'}->{'result'} );
		}
		&define_priority_functions();
		next;
	}
	## not a header line
	$hash = {};
	map { $hash->{ $orig_cols_names[$_] } = $line[$_] } @orig_col_ids;
	$tmp_table = data_table->new();

	foreach (@gtf_ids) {
		unless ( defined $line[$_] ) {
			$line[$_] = '';
		}
		else {
			if ( $line[$_] =~ m/^ \/\// ) {
				$line[$_] = "---" . $line[$_];
			}
			if ( $line[$_] =~ m/ \/\/ $/ ) {
				$line[$_] .= "---";
			}
		}
		my @values = map {
			if   ( defined $_ ) { $_ }
			else                { '---' }
		} split( " // ", $line[$_] );
		if ( @values == 0 ) {
			@values = ('');
		}
		$tmp_table->add_column( $orig_cols_names[$_], @values );
	}

	$tmp_table->calculate_on_columns(
		{
			'data_column'   => [ 'gtf_start', 'gtf_end' ],
			'target_column' => 'gtf_length',
			'function'      => sub            {$_[0] ||= 0;$_[1] ||= 0; return $_[1] - $_[0] }
		}
	);

	unless (@used_cols) {
		&helpString(
"The command line option -used_cols was undefined!\nPlease select columns of interest for the results table\n"
			  . $tmp_table->AsString() )
		  if ( $tmp_table->Rows() > 3 );
		next;
	}

	$best_data = &get_priority($tmp_table);
	map { $hash->{$_} = $best_data->{$_} } @used_cols;
	if ( $options->{'largest'} ) {
		my $r = &{$prio_functs->{'largest'}}($tmp_table);
		#print "Did we get anything? \$exp = ".root->print_perl_var_def($r ).";\n";
		if ( ref($r) eq "HASH"){
			for ( my $i = 0; $i < $options->{'largest'}->{'n'}; $i++ ){
				#print "@{$options->{'largest'}->{'result'}}[$i] => @{$options->{'largest'}->{'data'}}[$i] == $r->{@{$options->{'largest'}->{'data'}}[$i] }\n";
				$hash->{@{$options->{'largest'}->{'result'}}[$i] } = $r->{@{$options->{'largest'}->{'data'}}[$i] }
			}
			
		}
	}
  #	print "The final entry: \$exp = " . root->print_perl_var_def($hash) . ";\n";
	$data_table->AddDataset($hash);

#gtf_seqname	gtf_source	gtf_feature	gtf_start	gtf_end	gtf_score	gtf_strand	gtf_frame	gtf_attribute	gtf_gene_id	gtf_transcript_id	gtf_gene_type	gtf_gene_status	gtf_gene_name	gtf_transcript_type	gtf_transcript_status	gtf_transcript_name	gtf_exon_number	gtf_exon_id	gtf_level	gtf_protein_id	gtf_tag	gtf_transcript_support_level	gtf_ccdsid	gtf_havana_gene	gtf_havana_transcript	gtf_ont
#chr1	HAVANA	exon	93847174	93848939	.	+	.	ENSG00000260464.1	ENST00000565336.1	lincRNA	KNOWN	RP4-561L24.3	lincRNA	KNOWN	RP4-561L24.3-001	1	ENSE00002588542.1	2	---	basic	NA	---	OTTHUMG00000175883.1	OTTHUMT00000431234.1	---	---
#chr1	HAVANA	gene	93847174	93848939	.	+	.	ENSG00000260464.1		lincRNA	KNOWN	RP4-561L24.3						2					OTTHUMG00000175883.1
#chr1	HAVANA	transcript	93847174	93848939	.	+	.	ENSG00000260464.1	ENST00000565336.1	lincRNA	KNOWN	RP4-561L24.3	lincRNA	KNOWN	RP4-561L24.3-001			2		basic	NA		OTTHUMG00000175883.1	OTTHUMT00000431234.1
#chr1	MANUAL	gene	93847572	93847657	.	+	.	hg38:chr1-93847572:93847657	---	tRNA	KNOWN	tRNA-Arg-AGA	---	---	---	---	---	---	---	---	---	---	---	---	---	---

	## we want to process that table into a
	#gene	trna	rna exon
	#1	0	1	1
	#like structure
}
$data_table->write_table($outfile);

sub define_priority_functions {
	$prio_functs = { map { $_ => 1 } @priority };
	unless ( $prio_functs->{'smallest'} ) {
		@priority = ('smallest');
		$prio_functs->{'smallest'} = 1;
	}
	unless ( $prio_functs->{'largest'} ) {
		$prio_functs->{'largest'} = 1;
	}
	foreach ( keys %$prio_functs ) {
		if ( $_ eq "smallest" ) {
			$prio_functs->{$_} = sub {
				my $table = shift;
				my $r;
				return undef if ( $table->Rows() == 0 );
				$r = $table->Sort_by( [ [ 'gtf_length', 'numeric' ] ] );

#		print "\$exp = " . root->print_perl_var_def($r->get_line_asHash(0)) . ";\n";
				return $r->get_line_asHash(0);
			};

		}
		elsif ( $_ eq "largest" ) {
			$prio_functs->{$_} = sub {
				my $table = shift;
				my $r;
				return undef if ( $table->Rows() == 0 );
				$r = $table->Sort_by( [ [ 'gtf_length', 'antiNumeric' ] ] );

	#	print "largest: \$exp = " . root->print_perl_var_def($r->get_line_asHash(0)) . ";\n";
				return $r->get_line_asHash(0);
			};
		}
		else {
			my ( $col, $val ) = split( ";", $_ );
			Carp::confess("column '$col' is not defined in the table")
			  unless ( defined $avail_cols->{$col} );
			Carp::confess(
				"the priority '$_' is not in the format 'column_name;value'\n")
			  unless ( defined $val );
			$prio_functs->{$_} = sub {
				my $table = shift;
				my $t2 =
				  $table->select_where( $col, sub { $_[0] eq $val } );
				if ( $t2->Rows() == 0 ) {
		#			warn "no entry in column $col with value $val\n"
		#			  . $table->AsString() . "\n"
		#			  if ($debug);
					return undef;
				}
				return $t2->get_line_asHash(0);
			};
		}
	}

}

sub get_priority {
	my ($table) = @_;
	unless ( $table->Rows() ) {
		return {};
	}
	if ( $table->Rows() == 1 ) {
		return $table->get_line_asHash(0);
	}
	my $r;
	foreach (@priority) {
		$r = &{$prio_functs->{$_}}($table);
		return $r if ( ref($r) eq "HASH" );
	}
	Carp::confess(
		"Sorry I could not get a priority entry :-(" . $table->AsString() );
}

