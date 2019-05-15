#!/usr/bin/perl-w
#################################
#Sript name: Skript pro zkopirovani MASTER desky do noveho decka
#Verze     : 6.6.2014 RVI
#################################
use Tk;
use Tk::LabFrame;
use Tk::BrowseEntry;


#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Programs::Services::TpvService::ServiceApps::CheckReorderApp::CheckReorder::AcquireJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::HeliosConnector::HelperWriter';

use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';

my $inCAM = InCAM->new();


	
my $main = MainWindow->new;

$frame1 = $main->Frame(-width=>100, -height=>80)->pack(-side=>'top',-fill=>'both');
$frame2 = $main->Frame(-width=>100, -height=>80)->pack(-side=>'top',-fill=>'both');

$frame1->Label(-text => " OLD JOB ")->pack(-padx => 24, -pady => 5,-side=>'left');
$oldJob = $frame1->Entry(-width=>10)->pack(-padx => 5, -pady => 5,-side=>'left');
$newJob = $frame1->Entry(-width=>10)->pack(-padx => 5, -pady => 5,-side=>'right');
$frame1->Label(-text => " NEW JOB ")->pack(-padx => 24, -pady => 5,-side=>'right');

$tl_ok=$main->Button(-text => "ok",-command=> \&proved);
$tl_ok->pack(-padx => 10, -pady => 5,-side=>'right');


$infoKT = $frame2->Label(-text => "")->pack(-padx => 24, -pady => 5,-side=>'top');
$infoNote = $frame2->Label(-text => "")->pack(-padx => 24, -pady => 5,-side=>'top');
$infoDatacode = $frame2->Label(-text => "")->pack(-padx => 24, -pady => 5,-side=>'top');
$infoMaska = $frame2->Label(-text => "")->pack(-padx => 24, -pady => 5,-side=>'top');
$infoRemove = $frame2->Label(-text => "")->pack(-padx => 24, -pady => 5,-side=>'top');

MainLoop ();


sub proved {
	$oldName = $oldJob -> get;
	$jobName = $newJob -> get;
	   
	   
	   my $testDelete = delete_empty_folder($jobName);
	   

	   	 $inCAM -> INFO (entity_type =>"job",entity_path=>"$jobName",data_type=>"EXISTS");
    			if ($inCAM->{doinfo}{gEXISTS} eq "yes") { 
        				$main->messageBox(-message => "Nekdo te predbehl!:)", -type => "ok");    
    				exit;  
    			} 
       
       
       $inCAM -> INFO (entity_type =>"job",entity_path=>"$oldName",data_type=>"EXISTS");
       				if ($inCAM->{doinfo}{gEXISTS} eq "no") { 
					 						my $result = _AcquireNew($inCAM, $oldName);
					 						if ($oldName =~ /[df]\d{5}$/) {
													$oldName =~ s/d/d0/;
													$oldName =~ s/f/d1/;
					 						}
					}
    			$inCAM -> COM ('copy_entity',type=>'job',source_job=>"$oldName",source_name=>"$oldName",dest_job=>"$jobName",dest_name=>"$jobName",dest_database=>'incam');


	   			my ($kt, $poznamka, $datacode, $maska01) = get_old_nif ($oldName);
						  $infoKT->configure(-text=>"Konst.Trida= $kt");
						  $infoNote->configure(-text=>"Poznamky= $poznamka");
						  $infoDatacode->configure(-text=>"Datacode= $datacode");
						  $infoMaska->configure(-text=>"Maska01= $maska01");
						  $infoRemove->configure(-text=>"$testDelete");
   						


    			$inCAM->COM ("clipb_open_job",job=>"$jobName",update_clipboard=>"view_job");
    			
    			
				$inCAM->INFO(entity_type=>'step',entity_path=>"$jobName/panel",data_type=>'exists');
						if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							$inCAM->COM('delete_entity',job=>"$jobName",type=>'step',name=>"panel");
							
							$inCAM->INFO(entity_type => 'job',entity_path => "$jobName",data_type => 'STEPS_LIST');
							my @stepsList = @{$inCAM->{doinfo}{gSTEPS_LIST}};
							foreach my $stepName (@stepsList) {
    								if ($stepName =~ /[df]\d{5,}/) {
        								$inCAM->COM('delete_entity',job=>"$jobName",type=>'step',name=>"$stepName");
    								}elsif($stepName =~ /et_panel/) {
    									$inCAM->COM('delete_entity',job=>"$jobName",type=>'step',name=>"$stepName");
    								}
							}
							
						}
						
		$inCAM->COM ('set_step',name=>"o+1");



		$inCAM->COM('clear_layers');
		$inCAM->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
		$inCAM->COM ('filter_reset',filter_name=>'popup');

		my @signal_layers = CamJob->GetSignalLayerNames($inCAM, $jobName);
		
				foreach my $oneItem (@signal_layers) {
    							do_remove($oneItem);
				}
		my @layers = CamJob->GetAllLayers($inCAM, $jobName);

				foreach my $l (@layers) {
						delete_empty($l->{gROWname});
				}
		
		_SetMaskSilkHelios($jobName);
		$inCAM -> COM('checkin_closed_job',job=>"$oldName");
}

