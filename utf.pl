#!/usr/bin/perl-w

use warnings;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use Archive::Zip;
use File::Find;
use Tk;
use Tk::LabFrame;
use utf8;
use XML::Simple;
use Data::Dumper;


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'HelperScripts::DirStructure';

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Drilling::FinishSizeHoles::SetHolesRun';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::ETesting::MoveElTests';

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::HeliosConnector::HelperWriter';

use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob'; 
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';

use aliased 'Managers::MessageMngr::MessageMngr';


my $inCAM    = InCAM->new();



_NewJobCreate("d238139");

$inCAM->PAUSE ('Jedu dal');


sub _NewJobCreate {
		my $jobId = shift;
		
		my $numberCustomer;
		my $customerName;

							$numberCustomer = HegMethods->GetIdcustomer($jobId);
							

							 
							my @pole = HegMethods->GetUserInfoHelios($jobId);
							$customerName = $pole[0]->{'Zakaznik'};
		   					$customerName =~ s/,/./g;
		   					
		   					$numberCustomer = HegMethods->GetIdcustomer($jobId);
		   					

		   					
		   					$inCAM->HandleException(1);
		   					
		   					$inCAM->SupressToolkitException(1);
								$inCAM -> COM ('new_customer',name=>"$numberCustomer",disp_name=>"$customerName",properties=>'',skip_on_existing=>'yes');
								
								if ($inCAM->{STATUS} != 0) {
										$inCAM -> COM ('delete_customer',disp_name=>"$customerName");
										$inCAM -> COM ('new_customer',name=>"$numberCustomer",disp_name=>"$customerName",properties=>'',skip_on_existing=>'yes');
								}
								
								
							$inCAM->SupressToolkitException(0);
							$inCAM->HandleException(0);
							
							my $custIncamName = _GetInCamCustomer($numberCustomer);
							
							my $messMngr = MessageMngr->new($jobId);
							my @mess = ("$numberCustomer - $customerName  -  $custIncamName");
							my @btn = ("Smazat", "Ponechat");
							$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btn ); 
							my $btnNumber = $messMngr->Result(); 
							
							
							   					

}

sub _GetInCamCustomer {
		my $custNumber = shift;
	
		my $path = EnumsPaths->InCAM_server . "customers\\customers.xml";
	
		$katalog = XMLin("$path");

		my $cust = $katalog->{'customer'}->{$custNumber}->{display_name};
		
		
}