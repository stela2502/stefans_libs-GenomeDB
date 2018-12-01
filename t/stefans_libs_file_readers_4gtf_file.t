#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
BEGIN { use_ok 'stefans_libs::file_readers::gtf_file' }

use Time::HiRes qw[ time ];

use FindBin;
my $plugin_path = "$FindBin::Bin";

my ( $test_object, $value, $exp, @values );
$test_object = stefans_libs::file_readers::gtf_file->new();
is_deeply(
	ref($test_object),
	'stefans_libs::file_readers::gtf_file',
	'simple test of function stefans_libs::file_readers::gtf_file -> new()'
);

my $infile = "$plugin_path/data/GOI.gtf3.gz";
ok( -f $infile, "infile $infile" );

my $begin = time();

#warn "I want to see a has change between here \n$test_object\n";
$exp = $test_object->read_file($infile);

#warn "And there:\n$exp\n";

printf( "read_file consumed %.3f second(s)\n", time() - $begin );

#4.656 our
#4.603 my
## This will create a '__GeneFreeSplits__' bed file
ok( !defined $test_object->{'__GeneFreeSplits__'},
	"gene free splits not defined" );
$test_object->{'slice_length'} = 1e+7;
$test_object->get_chr_subID_4_start( 'chr1', 1 );

$value = $test_object->{'__GeneFreeSplits__'};
ok( ref($value) eq "stefans_libs::file_readers::bed_file",
	"defined as the right class" );

