#!/usr/bin/perl -w

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'Packages::InCAM::InCAM';

my $jobId = "1";
my $inCAM = InCAM->new();

my $step  = "1";
my $layer = "test";

my $f = Features->new();


$f->Parse( $inCAM, $jobId, $step, $layer, 0 );

my @features = $f->GetFeatures();

if ( scalar(@features) == 1 ) {

	print STDERR "x1=" . $features[0]->{"x1"};
	print STDERR "y1=" . $features[0]->{"y1"};
}
