#-------------------------------------------------------------------------------------------#
# Description: Helper module for InCAM Drill tool manager
# Author:RVI
#-------------------------------------------------------------------------------------------#

package Packages::Compare::Layers::CompareLayers;

#3th party library
use strict;
use warnings;

use Tk;
use Tk::LabFrame;
use Tk::BrowseEntry;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;


use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';


#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub CompareOrigLayers {
		my $self = shift;
		my $inCAM = shift;
		my $jobId = shift;
		my $origStep = 0;
		my $worksStep = 'o+1';
		
		CamLayer->ClearLayers($inCAM);

		$origStep = CamStep->GetReferenceStep($inCAM, $jobId, $worksStep);
		
		
		$inCAM->COM ('set_step',name=>$worksStep);
		
		
		my @layers = CamJob->GetBoardLayers($inCAM, $jobId);
		
		foreach my $l (@layers){
					CamLayer->WorkLayer($inCAM, $l->{"gROWname"});
						
					CamLayer->DisplayFromOtherStep($inCAM, $jobId, $origStep, $l->{"gROWname"});
			
					$inCAM->COM ('zoom_home');
					$inCAM->COM( "show_component",component=>"Result_Viewer",show=>"no",width=>"0",height=>"0");
					$inCAM->COM( "sel_clear_feat");
					$inCAM->COM( "clear_highlight");
					$inCAM->PAUSE ('Zkontroluj - ( vrstva => ' . $l->{"gROWname"} . ' ) ( originalni step => ' . $origStep . ' )');
	
		}
		
		CamLayer->ClearLayers($inCAM);
}


sub _SelectOrigStep {
		my @steps = @_;
		my @returnStep = ();
		
		
		#my @stepsList = grep { $currentStep ne $_ } @steps;
		my @stepsList = @steps;
		
  			my $mainStep = MainWindow->new();
  			$mainStep->Label(-text=>"Vyber DVA stepy pro porovnani - ORIGINALNI + REFERENCNI",-font=>"Arial 10 bold")->pack(-padx => 0, -pady => 0,-side=>'top');
  		
  			my $mainWindow = $mainStep->Frame(-width=>80, -height=>40)->pack(-side=>'top', -fill=>'both');
  			
  			my $stepWin = $mainWindow->Listbox(-font=>'ARIAL 12', -selectmode=>'multiple')->pack();
  			$stepWin->insert('end',@stepsList);
  		
			
  			my $exitBttn = $mainStep->Button(-text => "Pokracovat", -command =>\sub{foreach my $i ($stepWin->curselection){push @returnStep, $stepsList[$i];};$mainStep->destroy;})->pack(-side=>'top', -fill=>'both');
  				
  			$mainStep->waitWindow;
  			
  			unless(@returnStep) {
  						exit;
  			}else{
  				if (scalar @returnStep > 2 or scalar @returnStep == 1){
  						@returnStep = _SelectOrigStep();
  				}
		  	}
  	return(@returnStep);
}




#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#


1;