#print "\n\$exp = "  . root->print_perl_var_def([	$value->{'header'}, @{$value->{'data'} }]) . ";\n";
$exp = [
	[ 'chromosome', 'start', 'end', 'name', 'line_id' ],
	[ 'chr1',  '0',         '9999999',   undef, '0',  '0' ],
	[ 'chr1',  '10000000',  '19999999',  undef, '1',  '1' ],
	[ 'chr1',  '20000000',  '29999999',  undef, '2',  '2' ],
	[ 'chr1',  '30000000',  '39999999',  undef, '3',  '3' ],
	[ 'chr1',  '40000000',  '49999999',  undef, '4',  '4' ],
	[ 'chr1',  '50000000',  '59999999',  undef, '5',  '5' ],
	[ 'chr1',  '60000000',  '69999999',  undef, '6',  '6' ],
	[ 'chr1',  '70000000',  '79999999',  undef, '7',  '7' ],
	[ 'chr1',  '80000000',  '89999999',  undef, '8',  '8' ],
	[ 'chr1',  '90000000',  '99999999',  undef, '9',  '9' ],
	[ 'chr1',  '100000000', '109999999', undef, '10', '10' ],
	[ 'chr1',  '110000000', '119999999', undef, '11', '11' ],
	[ 'chr1',  '120000000', '129999999', undef, '12', '12' ],
	[ 'chr1',  '130000000', '139999999', undef, '13', '13' ],
	[ 'chr1',  '140000000', '149999999', undef, '14', '14' ],
	[ 'chr1',  '150000000', '159999999', undef, '15', '15' ],
	[ 'chr1',  '160000000', '169999999', undef, '16', '16' ],
	[ 'chr1',  '170000000', '179999999', undef, '17', '17' ],
	[ 'chr1',  '180000000', '189999999', undef, '18', '18' ],
	[ 'chr1',  '190000000', '199999999', undef, '19', '19' ],
	[ 'chr1',  '200000000', '209999999', undef, '20', '20' ],
	[ 'chr10', '0',         '9999999',   undef, '21' ],
	[ 'chr10', '10000000',  '19999999',  undef, '22' ],
	[ 'chr10', '20000000',  '29999999',  undef, '23' ],
	[ 'chr10', '30000000',  '39999999',  undef, '24' ],
	[ 'chr10', '40000000',  '49999999',  undef, '25' ],
	[ 'chr10', '50000000',  '59999999',  undef, '26' ],
	[ 'chr10', '60000000',  '69999999',  undef, '27' ],
	[ 'chr10', '70000000',  '79999999',  undef, '28' ],
	[ 'chr10', '80000000',  '89999999',  undef, '29' ],
	[ 'chr10', '90000000',  '99999999',  undef, '30' ],
	[ 'chr10', '100000000', '109999999', undef, '31' ],
	[ 'chr10', '110000000', '119999999', undef, '32' ],
	[ 'chr10', '120000000', '129999999', undef, '33' ],
	[ 'chr11', '0',         '9999999',   undef, '34' ],
	[ 'chr11', '10000000',  '19999999',  undef, '35' ],
	[ 'chr11', '20000000',  '29999999',  undef, '36' ],
	[ 'chr11', '30000000',  '39999999',  undef, '37' ],
	[ 'chr11', '40000000',  '49999999',  undef, '38' ],
	[ 'chr11', '50000000',  '59999999',  undef, '39' ],
	[ 'chr11', '60000000',  '69999999',  undef, '40' ],
	[ 'chr11', '70000000',  '79999999',  undef, '41' ],
	[ 'chr11', '80000000',  '89999999',  undef, '42' ],
	[ 'chr11', '90000000',  '99999999',  undef, '43' ],
	[ 'chr11', '100000000', '109999999', undef, '44' ],
	[ 'chr11', '110000000', '119999999', undef, '45' ],
	[ 'chr12', '0',         '9999999',   undef, '46' ],
	[ 'chr12', '10000000',  '19999999',  undef, '47' ],
	[ 'chr12', '20000000',  '29999999',  undef, '48' ],
	[ 'chr12', '30000000',  '39999999',  undef, '49' ],
	[ 'chr12', '40000000',  '49999999',  undef, '50' ],
	[ 'chr13', '0',         '9999999',   undef, '51' ],
	[ 'chr13', '10000000',  '19999999',  undef, '52' ],
	[ 'chr13', '20000000',  '29999999',  undef, '53' ],
	[ 'chr13', '30000000',  '39999999',  undef, '54' ],
	[ 'chr13', '40000000',  '49999999',  undef, '55' ],
	[ 'chr13', '50000000',  '59999999',  undef, '56' ],
	[ 'chr13', '60000000',  '69999999',  undef, '57' ],
	[ 'chr13', '70000000',  '79999999',  undef, '58' ],
	[ 'chr13', '80000000',  '89999999',  undef, '59' ],
	[ 'chr13', '90000000',  '99999999',  undef, '60' ],
	[ 'chr14', '0',         '9999999',   undef, '61' ],
	[ 'chr14', '10000000',  '19999999',  undef, '62' ],
	[ 'chr14', '20000000',  '29999999',  undef, '63' ],
	[ 'chr14', '30000000',  '39999999',  undef, '64' ],
	[ 'chr14', '40000000',  '49999999',  undef, '65' ],
	[ 'chr14', '50000000',  '59999999',  undef, '66' ],
	[ 'chr14', '60000000',  '69999999',  undef, '67' ],
	[ 'chr14', '70000000',  '79999999',  undef, '68' ],
	[ 'chr15', '0',         '9999999',   undef, '69' ],
	[ 'chr15', '10000000',  '19999999',  undef, '70' ],
	[ 'chr15', '20000000',  '29999999',  undef, '71' ],
	[ 'chr15', '30000000',  '39999999',  undef, '72' ],
	[ 'chr15', '40000000',  '49999999',  undef, '73' ],
	[ 'chr15', '50000000',  '59999999',  undef, '74' ],
	[ 'chr15', '60000000',  '69999999',  undef, '75' ],
	[ 'chr15', '70000000',  '79999999',  undef, '76' ],
	[ 'chr15', '80000000',  '89999999',  undef, '77' ],
	[ 'chr15', '90000000',  '99999999',  undef, '78' ],
	[ 'chr15', '100000000', '109999999', undef, '79' ],
	[ 'chr15', '110000000', '119999999', undef, '80' ],
	[ 'chr16', '0',         '9999999',   undef, '81' ],
	[ 'chr16', '10000000',  '19999999',  undef, '82' ],
	[ 'chr16', '20000000',  '29999999',  undef, '83' ],
	[ 'chr16', '30000000',  '39999999',  undef, '84' ],
	[ 'chr16', '40000000',  '49999999',  undef, '85' ],
	[ 'chr17', '0',         '9999999',   undef, '86' ],
	[ 'chr17', '10000000',  '19999999',  undef, '87' ],
	[ 'chr17', '20000000',  '29999999',  undef, '88' ],
	[ 'chr17', '30000000',  '39999999',  undef, '89' ],
	[ 'chr17', '40000000',  '49999999',  undef, '90' ],
	[ 'chr17', '50000000',  '59999999',  undef, '91' ],
	[ 'chr17', '60000000',  '69999999',  undef, '92' ],
	[ 'chr18', '0',         '9999999',   undef, '93' ],
	[ 'chr18', '10000000',  '19999999',  undef, '94' ],
	[ 'chr18', '20000000',  '29999999',  undef, '95' ],
	[ 'chr18', '30000000',  '39999999',  undef, '96' ],
	[ 'chr18', '40000000',  '49999999',  undef, '97' ],
	[ 'chr18', '50000000',  '59999999',  undef, '98' ],
	[ 'chr18', '60000000',  '69999999',  undef, '99' ],
	[ 'chr18', '70000000',  '79999999',  undef, '100' ],
	[ 'chr18', '80000000',  '89999999',  undef, '101' ],
	[ 'chr19', '0',         '9999999',   undef, '102' ],
	[ 'chr19', '10000000',  '19999999',  undef, '103' ],
	[ 'chr19', '20000000',  '29999999',  undef, '104' ],
	[ 'chr19', '30000000',  '39999999',  undef, '105' ],
	[ 'chr19', '40000000',  '49999999',  undef, '106' ],
	[ 'chr19', '50000000',  '59999999',  undef, '107' ],
	[ 'chr2',  '0',         '9999999',   undef, '108' ],
	[ 'chr2',  '10000000',  '19999999',  undef, '109' ],
	[ 'chr2',  '20000000',  '29999999',  undef, '110' ],
	[ 'chr2',  '30000000',  '39999999',  undef, '111' ],
	[ 'chr2',  '40000000',  '49999999',  undef, '112' ],
	[ 'chr2',  '50000000',  '59999999',  undef, '113' ],
	[ 'chr2',  '60000000',  '69999999',  undef, '114' ],
	[ 'chr2',  '70000000',  '79999999',  undef, '115' ],
	[ 'chr2',  '80000000',  '89999999',  undef, '116' ],
	[ 'chr2',  '90000000',  '99999999',  undef, '117' ],
	[ 'chr2',  '100000000', '109999999', undef, '118' ],
	[ 'chr2',  '110000000', '119999999', undef, '119' ],
	[ 'chr2',  '120000000', '129999999', undef, '120' ],
	[ 'chr2',  '130000000', '139999999', undef, '121' ],
	[ 'chr2',  '140000000', '149999999', undef, '122' ],
	[ 'chr2',  '150000000', '159999999', undef, '123' ],
	[ 'chr2',  '160000000', '169999999', undef, '124' ],
	[ 'chr2',  '170000000', '179999999', undef, '125' ],
	[ 'chr3',  '0',         '9999999',   undef, '126' ],
	[ 'chr3',  '10000000',  '19999999',  undef, '127' ],
	[ 'chr3',  '20000000',  '29999999',  undef, '128' ],
	[ 'chr3',  '30000000',  '39999999',  undef, '129' ],
	[ 'chr3',  '40000000',  '49999999',  undef, '130' ],
	[ 'chr3',  '50000000',  '59999999',  undef, '131' ],
	[ 'chr3',  '60000000',  '69999999',  undef, '132' ],
	[ 'chr3',  '70000000',  '79999999',  undef, '133' ],
	[ 'chr3',  '80000000',  '89999999',  undef, '134' ],
	[ 'chr3',  '90000000',  '99999999',  undef, '135' ],
	[ 'chr3',  '100000000', '109999999', undef, '136' ],
	[ 'chr3',  '110000000', '119999999', undef, '137' ],
	[ 'chr3',  '120000000', '129999999', undef, '138' ],
	[ 'chr3',  '130000000', '139999999', undef, '139' ],
	[ 'chr3',  '140000000', '149999999', undef, '140' ],
	[ 'chr4',  '0',         '9999999',   undef, '141' ],
	[ 'chr4',  '10000000',  '19999999',  undef, '142' ],
	[ 'chr4',  '20000000',  '29999999',  undef, '143' ],
	[ 'chr4',  '30000000',  '39999999',  undef, '144' ],
	[ 'chr4',  '40000000',  '49999999',  undef, '145' ],
	[ 'chr4',  '50000000',  '59999999',  undef, '146' ],
	[ 'chr4',  '60000000',  '69999999',  undef, '147' ],
	[ 'chr4',  '70000000',  '79999999',  undef, '148' ],
	[ 'chr4',  '80000000',  '89999999',  undef, '149' ],
	[ 'chr4',  '90000000',  '99999999',  undef, '150' ],
	[ 'chr4',  '100000000', '109999999', undef, '151' ],
	[ 'chr4',  '110000000', '119999999', undef, '152' ],
	[ 'chr4',  '120000000', '129999999', undef, '153' ],
	[ 'chr4',  '130000000', '139999999', undef, '154' ],
	[ 'chr4',  '140000000', '149999999', undef, '155' ],
	[ 'chr4',  '150000000', '159999999', undef, '156' ],
	[ 'chr5',  '0',         '9999999',   undef, '157' ],
	[ 'chr5',  '10000000',  '19999999',  undef, '158' ],
	[ 'chr5',  '20000000',  '29999999',  undef, '159' ],
	[ 'chr5',  '30000000',  '39999999',  undef, '160' ],
	[ 'chr5',  '40000000',  '49999999',  undef, '161' ],
	[ 'chr5',  '50000000',  '59999999',  undef, '162' ],
	[ 'chr5',  '60000000',  '69999999',  undef, '163' ],
	[ 'chr5',  '70000000',  '79999999',  undef, '164' ],
	[ 'chr5',  '80000000',  '89999999',  undef, '165' ],
	[ 'chr5',  '90000000',  '99999999',  undef, '166' ],
	[ 'chr5',  '100000000', '109999999', undef, '167' ],
	[ 'chr5',  '110000000', '119999999', undef, '168' ],
	[ 'chr5',  '120000000', '129999999', undef, '169' ],
	[ 'chr5',  '130000000', '139999999', undef, '170' ],
	[ 'chr5',  '140000000', '149999999', undef, '171' ],
	[ 'chr5',  '150000000', '159999999', undef, '172' ],
	[ 'chr6',  '0',         '9999999',   undef, '173' ],
	[ 'chr6',  '10000000',  '19999999',  undef, '174' ],
	[ 'chr6',  '20000000',  '29999999',  undef, '175' ],
	[ 'chr6',  '30000000',  '39999999',  undef, '176' ],
	[ 'chr6',  '40000000',  '49999999',  undef, '177' ],
	[ 'chr6',  '50000000',  '59999999',  undef, '178' ],
	[ 'chr6',  '60000000',  '69999999',  undef, '179' ],
	[ 'chr6',  '70000000',  '79999999',  undef, '180' ],
	[ 'chr6',  '80000000',  '89999999',  undef, '181' ],
	[ 'chr6',  '90000000',  '99999999',  undef, '182' ],
	[ 'chr6',  '100000000', '109999999', undef, '183' ],
	[ 'chr6',  '110000000', '119999999', undef, '184' ],
	[ 'chr6',  '120000000', '129999999', undef, '185' ],
	[ 'chr6',  '130000000', '139999999', undef, '186' ],
	[ 'chr6',  '140000000', '149999999', undef, '187' ],
	[ 'chr6',  '150000000', '159999999', undef, '188' ],
	[ 'chr7',  '0',         '9999999',   undef, '189' ],
	[ 'chr7',  '10000000',  '19999999',  undef, '190' ],
	[ 'chr7',  '20000000',  '29999999',  undef, '191' ],
	[ 'chr7',  '30000000',  '39999999',  undef, '192' ],
	[ 'chr7',  '40000000',  '49999999',  undef, '193' ],
	[ 'chr7',  '50000000',  '59999999',  undef, '194' ],
	[ 'chr7',  '60000000',  '69999999',  undef, '195' ],
	[ 'chr7',  '70000000',  '79999999',  undef, '196' ],
	[ 'chr7',  '80000000',  '89999999',  undef, '197' ],
	[ 'chr7',  '90000000',  '99999999',  undef, '198' ],
	[ 'chr7',  '100000000', '109999999', undef, '199' ],
	[ 'chr7',  '110000000', '119999999', undef, '200' ],
	[ 'chr7',  '120000000', '129999999', undef, '201' ],
	[ 'chr7',  '130000000', '139999999', undef, '202' ],
	[ 'chr7',  '140000000', '149999999', undef, '203' ],
	[ 'chr7',  '150000000', '159999999', undef, '204' ],
	[ 'chr8',  '0',         '9999999',   undef, '205' ],
	[ 'chr8',  '10000000',  '19999999',  undef, '206' ],
	[ 'chr8',  '20000000',  '29999999',  undef, '207' ],
	[ 'chr8',  '30000000',  '39999999',  undef, '208' ],
	[ 'chr8',  '40000000',  '49999999',  undef, '209' ],
	[ 'chr8',  '50000000',  '59999999',  undef, '210' ],
	[ 'chr8',  '60000000',  '69999999',  undef, '211' ],
	[ 'chr8',  '70000000',  '79999999',  undef, '212' ],
	[ 'chr8',  '80000000',  '89999999',  undef, '213' ],
	[ 'chr8',  '90000000',  '99999999',  undef, '214' ],
	[ 'chr8',  '100000000', '109999999', undef, '215' ],
	[ 'chr8',  '110000000', '119999999', undef, '216' ],
	[ 'chr8',  '120000000', '129999999', undef, '217' ],
	[ 'chr8',  '130000000', '139999999', undef, '218' ],
	[ 'chr9',  '0',         '9999999',   undef, '219' ],
	[ 'chr9',  '10000000',  '19999999',  undef, '220' ],
	[ 'chr9',  '20000000',  '29999999',  undef, '221' ],
	[ 'chr9',  '30000000',  '39999999',  undef, '222' ],
	[ 'chr9',  '40000000',  '49999999',  undef, '223' ],
	[ 'chr9',  '50000000',  '59999999',  undef, '224' ],
	[ 'chr9',  '60000000',  '69999999',  undef, '225' ],
	[ 'chr9',  '70000000',  '79999999',  undef, '226' ],
	[ 'chr9',  '80000000',  '89999999',  undef, '227' ],
	[ 'chr9',  '90000000',  '99999999',  undef, '228' ],
	[ 'chr9',  '100000000', '109999999', undef, '229' ],
	[ 'chr9',  '110000000', '119999999', undef, '230' ],
	[ 'chr9',  '120000000', '129999999', undef, '231' ],
	[ 'chrX',  '0',         '9999999',   undef, '232' ],
	[ 'chrX',  '10000000',  '19999999',  undef, '233' ]
];

