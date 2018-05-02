#!/usr/bin/perl-w
#################################################################################################################################
#################################################################################################################################
use Genesis;
use sqlNoris;
use warnings;
use strict;


my $genesis = new Genesis;
my $cestaExportu = 'c:/Export';
my $job = "$ENV{JOB}";

make_layer_genesis("$job");


sub make_layer_genesis {
		my $jobName = shift;
			
					$genesis -> INFO (entity_type =>"job",entity_path=>"$jobName",data_type=>"EXISTS");
    				if ($genesis->{doinfo}{gEXISTS} eq "no") { 
        				$genesis-> COM ("acquire_job",job=>"$jobName",db=>"genesis");
        			}
												$genesis -> VOF;
												$genesis-> COM ('open_job',job=>"$jobName");
												my $stat2 = $genesis->{STATUS};
												$genesis -> VON;
												unless ($stat2) {
													
	    												
	    												$genesis->COM ('set_step',name=>'panel');
	    												
														$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/pc",data_type=>'exists');
													 	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
													 			(my $madeLayer, my $mirror) = delete_features('pc',$jobName);
													 			copy_features("$madeLayer",$jobName);
													 			spill_compenzation("$madeLayer",$jobName);
													 			multiLayerMOVE("$madeLayer",$jobName);
													 			get_gerber_jetPrint("$madeLayer",$jobName, $mirror);
													 	}
													 	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/ps",data_type=>'exists');
													 	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
													 			(my $madeLayer, my $mirror) = delete_features('ps',$jobName);
													 			copy_features("$madeLayer",$jobName);
													 			spill_compenzation("$madeLayer",$jobName);
													 			multiLayerMOVE("$madeLayer",$jobName);
													 			get_gerber_jetPrint("$madeLayer",$jobName, $mirror);
													 	}
													
#														$genesis -> COM ('close_job',job=>"$jobName");
#														$genesis -> COM ('close_form',job=>"$jobName");
#														$genesis -> COM ('close_flow',job=>"$jobName");
												}
}

sub delete_features {
		my $silkItem = shift;
		my $jobName = shift;
		my $tmpSufix = 'jet';
		my $mirrorGerber;
		my $deleteFrame = -1;
	
	    
		$genesis->COM ('display_layer',name=>"$silkItem",display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>"$silkItem");
		
			$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/$silkItem",data_type=>'SIDE');
					if ($genesis->{doinfo}{gSIDE} eq 'top') {
							$mirrorGerber = 'no';
					}else{
							$mirrorGerber = 'yes';
					}
	
  			$genesis->COM ('clear_layers');
  				$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/${silkItem}_$tmpSufix",data_type=>'exists');
  		    		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
  		    				$genesis->COM ('delete_layer',layer=>"${silkItem}_$tmpSufix");
  		    		}
  		    	
  		$genesis->COM ('flatten_layer',source_layer=>"$silkItem",target_layer=>"${silkItem}_$tmpSufix");
  		$genesis->COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>"${silkItem}_$tmpSufix",type=>'silk_screen');
  		
  		$genesis->COM ('display_layer',name=>"${silkItem}_$tmpSufix",display=>'yes',number=>'1');
  		$genesis->COM ('work_layer',name=>"${silkItem}_$tmpSufix");
  		
  		###### 1. odmazani ramecku
		$genesis->COM ('clip_area_strt');
		$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/panel/${silkItem}_$tmpSufix",data_type => 'LIMITS');
		$genesis->COM ('clip_area_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$deleteFrame",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$deleteFrame");
		$genesis->COM ('clip_area_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$deleteFrame",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$deleteFrame");
		$genesis->COM ('clip_area_end',layers_mode=>'layer_name',layer=>"${silkItem}_$tmpSufix",area=>'manual',area_type=>'rectangle',inout=>'outside',contour_cut=>'no',margin=>'0',feat_types=>'line\;pad\;surface\;arc\;text');
		###### 1. KONEC odmazani ramecku
		
		###### 2. odmazani nepotrebneho textu
		$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'T-User*',min_int_val=>'999',max_int_val=>'999');
		$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'T-Time*',min_int_val=>'999',max_int_val=>'999');
		$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'T-Date*',min_int_val=>'999',max_int_val=>'999');
		$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'T-Day*',min_int_val=>'999',max_int_val=>'999');
		$genesis->COM ('filter_atr_logic',filter_name=>'popup',logic=>'or');
		$genesis->COM ('filter_area_strt');
		$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
		$genesis->COM ('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_delete');
					}
 		$genesis->COM ('filter_reset',filter_name=>'popup');
 		###### 2. KONEC odmazani nepotrebneho textu
 	
 	
 		###### 3. odmazani navadecich 3.2 atd.
		$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'yes',attribute=>'.geometry',min_int_val=>0,max_int_val=>0,min_float_val=>0,max_float_val=>0,option=>'',text=>'centre*');
		
		#$genesis->COM ('set_filter_and_or_logic',filter_name=>'popup',criteria=>'inc_attr',logic=>'or');
		$genesis->COM ('filter_area_strt');
		$genesis->COM ('filter_area_end',filter_name=>'popup',operation=>'select');
 		$genesis->COM ('get_select_count');
			if ($genesis->{COMANS} > 0) {
					$genesis->COM ('sel_delete');
					}
 		$genesis->COM ('filter_reset',filter_name=>'popup');
 		###### 3. KONEC odmazani navadecich 3.2 atd.
 		
 		
 		my $layerCount = get_layer_count($jobName);
 		my $coverX = -1;
		my $coverY = -1;
 		if ($layerCount > 2) {
 		 		$genesis->COM ('add_polyline_strt');
		 		$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/panel/fr",data_type => 'LIMITS');
				$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
				$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
				$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$coverY");
				$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$coverY");
				$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
		 		$genesis->COM ('add_polyline_end',attributes=>'no',symbol=>'r100',polarity=>'positive');
		 		$genesis->COM ('affected_layer',name=>"",mode=>"all",affected=>"no");
		 		$genesis->COM ('filter_reset',filter_name=>'popup');
		}else{	
				$genesis->COM ('profile_to_rout', layer=>"${silkItem}_$tmpSufix", width=>'100');
		}
 	return("${silkItem}_$tmpSufix",$mirrorGerber);
}

