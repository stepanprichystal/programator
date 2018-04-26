#!/usr/bin/perl-w
#################################



#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';

my $inCAM    = InCAM->new();

my $frm = SimpleInputFrm->new(-1, "UnARCHIVE", "Set reference of job, for more jobs separate by ';' (f12345;d12345;f....)", \$jobs);
$frm->ShowModal();

my @jobList = split /;/,$jobs;

foreach my $job (@jobList){
		if ($job =~ /[FfDd]\d{5,}/) {
					$job = lc $job;
					
					unless (CamJob->JobExist($inCAM, $job)) {
			  				my @pole = HegMethods->GetAllByPcbId("$job");
			  				my $outputDir = $pole[0]->{'archiv'};
		   	  				   $outputDir =~ s/\\/\//g;
		   	  				   
		   	  				   $inCAM->COM('import_job',db=>"incam",path=>"$outputDir/$job.tgz",name=>"$job",analyze_surfaces=>'no');
		   	  		}
			
		}
}