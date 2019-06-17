#-------------------------------------------------------------------------------------------#
# Description: K nastaveni vrtanych nebo vyslednych otvoru uzivatelem
# Author:RVI
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::FinishSizeHoles::SetHolesRun;


use warnings;
use strict;	
use Tk;

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::Other::CustomerNote'; 
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::GuideSubs::Routing::DoSetDTM';
use aliased 'Managers::MessageMngr::MessageMngr';

use aliased 'CamHelpers::CamDTM';


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub CalculationDrills {
	my $self  = shift; 
	my $inCAM = shift;
	my $jobName = shift;
	
	my $customer = HegMethods->GetCustomerInfo($jobName);
	my $note = CustomerNote->new( $customer->{"reference_subjektu"} );
	

		if (HegMethods->GetTypeOfPcb($jobName) eq 'Jednostranny') {
					_SetDrill($inCAM, EnumsDrill->DTM_VRTANE, $jobName);
			
		}elsif($note->PlatedHolesType() ne undef){
				# Vraci tri hodnoty
				#- undef
				# EnumsDrill->DTM_VYSLEDNE
				# EnumsDrill->DTM_VRTANE
				my $usrHolesType = $note->PlatedHolesType();
				_SetDrill($inCAM, $usrHolesType, $jobName);
		}else{
			_Gui($inCAM, $jobName);
			
		}
}
# GUI ###################################
sub _Gui {
		my $inCAM = shift;
		my $jobId = shift;
		my $adjust = '';
		
		
		
		my $logo_way = GeneralHelper->Root()."\\_from_z\\drill.gif";
		my $main = MainWindow->new;
		$main->title('Vys/Vrt Job =>' . $jobId);
		$main->minsize(qw(260 50));

			my $subMain = $main->Frame(-width=>100, -height=>50)->pack(-side=>'top');
				my $left = $subMain->Frame(-width=>100, -height=>50)->pack(-side=>'left', -fill=>'both');
						my $logomain = $left->Frame(-width=>100, -height=>50)->pack(-side=>'left', -fill=>'both');
								my $logo_frame = $logomain->Frame(-width=>50, -height=>50)->pack(-side=>'left');
									my $error_logo = $logo_frame->Photo(-file=>"$logo_way");
									   $logo_frame->Label(-image=>$error_logo)->pack(); 
						
				my $right = $subMain->Frame(-width=>100, -height=>50)->pack(-side=>'right');
						my $subRightTop = $right->Frame(-width=>100, -height=>25)->pack(-side=>'top',-fill=>'both');
									$subRightTop->Radiobutton(-value=>"vysledne", -variable=>\$adjust, -text=>"vysledne",-font=>'arial 12 {bold}')->pack(-side=>'left',-padx => 5, -pady => 5);
						my $subRightBot = $right->Frame(-width=>100, -height=>25)->pack(-side=>'top',-fill=>'both');
									$subRightBot->Radiobutton(-value=>"vrtane", -variable=>\$adjust, -text=>"vrtane",-font=>'arial 12 {bold}')->pack(-side=>'left',-padx => 5, -pady => 5);
			
			my $bottom = $main->Frame(-width=>100, -height=>50)->pack(-side=>'bottom', -fill=>'both');
						$bottom->Button(-height => "3", -text => "Pokracovat",-command=> sub {_SetDrill($inCAM, $adjust, $jobId); $main->destroy},-bg=>'grey',-relief=>'raise',-bd=>'3')->pack(-padx => 5, -pady => 5,-side=>'bottom', -fill=>'both');
			
			
		MainLoop ();
		
}

sub _SetDrill {
	  my $inCAM = shift;
      my $adjustDrill = shift;
      my $jobId       = shift;
      my $layerDrill = 'm';
      my $layerMill = 'f';
      my $layerPltMill = 'r';

      # 1) Reset DTM (vymazani),
      # 2) Nastaveni vysledne/vrtane
      # 3) Pridani nastroju do DTM + recalculate tools by drill_size_hook
      my $holes  = 1;    # recalculate holes type
      my $slots  = 0;    # recalculate slots type

	  my $res2 = DoSetDTM->MoveHoles2RoutBeforeDTMRecalc( $inCAM, $jobId, "o+1", $layerDrill, $layerPltMill, $adjustDrill );
	  
	  CamDTM->RecalcDTMTools( $inCAM, $jobId, "o+1", $layerDrill, $adjustDrill, $holes, $slots );
      
      
      # ROUT layer
      my $res = DoSetDTM->MoveHoles2RoutBeforeDTMRecalc( $inCAM, $jobId, "o+1", $layerMill, $layerMill, EnumsDrill->DTM_VRTANE );
      
      CamDTM->RecalcDTMTools( $inCAM, $jobId, "o+1", $layerMill, EnumsDrill->DTM_VRTANE, $holes, $slots );

       
   
       

}

1;