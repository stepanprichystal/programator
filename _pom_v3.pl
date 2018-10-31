#!/usr/bin/perl-w
#################################


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Connectors::HeliosConnector::HegMethods';
use LWP::Simple;


my $jobName = 'D122826';

my @infoPcbOffer = HegMethods->GetExternalDoc($jobName);
							
my @dokuments = split /,/ ,$infoPcbOffer[0]->{'externi_dokumenty'};

foreach my $oneDoc (@dokuments) {
	
	system("c:/Program Files (x86)/Internet Explorer/iexplore.exe", $oneDoc);

	
	print $oneDoc , "\n";
	last;
	
}