is_deeply( [ $value->{'header'}, @{ $value->{'data'} } ],
	$exp, "The __GeneFreeSplit___ data" );

## now try the gene free split.
$test_object->{'__GeneFreeSplits__'} = undef;

$value = $test_object->GeneFreeSplits();

#print "\n\$exp = "  . root->print_perl_var_def([	$value->{'header'}, @{$value->{'data'} }]) . ";\n";

$exp = [
	[ 'chromosome', 'start',     'end', 'name' ],
	[ 'chr1',       '0',         '9999999' ],
	[ 'chr1',       '10000000',  '20000362' ],
	[ 'chr1',       '20000363',  '29999999' ],
	[ 'chr1',       '30000000',  '39999999' ],
	[ 'chr1',       '40000000',  '49999999' ],
	[ 'chr1',       '50000000',  '59999999' ],
	[ 'chr1',       '60000000',  '69999999' ],
	[ 'chr1',       '70000000',  '79999999' ],
	[ 'chr1',       '80000000',  '89999999' ],
	[ 'chr1',       '90000000',  '99999999' ],
	[ 'chr1',       '100000000', '109999999' ],
	[ 'chr1',       '110000000', '119999999' ],
	[ 'chr1',       '120000000', '129999999' ],
	[ 'chr1',       '130000000', '139999999' ],
	[ 'chr1',       '140000000', '149999999' ],
	[ 'chr1',       '150000000', '159999999' ],
	[ 'chr1',       '160000000', '169999999' ],
	[ 'chr1',       '170000000', '179999999' ],
	[ 'chr1',       '180000000', '189999999' ],
	[ 'chr1',       '190000000', '195176715' ],
	[ 'chr10',      '0',         '9999999' ],
	[ 'chr10',      '10000000',  '19999999' ],
	[ 'chr10',      '20000000',  '29999999' ],
	[ 'chr10',      '30000000',  '39999999' ],
	[ 'chr10',      '40000000',  '49999999' ],
	[ 'chr10',      '50000000',  '59999999' ],
	[ 'chr10',      '60000000',  '69999999' ],
	[ 'chr10',      '70000000',  '79999999' ],
	[ 'chr10',      '80000000',  '89999999' ],
	[ 'chr10',      '90000000',  '99999999' ],
	[ 'chr10',      '100000000', '109999999' ],
	[ 'chr10',      '110000000', '117710757' ],
	[ 'chr11',      '0',         '9999999' ],
	[ 'chr11',      '10000000',  '19999999' ],
	[ 'chr11',      '20000000',  '29999999' ],
	[ 'chr11',      '30000000',  '39999999' ],
	[ 'chr11',      '40000000',  '49999999' ],
	[ 'chr11',      '50000000',  '59999999' ],
	[ 'chr11',      '60000000',  '69999999' ],
	[ 'chr11',      '70000000',  '79999999' ],
	[ 'chr11',      '80000000',  '89999999' ],
	[ 'chr11',      '90000000',  '99999999' ],
	[ 'chr11',      '100000000', '100939539' ],
	[ 'chr12',      '0',         '9999999' ],
	[ 'chr12',      '10000000',  '19999999' ],
	[ 'chr12',      '20000000',  '29999999' ],
	[ 'chr12',      '30000000',  '35535037' ],
	[ 'chr13',      '0',         '9999999' ],
	[ 'chr13',      '10000000',  '19999999' ],
	[ 'chr13',      '20000000',  '29999999' ],
	[ 'chr13',      '30000000',  '39999999' ],
	[ 'chr13',      '40000000',  '49999999' ],
	[ 'chr13',      '50000000',  '59999999' ],
	[ 'chr13',      '60000000',  '69999999' ],
	[ 'chr13',      '70000000',  '79999999' ],
	[ 'chr13',      '80000000',  '83667079' ],
	[ 'chr14',      '0',         '9999999' ],
	[ 'chr14',      '10000000',  '19999999' ],
	[ 'chr14',      '20000000',  '29999999' ],
	[ 'chr14',      '30000000',  '39999999' ],
	[ 'chr14',      '40000000',  '49999999' ],
	[ 'chr14',      '50000000',  '59999999' ],
	[ 'chr14',      '60000000',  '65981547' ],
	[ 'chr15',      '0',         '9999999' ],
	[ 'chr15',      '10000000',  '19999999' ],
	[ 'chr15',      '20000000',  '29999999' ],
	[ 'chr15',      '30000000',  '39999999' ],
	[ 'chr15',      '40000000',  '49999999' ],
	[ 'chr15',      '50000000',  '59999999' ],
	[ 'chr15',      '60000000',  '69999999' ],
	[ 'chr15',      '70000000',  '79999999' ],
	[ 'chr15',      '80000000',  '89999999' ],
	[ 'chr15',      '90000000',  '99999999' ],
	[ 'chr15',      '100000000', '102231934' ],
	[ 'chr16',      '0',         '9999999' ],
	[ 'chr16',      '10000000',  '19999999' ],
	[ 'chr16',      '20000000',  '29999999' ],
	[ 'chr16',      '30000000',  '38486932' ],
	[ 'chr17',      '0',         '9999999' ],
	[ 'chr17',      '10000000',  '19999999' ],
	[ 'chr17',      '20000000',  '29999999' ],
	[ 'chr17',      '30000000',  '39999999' ],
	[ 'chr17',      '40000000',  '49999999' ],
	[ 'chr17',      '50000000',  '51833289' ],
	[ 'chr18',      '0',         '9999999' ],
	[ 'chr18',      '10000000',  '19999999' ],
	[ 'chr18',      '20000000',  '29999999' ],
	[ 'chr18',      '30000000',  '39999999' ],
	[ 'chr18',      '40000000',  '49999999' ],
	[ 'chr18',      '50000000',  '59999999' ],
	[ 'chr18',      '60000000',  '69999999' ],
	[ 'chr18',      '70000000',  '75395934' ],
	[ 'chr19',      '0',         '9999999' ],
	[ 'chr19',      '10000000',  '19999999' ],
	[ 'chr19',      '20000000',  '29999999' ],
	[ 'chr19',      '30000000',  '39999999' ],
	[ 'chr19',      '40000000',  '40271841' ],
	[ 'chr2',       '0',         '9999999' ],
	[ 'chr2',       '10000000',  '19999999' ],
	[ 'chr2',       '20000000',  '29999999' ],
	[ 'chr2',       '30000000',  '39999999' ],
	[ 'chr2',       '40000000',  '49999999' ],
	[ 'chr2',       '50000000',  '59999999' ],
	[ 'chr2',       '60000000',  '69999999' ],
	[ 'chr2',       '70000000',  '79999999' ],
	[ 'chr2',       '80000000',  '89999999' ],
	[ 'chr2',       '90000000',  '99999999' ],
	[ 'chr2',       '100000000', '109999999' ],
	[ 'chr2',       '110000000', '119999999' ],
	[ 'chr2',       '120000000', '129999999' ],
	[ 'chr2',       '130000000', '139999999' ],
	[ 'chr2',       '140000000', '149999999' ],
	[ 'chr2',       '150000000', '159999999' ],
	[ 'chr2',       '160000000', '167690417' ],
	[ 'chr3',       '0',         '9999999' ],
	[ 'chr3',       '10000000',  '19999999' ],
	[ 'chr3',       '20000000',  '29999999' ],
	[ 'chr3',       '30000000',  '39999999' ],
	[ 'chr3',       '40000000',  '49999999' ],
	[ 'chr3',       '50000000',  '59999999' ],
	[ 'chr3',       '60000000',  '69999999' ],
	[ 'chr3',       '70000000',  '79999999' ],
	[ 'chr3',       '80000000',  '89999999' ],
	[ 'chr3',       '90000000',  '99999999' ],
	[ 'chr3',       '100000000', '109999999' ],
	[ 'chr3',       '110000000', '119999999' ],
	[ 'chr3',       '120000000', '129999999' ],
	[ 'chr3',       '130000000', '135691546' ],
	[ 'chr4',       '0',         '9999999' ],
	[ 'chr4',       '10000000',  '19999999' ],
	[ 'chr4',       '20000000',  '29999999' ],
	[ 'chr4',       '30000000',  '39999999' ],
	[ 'chr4',       '40000000',  '49999999' ],
	[ 'chr4',       '50000000',  '59999999' ],
	[ 'chr4',       '60000000',  '69999999' ],
	[ 'chr4',       '70000000',  '79999999' ],
	[ 'chr4',       '80000000',  '89999999' ],
	[ 'chr4',       '90000000',  '99999999' ],
	[ 'chr4',       '100000000', '109999999' ],
	[ 'chr4',       '110000000', '119999999' ],
	[ 'chr4',       '120000000', '129999999' ],
	[ 'chr4',       '130000000', '139999999' ],
	[ 'chr4',       '140000000', '149702570' ],
	[ 'chr5',       '0',         '9999999' ],
	[ 'chr5',       '10000000',  '19999999' ],
	[ 'chr5',       '20000000',  '29999999' ],
	[ 'chr5',       '30000000',  '39999999' ],
	[ 'chr5',       '40000000',  '49999999' ],
	[ 'chr5',       '50000000',  '59999999' ],
	[ 'chr5',       '60000000',  '69999999' ],
	[ 'chr5',       '70000000',  '79999999' ],
	[ 'chr5',       '80000000',  '89999999' ],
	[ 'chr5',       '90000000',  '99999999' ],
	[ 'chr5',       '100000000', '109999999' ],
	[ 'chr5',       '110000000', '119999999' ],
	[ 'chr5',       '120000000', '129999999' ],
	[ 'chr5',       '130000000', '139999999' ],
	[ 'chr5',       '140000000', '147400488' ],
	[ 'chr6',       '0',         '9999999' ],
	[ 'chr6',       '10000000',  '19999999' ],
	[ 'chr6',       '20000000',  '29999999' ],
	[ 'chr6',       '30000000',  '39999999' ],
	[ 'chr6',       '40000000',  '49999999' ],
	[ 'chr6',       '50000000',  '59999999' ],
	[ 'chr6',       '60000000',  '69999999' ],
	[ 'chr6',       '70000000',  '79999999' ],
	[ 'chr6',       '80000000',  '89999999' ],
	[ 'chr6',       '90000000',  '99999999' ],
	[ 'chr6',       '100000000', '109999999' ],
	[ 'chr6',       '110000000', '119999999' ],
	[ 'chr6',       '120000000', '129999999' ],
	[ 'chr6',       '130000000', '139999999' ],
	[ 'chr6',       '140000000', '145865557' ],
	[ 'chr7',       '0',         '9999999' ],
	[ 'chr7',       '10000000',  '19999999' ],
	[ 'chr7',       '20000000',  '29999999' ],
	[ 'chr7',       '30000000',  '39999999' ],
	[ 'chr7',       '40000000',  '49999999' ],
	[ 'chr7',       '50000000',  '59999999' ],
	[ 'chr7',       '60000000',  '69999999' ],
	[ 'chr7',       '70000000',  '79999999' ],
	[ 'chr7',       '80000000',  '89999999' ],
	[ 'chr7',       '90000000',  '99999999' ],
	[ 'chr7',       '100000000', '109999999' ],
	[ 'chr7',       '110000000', '119999999' ],
	[ 'chr7',       '120000000', '129999999' ],
	[ 'chr7',       '130000000', '139999999' ],
	[ 'chr7',       '140000000', '142494866' ],
	[ 'chr8',       '0',         '9999999' ],
	[ 'chr8',       '10000000',  '19999999' ],
	[ 'chr8',       '20000000',  '29999999' ],
	[ 'chr8',       '30000000',  '39999999' ],
	[ 'chr8',       '40000000',  '49999999' ],
	[ 'chr8',       '50000000',  '59999999' ],
	[ 'chr8',       '60000000',  '69999999' ],
	[ 'chr8',       '70000000',  '79999999' ],
	[ 'chr8',       '80000000',  '89999999' ],
	[ 'chr8',       '90000000',  '99999999' ],
	[ 'chr8',       '100000000', '109999999' ],
	[ 'chr8',       '110000000', '119999999' ],
	[ 'chr8',       '120000000', '128733199' ],
	[ 'chr9',       '0',         '9999999' ],
	[ 'chr9',       '10000000',  '19999999' ],
	[ 'chr9',       '20000000',  '29999999' ],
	[ 'chr9',       '30000000',  '39999999' ],
	[ 'chr9',       '40000000',  '49999999' ],
	[ 'chr9',       '50000000',  '59999999' ],
	[ 'chr9',       '60000000',  '69999999' ],
	[ 'chr9',       '70000000',  '79999999' ],
	[ 'chr9',       '80000000',  '89999999' ],
	[ 'chr9',       '90000000',  '99999999' ],
	[ 'chr9',       '100000000', '109999999' ],
	[ 'chr9',       '110000000', '110423011' ],
	[ 'chrX',       '0',         '9487770' ]
];

for ( my $i = 0 ; $i < @$exp ; $i++ ) {
	splice( @{ @$exp[$i] }, 5, 1 ) if ( scalar( @{ @$exp[$i] } ) > 5 );
}

is_deeply( [ $value->{'header'}, @{ $value->{'data'} } ],
	$exp, "The GeneFreeSplits() data" );

## And now try if this thing does work!

@values = $test_object->efficient_match_chr_position( 'chr1', 20000300 );

ok( scalar(@values) == 1, "I had expected 1 entry (" . scalar(@values) . ")" );


@values = $test_object->efficient_match_chr_position( 'chrX', 20000300 );

ok ( scalar(@values) == 0, "I had expected 1 entry (" . scalar(@values) . ")" );
#print "\$exp = ".root->print_perl_var_def($value ).";\n";
