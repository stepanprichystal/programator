#-------------------------------------------------------------------------------------------#
# Description: K nastaveni vrtanych nebo vyslednych otvoru uzivatelem
# Author:RVI
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::FinishSizeHoles::SetHolesRun;


use warnings;
use strict;	
use Tk;

use lib qw(//incam/incam_server/site_data/scripts);
 
use aliased 'Connectors::HeliosConnector::HegMethods';



#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub SetFinishHoles {
	my $self     = shift;
	my $inCAM = shift;
	my $jobName  = shift;
	
	
		#GUI VIEW ###################################
		my $logo_way = "$ENV{'GENESIS_DIR'}/sys/scripts/gatema/drill.gif";
		my $adjustDrill = "vysledne";
	
		#my $pcbType = HegMethods->GetTypeOfPcb($jobName);
		#my $customerName = HegMethods->GetAllByPcbId($jobName)->{'customer'};
		#$inCAM -> PAUSE("aaa $customerName");
		unless (HegMethods->GetAllByPcbId($jobName)->{'customer'} =~ /[Mm][Uu][Ll][Tt][Ii] [Cc][Ii][Rr][Cc][Uu][Ii][Tt] [Bb]/ and HegMethods->GetTypeOfPcb($jobName) ne 'Jednostranny') {
		 		my $main = MainWindow->new;
					$main->title('Vys/Vrt');
					$main->minsize(qw(220 120));

					my $topMain = $main->Frame(-width=>10, -height=>20)->pack(-side=>'top');
							my $topMainLeft = $topMain->Frame(-width=>10, -height=>20)->pack(-side=>'left');
							my $topMainRight = $topMain->Frame(-width=>10, -height=>20)->pack(-side=>'right');
									my $topMainRightTop = $topMainRight->Frame(-width=>10, -height=>20)->pack(-side=>'top',-fill=>'x');
									my $topMainRightBot = $topMainRight->Frame(-width=>10, -height=>20)->pack(-side=>'bottom',-fill=>'x');
					my $botMain = $main->Frame(-width=>10, -height=>20)->pack(-side=>'bottom',-fill=>'x');
			
					my $logo_frame = $topMainLeft->Frame(-width=>50, -height=>50)->pack(-side=>'left');
										my $error_logo = $logo_frame->Photo(-file=>"$logo_way");
										$logo_frame->Label(-image=>$error_logo)->pack(); 
		
						$topMainRightTop->Radiobutton(-value=>"vysledne", -variable=>\$adjustDrill, -text=>"vysledne",-font=>'arial 12 {bold}')->pack(-padx => 5, -pady => 5,-side=>'left');
						$topMainRightBot->Radiobutton(-value=>"vrtane", -variable=>\$adjustDrill, -text=>"vrtane",-font=>'arial 12 {bold}')->pack(-padx => 5, -pady => 5,-side=>'left');

						$botMain->Button(-height=>2, -text => "NASTAVIT",-command=>sub {_RunSet($inCAM, $jobName, $adjustDrill)},-bg=>'grey',-relief=>'raise',-bd=>'3')->pack(-padx => 1, -pady => 1,-side=>'bottom',-fill=>'x');
				MainLoop ();

		}else {
			$adjustDrill = 'vysledne';
			_RunSet($inCAM, $jobName, $adjustDrill);
		}
		##END GUI #################################

}
	
	
sub _RunSet {
		my $inCAM = shift;
		my $jobName = shift;
		my $userSet = shift;
		
				$inCAM -> COM('tools_set',layer=>'m',thickness=>'0',user_params=>"$userSet");
				$inCAM -> COM('tools_recalc');



				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/f",data_type=>'exists');
			    		if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
								$inCAM -> COM('tools_set',layer=>'f',thickness=>'0',user_params=>'vrtane');
								$inCAM -> COM('tools_recalc');
						}


	return();
}

1;