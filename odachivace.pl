#!/usr/bin/perl-w
#################################



#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Connectors::HeliosConnector::HegMethods';

use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';

use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';

my $inCAM    = InCAM->new();

my $frm = SimpleInputFrm->new(-1, "UnARCHIVE", "Set reference of job, for more jobs separate by ';' (f12345;d12345;f....)", \$jobs);
$frm->ShowModal();

my @jobList = split /;/,$jobs;

foreach my $job (@jobList){
		if ($job =~ /[FfDd]\d{5,}/) {
					$job = lc $job;
					
					my $result = _AcquireNew($inCAM, $job);
			
		}
}


sub _AcquireNew {
      my $inCAM = shift;
      my $jobId = shift;

      if($jobId =~ /^[df]\d{5}$/i){
            
            $jobId = JobHelper->ConvertJobIdOld2New($jobId);
      }
      
      # Supress all toolkit exception/error windows
      $inCAM->SupressToolkitException(1);
      my $result = AcquireJob->Acquire($inCAM, $jobId);
      $inCAM->SupressToolkitException(0);
      
      return $result
}
