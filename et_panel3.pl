#!/usr/bin/perl-w
use Genesis;
use warnings;
use strict;


my ($jobName, $ipcStep);

unless ($ENV{JOB}) {
	$jobName = shift;
    $ipcStep = shift;
    
}else{
	$jobName = "$ENV{JOB}";
    $ipcStep = 'special';
}

my $genesis = new Genesis;
my $etNamepanel = 'et_panel';
my $panel = 'panel';

				if($ipcStep eq 'special') {
					create_et_panel();
					removeCoupon();
					my $layersSignal = flatten_layers();
					removeTab();
					if($layersSignal > 2) {
							multiLayerMOVE();
					}
					remove_mask_PTHrout();
					return();
				}

##################################################################################################################################################		
############		PODPROGRAMY   ################################################################################################################
##################################################################################################################################################
##################################################################################################################################################		
sub create_et_panel {
	$genesis->COM('clipb_open_job',job=>"$jobName",update_clipboard=>"view_job");
	$genesis->COM('copy_entity',type=>'step',source_job=>"$jobName",source_name=>"$panel",dest_job=>"$jobName",dest_name=>"$etNamepanel",dest_database=>'');
	
    $genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$etNamepanel",iconic=>'no');
    
    $genesis->AUX('set_group', group => $genesis->{COMANS});
   	$genesis->COM('units',type=>'mm');
   	
   	$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"yes");
   	
   	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$etNamepanel/fr",data_type=>'exists');
    		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
   					$genesis->COM('affected_layer',name=>'fr',mode=>'single',affected=>'no');
   			}
	$genesis->COM('sel_delete');
	$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
}

sub flatten_layers {
	my @layersFlatten = ();
	my $layerCount = 0;
	$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
		my $totalRows = @{$genesis->{doinfo}{gROWname}};
  				for (my $count=0;$count<$totalRows;$count++) {
  					if( $genesis->{doinfo}{gROWtype}[$count] ne "empty" ) {
  						my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
  						my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
  						my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
  						my $rowSide = ${$genesis->{doinfo}{gROWside}}[$count];
  			
  						if ($rowContext eq "board" && $rowName ne "fr" && $rowName ne "v1" && $rowName ne "f" && $rowName ne "pc" && $rowName ne "ps") {
  							push(@layersFlatten, $rowName );
  						}
  						if ($rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground")) {
            					$layerCount ++;
						}
  					}
  				}
				foreach my $oneLayer (@layersFlatten) {
					$genesis->COM('flatten_layer',source_layer=>"$oneLayer",target_layer=>"${oneLayer}_eeelll_");
				}
				foreach my $oneLayer (@layersFlatten) {
					$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$etNamepanel",source_layer=>"${oneLayer}_eeelll_",dest=>'layer_name',dest_layer=>"$oneLayer",mode=>'replace',invert=>'no');
					$genesis -> COM ('delete_layer',layer=>"${oneLayer}_eeelll_");
				}
				$genesis -> COM ('sr_active',top=>'0',bottom=>'0',left=>'0',right=>'0');
		return($layerCount);
}			
sub removeTab {
	$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$etNamepanel",data_type => 'NUM_SR');
			    my $numStepPanel = $genesis->{doinfo}{gNUM_SR};
  					for(my $z=1;$z<=$numStepPanel;$z++) {
 				 			$genesis->COM('sr_tab_del',line=>'1');
  					}
}
sub removeCoupon {
		my $existEnd = 0;
		
		$genesis->COM('clipb_open_job',job=>"$jobName",update_clipboard=>"view_job");
		$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$etNamepanel",iconic=>'no');
    	$genesis->AUX('set_group', group => $genesis->{COMANS});
   		$genesis->COM('units',type=>'mm');
   		
		while(1) {
		$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$etNamepanel",data_type => 'SR');
			    my @nameOFsteps = @{$genesis->{doinfo}{gSRstep}};
			    foreach my $oneItem (@nameOFsteps) {
			    		if ($oneItem =~ /coupon/) {
			    			$existEnd = 1;
			    		}else{
			    			$existEnd = 0;
			    		}
			    }
			    
			    if ($existEnd == 1) {
			    		my $count = 1;
			    		foreach my $oneItem (@nameOFsteps) {
					    		if ($oneItem =~ /coupon/) {
			    						$genesis->COM('sr_tab_del',line=>"$count");
			    						next;
			    				}
			    			$count++;
			    		}
				}else{
						last;
				}
		}
		
		
}

