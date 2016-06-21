#! /usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok 'stefans_libs::plot::genomePlot' }

my ( $value, @values, $exp );
my $stefans_libs_plot_genomePlot = stefans_libs_plot_genomePlot -> new();
is_deeply ( ref($stefans_libs_plot_genomePlot) , 'stefans_libs_plot_genomePlot', 'simple test of function stefans_libs_plot_genomePlot -> new()' );

#print "\$exp = ".root->print_perl_var_def($value ).";\n";


