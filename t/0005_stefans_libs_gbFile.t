#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;
BEGIN { use_ok 'stefans_libs::gbFile' }

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = gbFile -> new();
is_deeply ( ref($OBJ) , 'gbFile', 'simple test of function stefans_libs::gbFile -> new() ');

$OBJ->openFile( "$plugin_path/data/testGBfile.gb" );

$value = { 'Version' => $OBJ->Version(), 'Features' => [ map { $_-> getAsGB() } @{$OBJ->Features()}[0,47,48]], 'seq' => $OBJ->Get_SubSeq(0,100) };
$exp = {
  'Version' => 'NT_113819.1',
  'seq' => 'GATCACATTTCTTTTCACTATTCTATTGCTTTCCATTCCATCCCATTCCATTCCAGTCTATTTCACTCCACTCCACTGCACTTCACTCCATTCCATTCCA',
  'Features' => [ '     source          1..554624
                     /organism="Homo sapiens"
                     /mol_type="genomic DNA"
                     /db_xref="taxon:9606"
                     /chromosome="Y"
', '     ncRNA           join(<12788761..>12788797,<12791047..>12791061,
                     <12794939..12795183)
                     /gene="LINC01194"
                     /gene_synonym="TAG"
                     /ncRNA_class="lncRNA"
                     /product="long intergenic non-protein coding RNA 1194"
                     /inference="similar to RNA sequence (same
                     species):RefSeq:NR_033383.1"
                     /exception="annotated by transcript or proteomic data"
                     /note="The RefSeq transcript has 9 substitutions and 1
                     indel and aligns at 47% coverage compared to this genomic
                     sequence; Derived by automated computational analysis
                     using gene prediction method: BestRefSeq."
                     /transcript_id="NR_033383.1"
                     /db_xref="GI:291045142"
                     /db_xref="GeneID:404663"
                     /db_xref="HGNC:37171"
', '     CDS             complement(join(435459..435781,435906..436005,
                     443266..443460))
                     /gene="LOC439957"
                     /codon_start=1
                     /product="similar to hCG1742442"
                     /protein_id="XP_001716757.1"
                     /db_xref="GI:169217347"
                     /db_xref="GeneID:439957"
' ]
};
#print "\$exp = ".root->print_perl_var_def( $value ).";\n";

is_deeply( $value, $exp, "openFile()");

is_deeply( [$OBJ->Version(), scalar(@{$OBJ->Features}),length($OBJ->{seq}) ], ['NT_113819.1', 49, 554624], "file internals");


unlink ( "$plugin_path/data/output/testGBfile.gb" ) if ( -f "$plugin_path/data/output/testGBfile.gb");
$OBJ->WriteAsGB_toFile ( "$plugin_path/data/output/testGBfile.gb");

$OBJ = gbFile->new();
$OBJ->openFile( "$plugin_path/data/output/testGBfile.gb" );

is_deeply( [$OBJ->Version(), scalar(@{$OBJ->Features}),length($OBJ->{seq}) ], ['NT_113819.1', 48, 554624], "file internals");
$value = { 'Version' => $OBJ->Version(), 'Features' => [ map { $_-> getAsGB() } @{$OBJ->Features()}[0,47]], 'seq' => $OBJ->Get_SubSeq(0,100) };
$exp->{Features} = [@{$exp->{Features}}[0,2]];
is_deeply( $value, $exp, "written file");

unlink ( "$plugin_path/data/output/testGBfile.gb" ) if ( -f "$plugin_path/data/output/testGBfile.gb");

$OBJ->WriteAsGB_toFile ( "$plugin_path/data/output/testGBfile.gb", 50);

$OBJ = gbFile->new();
$OBJ->openFile( "$plugin_path/data/output/testGBfile.gb" );
is_deeply( [$OBJ->Version(), scalar(@{$OBJ->Features}),length($OBJ->{seq}) ], ['NT_113819.1', 48, 554574], "file internals");

$value = { 'Version' => $OBJ->Version(), 'Features' => [ map { $_-> getAsGB() } @{$OBJ->Features()}[0,47]], 'seq' => $OBJ->Get_SubSeq(0,100) };
$exp = {
  'Version' => 'NT_113819.1',
  'seq' => 'TTCCAGTCTATTTCACTCCACTCCACTGCACTTCACTCCATTCCATTCCACTCCATCACATTCCATTCTACTCCATTCAACTCCACTCCACTCCACTCCA',
  'Features' => [ '     source          <1..554574
                     /organism="Homo sapiens"
                     /mol_type="genomic DNA"
                     /db_xref="taxon:9606"
                     /chromosome="Y"
', '     CDS             complement(join(435409..435731,435856..435955,
                     443216..443410))
                     /gene="LOC439957"
                     /codon_start=1
                     /product="similar to hCG1742442"
                     /protein_id="XP_001716757.1"
                     /db_xref="GI:169217347"
                     /db_xref="GeneID:439957"
' ]
};

is_deeply( $value, $exp, "written file");

my $gbFeature = gbFeature->new( 'test', "join(1..10,20..30,40..50)" );

ok ( $OBJ->Get_SubSeq( $gbFeature ) eq substr($exp->{'seq'},0,49), "Get_SubSeq for a gbFeature - full" );
ok ( $OBJ->Get_SubSeq( $gbFeature, 10 ) eq substr($exp->{'seq'},0,59), "Get_SubSeq for a gbFeature - extended" );


#print "got: ".$OBJ->Get_SubSeq( $gbFeature, 10 )."\nexp: ".substr($exp->{'seq'},0,59)."\n";
@values = $OBJ->Get_SubSeq( $gbFeature, 'covered' );
#print "\$exp = ".root->print_perl_var_def( \@values ).";\n";
# TTCCAGTCT-ACTCCACTGC-ATTCCATTCC
$exp = [ 'TTCCAGTCT', 'ACTCCACTGC', 'ATTCCATTCC' ];
is_deeply (\@values, $exp, "Get_SubSeq for a gbFeature - covered" );




#print "\$exp = ".root->print_perl_var_def($value ).";\n";