sub remove_mask_PTHrout {
	my $maskExist = 0;
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$etNamepanel/r",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    				$genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$etNamepanel",iconic=>'no');
			    	$genesis->AUX('set_group', group => $genesis->{COMANS});
				    $genesis->COM('units',type=>'mm');
				    
					$genesis->COM('display_layer',name=>'r',display=>'yes',number=>'1');
					$genesis->COM('work_layer',name=>'r');
					$genesis->COM('compensate_layer',source_layer=>'r',dest_layer=>'r__wcom',dest_layer_type=>'rout');
					$genesis->COM('display_layer',name=>'r',display=>'no',number=>'1');
					$genesis->COM('display_layer',name=>'r__wcom',display=>'yes',number=>'1');
					$genesis->COM('work_layer',name=>'r__wcom');
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$etNamepanel/mc",data_type=>'exists');
				    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {	
								$genesis->COM('affected_layer',name=>'mc',mode=>'single',affected=>'yes');
								$maskExist = 1;
						}
				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$etNamepanel/ms",data_type=>'exists');
				    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {	
								$genesis->COM('affected_layer',name=>'ms',mode=>'single',affected=>'yes');	
								$maskExist = 1;
						}
			if($maskExist) {
				$genesis->COM('sel_copy_other',dest=>'affected_layers',target_layer=>'',invert=>'yes',dx=>'0',dy=>'0',size=>'50');
				$genesis->COM('affected_layer',mode=>'all',affected=>'no');
				$genesis->COM('delete_layer',layer=>'r__wcom'); 
			}else{
				$genesis->COM('delete_layer',layer=>'r__wcom'); 
			}
			$genesis->COM ('editor_page_close');
		}
}
sub multiLayerMOVE {
		my $coverX = -3;
		my $coverY = -3;
			
			$genesis -> COM('create_layer',layer=>'new_prof',context=>'misc',type=>'document',polarity=>'positive',ins_layer=>'fr');
			$genesis -> COM('display_layer',name=>'new_prof',display=>'yes',number=>'1');
			$genesis -> COM('work_layer',name=>'new_prof');
			
			$genesis->COM ('add_polyline_strt');
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$etNamepanel/fr",data_type => 'LIMITS');
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
			$genesis->COM ('add_polyline_end',attributes=>'no',symbol=>'r2',polarity=>'positive');
			$genesis->COM ('affected_layer',name=>"",mode=>"all",affected=>"no");
   			$genesis->COM ('display_layer',name=>'new_prof',display=>'no',number=>'1');
			$genesis->COM ('filter_reset',filter_name=>'popup');
			
			
			
							$genesis->COM('display_layer',name=>'new_prof',display=>'yes',number=>'1');
							$genesis->COM('work_layer',name=>'new_prof');
						    $genesis->COM('filter_reset',filter_name=>'popup');
  						    $genesis->COM('filter_area_strt');
						    $genesis->COM('filter_area_end',layer=>'o',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
   							
   							$genesis->COM('sel_create_profile');
  						 	$genesis->COM('filter_reset',filter_name=>'popup');

   								$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$etNamepanel",data_type => 'PROF_LIMITS');
  							    my $spodniXbod = $genesis->{doinfo}{gPROF_LIMITSxmin};
								my $spodniYbod = $genesis->{doinfo}{gPROF_LIMITSymin};
	
												my $moveX = ($spodniXbod * (-1));
												my $moveY = ($spodniYbod * (-1));

	
   						$genesis->COM('affected_layer',mode=>'all',affected=>'yes');
   						$genesis->COM('sel_move',dx=>"$moveX",dy=>"$moveY");
					    $genesis->COM('affected_layer',mode=>'all',affected=>'no');
						$genesis->COM('filter_reset',filter_name=>'popup');
					    $genesis->COM('filter_area_strt');
						$genesis->COM('filter_area_end',layer=>'new_prof',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
						$genesis->COM('sel_create_profile');
   						$genesis->COM('filter_reset',filter_name=>'popup');
   						$genesis->COM('delete_layer',layer=>'new_prof'); 
						$genesis->COM('editor_page_close');
}
