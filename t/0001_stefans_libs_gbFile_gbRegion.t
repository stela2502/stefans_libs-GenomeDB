#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
BEGIN { use_ok 'stefans_libs::gbFile::gbRegion' }
use stefans_libs::root;
use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $value, @values, $exp );
my $OBJ = gbRegion -> new({});
is_deeply ( ref($OBJ) , 'gbRegion', 'simple test of function stefans_libs::gbFile::gbRegion -> new() ');


my $region = 'join(<12788761..>12788797,<12791047..>12791061,<12794939..12795183)';
my @value = $OBJ->ParseRegions( $region);
#print "\$exp = ".root->print_perl_var_def(\@value ).";\n";

$exp = [ [ {
  'tag_start' => '<',
  'tag' => 'normal',
  'start' => '12788761',
  'end' => '12788797',
  'tag_end' => '>'
}, {
  'tag_end' => '>',
  'start' => '12791047',
  'tag_start' => '<',
  'tag' => 'normal',
  'end' => '12791061'
}, {
  'tag_start' => '<',
  'tag' => 'normal',
  'start' => '12794939',
  'end' => '12795183',
  'tag_end' => ''
} ], '12788761', '12795183' ];
is_deeply(\@value, $exp, "Parse the region in the right way" );

ok ( $OBJ->Join() eq "join", "join was recorded" );

$value = $OBJ->Print();
#print "this is the printed region: $value\n";
is_deeply([split(",", $value)], [split(",", $region)], "prints as expected" );


@value = map{ $OBJ->Itemize_old($_) } split( ",", $region);
#print "\$exp = ".root->print_perl_var_def(\@value ).";\n";

$value = @$exp[0];

is_deeply( \@value, $value, "Itemize_old" );

$region = 'join(<12788761..>12788797,<12791047..>12791061,';
$OBJ= gbRegion->new();
@value = $OBJ->ParseRegions( $region);

#print "\$exp = ".root->print_perl_var_def(\@value ).";\n";
my $exp2 = [ [ {
  'tag_start' => '<',
  'tag' => 'normal',
  'start' => '12788761',
  'end' => '12788797',
  'tag_end' => '>'
}, {
  'end' => '12791061',
  'tag_end' => '>',
  'tag' => 'normal',
  'tag_start' => '<',
  'start' => '12791047'
} ], '12788761', '12791061' ];

is_deeply( \@value, $exp2, "Parse partial region 1" );

@value = $OBJ->ParseRegions("<12794939..12795183)");

is_deeply( \@value, $exp, "Parse partial region 2" );

is_deeply($OBJ->getAsGB(), "join(<12788761..>12788797,<12791047..>12791061,\n                     <12794939..12795183)", "getAsGB");

is_deeply($OBJ->Print( 12788761), "join(<1..>36,<2286..>2300,<6178..6422)", "changed positions start" );

is_deeply($OBJ->Print( 0, 12791049), "join(<12788761..>12788797,<12791047..>12791049)", "changed positions end" );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


