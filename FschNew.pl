#!/usr/bin/perl
use FindBin;						
use lib "$FindBin::Bin/../";		
use PackagesLib;use aliased 'Packages::InCAM::InCAM';	
use aliased 'Packages::Routing::RoutLayer::FlattenRout::CreateFsch';

my $inCAM = InCAM->new();
my $jobName = shift;
my $fsch = CreateFsch->new( $inCAM, "$jobName");

$fsch->Create();
