#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;
BEGIN { use_ok 'stefans_libs::plot::multiline_gb_Axis' }
BEGIN { use_ok 'GD::SVG'}
BEGIN { use_ok 'stefans_libs::plot::color'}
BEGIN { use_ok 'stefans_libs::plot::Font'}
BEGIN { use_ok 'stefans_libs::plot::axis'}
BEGIN { use_ok 'stefans_libs::gbFile'}

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp, $gbFile );

$gbFile = gbFile->new();
my $gbfeature_1 = gbFeature->new('gene', '1..1000');
$gbfeature_1 ->Name( 'GeneA');
push ( @values, $gbfeature_1);

my $gbfeature_2 = gbFeature->new('mRNA', '1..50,250..300,500..600,710..715,970..1000');
$gbfeature_2 ->Name( 'GeneA');
push ( @values, $gbfeature_2);

my $gbfeature_3 = gbFeature->new('CDS', '49..50,250..300,500..600,710..714');
$gbfeature_3 ->Name( 'GeneA');
push ( @values, $gbfeature_3);

my $gbfeature_10 = gbFeature->new('mRNA', '450..460,500..600,710..715,970..1000');
$gbfeature_10 ->Name( 'GeneA');
push ( @values, $gbfeature_10);

my $gbfeature_4 = gbFeature->new('CDS', '459..460,500..600,710..714');
$gbfeature_4 ->Name( 'GeneA');
push ( @values, $gbfeature_4);

my $gbfeature_5 = gbFeature->new('gene', 'complement(900..1500)');
$gbfeature_5 ->Name( 'GeneB');
push ( @values, $gbfeature_5);

my $gbfeature_6 = gbFeature->new('mRNA', 'complement(join(900..920,1030..1060,1200..1300,1400..1430,1480..1500))');
$gbfeature_6 ->Name( 'GeneB');
push ( @values, $gbfeature_6);

my $gbfeature_7 = gbFeature->new('CDS', 'complement(join(1039..1060,1200..1300,1400..1429))');
$gbfeature_7 ->Name( 'GeneB');
push ( @values, $gbfeature_7);


my $gbfeature_8 = gbFeature->new('gene', '1900..2000)');
$gbfeature_8 ->Name( 'SNORD36A');
push ( @values, $gbfeature_8);

my $gbfeature_9 = gbFeature->new('ncRNA', '1900..2000');
$gbfeature_9 ->Name( 'SNORD36A');
push ( @values, $gbfeature_9);

$gbFile->Features(\@values);

my ( $im, $color, $font);

$im = new GD::SVG::Image( 800, 400 );
$color = color->new( $im );
$font = Font->new( 'tiny');

my $multiline_gb_Axis = stefans_libs::plot::multiline_gb_Axis -> new($gbFile,1,2200,100,100,700,300,'gbfeature', $color );
is_deeply ( ref($multiline_gb_Axis) , 'stefans_libs::plot::multiline_gb_Axis', 'simple test of function stefans_libs::plot::multiline_gb_Axis -> new()' );

## now I want to check the new features:
is_deeply($multiline_gb_Axis -> calculate_required_lines(), 2, "the total lines are 2" );
is_deeply ($multiline_gb_Axis ->{'placements'}, {'GeneA'=> ['0' , '1'], 'GeneB' => ['2'], 'SNORD36A'=> [0] }, "the gene location list" );
#print "\$exp = ".root->print_perl_var_def($multiline_gb_Axis ->define_line_coordinates(3) ).";\n";
$exp = {
  '1' => [ '146', '159' ],
  '0' => [ '131', '144' ],
  '2' => [ '161', '174' ],
  '-1' => [ '100', '300' ]
};

is_deeply ($multiline_gb_Axis ->define_line_coordinates(3), $exp, "define line coordinates" );

$multiline_gb_Axis->plot($im, $font );
my $pictureFileName =  $plugin_path."/data/multiline_figure.svg";
open( PICTURE, ">$pictureFileName" )
	or die "Cannot open file $pictureFileName for writing\n$!\n";
binmode PICTURE;
print PICTURE $im->svg;
close PICTURE;
#print "\$exp = ".root->print_perl_var_def($value ).";\n";