sub copy_features {
		my $silkItem = shift;
		my $jobName = shift;
		
		if(getValueNoris ($jobName,'typ_desky') ne 'Jednostranny') {
				$genesis->COM ('clear_layers');
				$genesis->COM ('display_layer',name=>"$silkItem",display=>'yes',number=>'1');
				$genesis->COM ('work_layer',name=>"$silkItem");
				
				$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>'SF-*',min_int_val=>'999',max_int_val=>'999');
				$genesis->COM ('filter_area_strt');
				$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
				$genesis->COM ('get_select_count');
					if ($genesis->{COMANS} == 0) {
							$genesis->COM ('clear_layers');
							$genesis->COM ('filter_reset',filter_name=>'popup');
							$genesis->COM ('display_layer',name=>"c",display=>'yes',number=>'1');
							$genesis->COM ('work_layer',name=>"c");
				   		
							$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'s1500');
				   			$genesis->COM ('filter_area_strt');
							$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
							$genesis->COM ('get_select_count');
							if ($genesis->{COMANS} > 0) {
									$genesis->COM ('sel_copy_other',dest=>'layer_name',target_layer=>"$silkItem",invert=>'no',dx=>'0',dy=>'0',size=>'0',x_anchor=>0,y_anchor=>0,rotation=>0,mirror=>'none');
							}
							$genesis->COM ('display_layer',name=>"c",display=>'no',number=>'1');
							
					}		
				$genesis->COM ('filter_reset',filter_name=>'popup');
				$genesis->COM ('clear_layers');
		}else{
							$genesis->COM ('clear_layers');
							$genesis->COM ('filter_reset',filter_name=>'popup');
							$genesis->COM ('display_layer',name=>"m",display=>'yes',number=>'1');
							$genesis->COM ('work_layer',name=>"m");
							

							$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'yes',attribute=>'.pnl_place',min_int_val=>0,max_int_val=>0,min_float_val=>0,max_float_val=>0,option=>'',text=>'M-right-top-c');
							$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'yes',attribute=>'.pnl_place',min_int_val=>0,max_int_val=>0,min_float_val=>0,max_float_val=>0,option=>'',text=>'M-right-bot-c');
							$genesis->COM ('set_filter_attributes',filter_name=>'popup',exclude_attributes=>'no',condition=>'yes',attribute=>'.pnl_place',min_int_val=>0,max_int_val=>0,min_float_val=>0,max_float_val=>0,option=>'',text=>'M-left-bot-c');
							
							$genesis->COM ('set_filter_and_or_logic',filter_name=>'popup',criteria=>'inc_attr',logic=>'or');
							$genesis->COM ('filter_area_strt');
							$genesis->COM ('filter_area_end',filter_name=>'popup',operation=>'select');
							$genesis->COM ('get_select_count');
									if ($genesis->{COMANS} > 0) {
											$genesis->COM ('sel_copy_other',dest=>'layer_name',target_layer=>"$silkItem",invert=>'no',dx=>'0',dy=>'0',size=>'0',x_anchor=>0,y_anchor=>0,rotation=>0,mirror=>'none');
									}
							
							$genesis->COM ('display_layer',name=>"m",display=>'no',number=>'1');
							$genesis->COM ('filter_reset',filter_name=>'popup');					
							$genesis->COM ('affected_layer',mode=>'all',affected=>'no');
							$genesis->COM ('clear_layers');
		}
}
sub spill_compenzation {
		my $silkItem = shift;
		my $jobName = shift;
		my $valueOFcomp = 60; # hodnota kompenzace pro rozliti potisku
			
		######### NEGATIVNI SYMBOLY
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
			$genesis -> COM ('display_layer',name=>"$silkItem",display=>'yes',number=>'1');
			$genesis -> COM ('work_layer',name=>"$silkItem");
			$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
			$genesis -> COM ('filter_area_strt');
			$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
			$genesis->COM ('get_select_count');
					if ($genesis->{COMANS} > 0) {
							$genesis -> COM ('sel_resize',size=>"$valueOFcomp",corner_ctl=>'no');
			}
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('zoom_home');
			$genesis -> COM ('display_layer',name=>"$silkItem",display=>'no',number=>'1');
		
			######### POSITIVNI SYMBOLY
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
			$genesis -> COM ('display_layer',name=>"$silkItem",display=>'yes',number=>'1');
			$genesis -> COM ('work_layer',name=>"$silkItem");
			$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
			$genesis -> COM ('filter_area_strt');
			$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
			$genesis -> COM ('get_select_count');
					if ($genesis->{COMANS} > 0) {
							$genesis -> COM ('sel_resize',size=>"-${valueOFcomp}",corner_ctl=>'no');
			}
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('zoom_home');
			$genesis -> COM ('display_layer',name=>"$silkItem",display=>'no',number=>'1');

}
sub multiLayerMOVE {
		my $silkItem = shift;
		my $jobName = shift;
		
	 			my $layerCount = get_layer_count($jobName);
 	 			if ($layerCount > 2) {
   						$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/panel/$silkItem",data_type => 'LIMITS');
  							    my $spodniXbod = $genesis->{doinfo}{gLIMITSxmin};
								my $spodniYbod = $genesis->{doinfo}{gLIMITSymin};
	
												my $moveX = ($spodniXbod * (-1));
												my $moveY = ($spodniYbod * (-1));
												
   						$genesis->COM ('clear_layers');
   						$genesis->COM ('affected_layer',mode=>'all',affected=>'no');
						$genesis->COM ('display_layer',name=>"$silkItem",display=>'yes',number=>'1');
						$genesis->COM ('work_layer',name=>"$silkItem");
   						$genesis->COM ('sel_move',dx=>"$moveX",dy=>"$moveY");
					    $genesis->COM ('display_layer',name=>"$silkItem",display=>'no',number=>'1');
						$genesis->COM ('filter_reset',filter_name=>'popup');
				}
}
sub get_layer_count {
	my $jobName = shift;
    my $tmpCount = 0;
    
    
	    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
		    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    				for (my $count=0;$count<=$totalRows;$count++) {
							my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$count];
							my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
							my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
							my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
						if ($rowFilled ne "empty" && $rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground")) {
            					$tmpCount ++;
						}
					}
    return ($tmpCount);
}

sub get_gerber_jetPrint {
	my $silkItem = shift;
	my $jobName = shift;
	my $mirrorGerber = shift;
	my $angleRotate = 0;
	
	$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/panel/$silkItem",data_type => 'LIMITS');
		my $getRozmerY = $genesis->{doinfo}{gLIMITSymax} - $genesis->{doinfo}{gLIMITSymin};
	if ($getRozmerY > 480){
			$angleRotate = 90;
	}

	$genesis -> COM ('output_layer_reset');	
	$genesis -> COM ('output_layer_set',layer=>"$silkItem",angle=>"$angleRotate",mirror=>"$mirrorGerber",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'inch',gscl_file=>'');
	$genesis -> COM ('output',job=>"$jobName",step=>'panel',format=>'Gerber274x',dir_path=>"$cestaExportu",prefix=>"$jobName",suffix=>".ger",break_sr=>'yes',break_symbols=>'no',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
	$genesis -> COM ('disp_on');
	$genesis -> COM ('origin_on');
	
	
	
	#$genesis->COM ('delete_layer',layer=>"$silkItem");
}
#				open (REPORT,">>c:/Export/testJET");
#				print REPORT "$spodniXbod $spodniYbod\n";
#				close REPORT;