sub do_remove {
	my $justLayer = shift;
		$inCAM->COM ('display_layer',name=>"$justLayer",display=>'yes',number=>'1');
		$inCAM->COM ('work_layer',name=>"$justLayer");

			$inCAM->COM('filter_set',filter_name=>'popup',update_popup=>'no',profile=>'out');
			$inCAM->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
					if ($inCAM->{COMANS} > 0) {
							$inCAM->COM('sel_delete');
					}	
		$inCAM->COM ('display_layer',name=>"$justLayer",display=>'no',number=>'1');
}

sub get_old_nif {
	my $job = shift;
	my ($a,$b,$c,$d);
	
	
	my @infoPcbOffer = HegMethods->GetAllByPcbId($job);
	my $pathToNif = $infoPcbOffer[0]{'archiv'};
	$pathToNif =~ s/\\/\//g;
		   						
		   						
	if (-e "$pathToNif/$job.bac") {
 				open (OLDNIF,"$pathToNif/$job.bac");
 			         while (<OLDNIF>) {
 			         		if ($_ =~ /kons_trida=(\d)/) {
 			                         $a = $1;
 			             	}
 			             	if ($_ =~ /poznamka=(.*)/) {
 			                         $b = $1;
 			             	}
 			             	if ($_ =~ /datacode=(.*)/) {
 			                         $c = $1;
 			             	}
 			             	if ($_ =~ /=-2814075/) {
 			                         $d = 'N';
 			             	}
 			             	if ($_ =~ /=2814075/) {
 			                         $d = 'A';
 			             }
 			         }
 				close OLDNIF;
 	}else{
 		 		open (OLDNIF,"$pathToNif/$job.nif");
 			         while (<OLDNIF>) {
 			         		if ($_ =~ /kons_trida=(\d)/) {
 			                         $a = $1;
 			             	}
 			             	if ($_ =~ /poznamka=(.*)/) {
 			                         $b = $1;
 			             	}
 			             	if ($_ =~ /datacode=(.*)/) {
 			                         $c = $1;
 			             	}
 			             	if ($_ =~ /=-2814075/) {
 			                         $d = 'N';
 			             	}
 			             	if ($_ =~ /=2814075/) {
 			                         $d = 'A';
 			             }
 			         }
 				close OLDNIF;
	}
	return($a,$b,$c,$d);

}
sub delete_empty {
	my $layerEmpty = shift;
			$inCAM->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/o+1/$layerEmpty",data_type => 'FEAT_HIST');
					if ($inCAM->{doinfo}{gFEAT_HISTtotal} == 0) {
							$inCAM->COM ('delete_layer',layer=>"$layerEmpty");

					}
					if ($layerEmpty =~ /mk_1_/) {
							$inCAM->COM ('delete_layer',layer=>"$layerEmpty");
					}elsif($layerEmpty =~ /ms_1_/) {
							$inCAM->COM ('delete_layer',layer=>"$layerEmpty");
					}
}
sub delete_empty_folder {
	my $job = uc(shift);
	my $pathToNif = 'r:/PCB'; 
	my $infoText;
				if (-e "$pathToNif/$job") {
						if(rmdir "$pathToNif/$job" == 0) {
								$infoText =  "Pozor nesmazal jsem na pcb data, je tam plna slozka, zkontroluj!";
						}
				}
	return($infoText);
}
sub _SetMaskSilkHelios {
		my $jobId = shift;
		my $step = 'o+1';
		
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$step/pc",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "B", "potisk_c_1");
					}else{
							HelperWriter->OnlineWrite_pcb("$jobId", "", "potisk_c_1");
					}
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$step/ps",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "B", "potisk_s_1");
					}else{
							HelperWriter->OnlineWrite_pcb("$jobId", "", "potisk_s_1");
					}
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$step/mc",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "Z", "maska_c_1");
					}else{
							HelperWriter->OnlineWrite_pcb("$jobId", "", "maska_c_1");
					}
				$inCAM->INFO(entity_type=>'layer',entity_path=>"$jobId/$step/ms",data_type=>'exists');
					if ($inCAM->{doinfo}{gEXISTS} eq "yes") {
							HelperWriter->OnlineWrite_pcb("$jobId", "Z", "maska_s_1");
					}else{
							HelperWriter->OnlineWrite_pcb("$jobId", "", "maska_s_1");
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