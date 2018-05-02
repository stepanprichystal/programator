#!/usr/bin/perl -w

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

	use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';
	use aliased 'Packages::InCAM::InCAM';

my $jobId = $ENV{"JOB"};
my $inCAM = InCAM->new();

 
	my $fsch = CreateFsch->new( $inCAM, $jobId);
	print $fsch->Create();
