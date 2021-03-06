#!/usr/bin/perl-w
#################################
use Time::localtime;
use File::Copy 'cp';
use untilityScript;

use Genesis;
my $genesis = new Genesis;
use Tk;

unless ($ENV{JOB}) {
	$jobName = shift;
	$cestaZdroje = shift;
} else {
	$jobName = "$ENV{JOB}";
	$cestaZdroje = "c:/Export";
}
my $logo_way = "$ENV{'GENESIS_DIR'}/sys/scripts/gatema/error.gif"; 
my $obysDesky = 0;
my $dateString = sprintf "%02.f:%02.f:%02.f",localtime->hour(),localtime->min(),localtime->sec();
my $datumHodnota = sprintf "%02.f.%02.f.%04.f",localtime->mday(),(localtime->mon() + 1),(localtime->year() + 1900);
my $myStepMap = 'o+1';
my $cestaExportu = 'r:/Kooperace_drillMap/';

$genesis->COM('get_user_name');
my $userName = "$genesis->{COMANS}";

	  mkdir("$cestaZdroje/${jobName}_data");
$cestaZdroje = "$cestaZdroje/${jobName}_data";

my $pripona = '.ger';

&infoLayers;

$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/mpanel",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$myStep = 'mpanel';
    	}else{
    		$myStep = 'o+1';
    	}

$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/f",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
			#$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>"$myStep",iconic=>'no');
			$genesis->COM ('set_step',name=>"$myStep");
			$genesis->AUX('set_group', group => $genesis->{COMANS});
    		$genesis->COM('units',type=>'mm');
    		 $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/f",data_type=>'FEAT_HIST',options =>'break_sr');
									$padFeatF = $genesis->{doinfo}{gFEAT_HISTpad};
										if ($padFeatF > 0) {
    											$genesis -> COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'f',type=>'drill'); 
    												if ($myStep eq 'mpanel') {
    													$genesis->COM('flatten_layer',source_layer=>'f',target_layer=>'first_mill_npth');
    													&calculateRout;
    													$genesis -> COM('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'first_mill_npth',type=>'rout'); 
    													$genesis -> COM('compensate_layer',source_layer=>'first_mill_npth',dest_layer=>'mill_npth',dest_layer_type=>'document');
													}else{
														$genesis->COM('copy_layer',source_job=>"$jobName",source_step=>"$myStep",source_layer=>'f',dest=>'layer_name',dest_layer=>'first_mill_npth',mode=>'replace',invert=>'no');
														$genesis->COM('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'first_mill_npth',type=>'drill');
														&calculateRout;
														$genesis -> COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'first_mill_npth',type=>'rout'); 
    													$genesis -> COM ('compensate_layer',source_layer=>'first_mill_npth',dest_layer=>'mill_npth',dest_layer_type=>'document');
    												}
    											$genesis -> COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'f',type=>'rout'); 
										}else{
    													$genesis -> COM ('compensate_layer',source_layer=>'f',dest_layer=>'mill',dest_layer_type=>'document');
										}
    		$genesis -> COM ('editor_page_close');
    	}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/r",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		#$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>"$myStep",iconic=>'no');
		#	$genesis->AUX('set_group', group => $genesis->{COMANS});
		$genesis->COM ('set_step',name=>"$myStep");
    		$genesis->COM('units',type=>'mm');
    		$genesis -> COM ('compensate_layer',source_layer=>'r',dest_layer=>'pt_mill',dest_layer_type=>'document');
    		$genesis -> COM ('editor_page_close');
    	}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/score",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$genesis -> COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>'score',type=>'rout');
    		$genesis -> COM ('matrix_layer_context',job=>"$jobName",matrix=>'matrix',layer=>'score',context=>'board');
    	}
    	if ($myStep eq 'mpanel') {
    		    		#$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>"$myStep",iconic=>'no');
					#	$genesis->AUX('set_group', group => $genesis->{COMANS});
							$genesis->COM ('set_step',name=>"$myStep");
							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/m",data_type=>'exists');
							    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							    		$genesis->COM('flatten_layer',source_layer=>'m',target_layer=>'pth');
							    		&calculateDrill;
						    		}
							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/d",data_type=>'exists');
							    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							    		$genesis->COM('flatten_layer',source_layer=>'d',target_layer=>'npth');
							    	}
			    		$genesis -> COM ('editor_page_close');
		}else{
    		    		#$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>"$myStep",iconic=>'no');
				#		$genesis->AUX('set_group', group => $genesis->{COMANS});
						$genesis->COM ('set_step',name=>"$myStep");
							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/m",data_type=>'exists');
							    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							    		$genesis->COM('copy_layer',source_job=>"$jobName",source_step=>"$myStep",source_layer=>'m',dest=>'layer_name',dest_layer=>'pth',mode=>'replace',invert=>'no');
										&calculateDrill;
							 		}
							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/d",data_type=>'exists');
							    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
							    		$genesis->COM('copy_layer',source_job=>"$jobName",source_step=>"$myStep",source_layer=>'d',dest=>'layer_name',dest_layer=>'npth',mode=>'replace',invert=>'no');
							    	}
			    		$genesis -> COM ('editor_page_close');
		}
$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    for ($count=0;$count<=$totalRows;$count++) {
	my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$count];
	my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
	my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
	my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
	
		unless (($rowName eq "sa") || ($rowName eq "sb") || ($rowName eq "v1") || ($rowName eq "fr") || ($rowName eq "fk")  || ($rowName eq "f")  || ($rowName eq "r") || ($rowName eq "m") || ($rowName eq "d")) {
			if ($rowType ne "document" && $rowFilled ne "empty" && $rowContext eq "board") {
    		       push(@exportLayer,$rowName);
		    }
		}
		if ($rowFilled ne "empty" && $rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground")) {
            $layerCount ++;
			}
	#	if ($rowName eq "o") {
	#		push(@exportLayer,'o');
	#			$obysDesky = 1;
	#	}
		if ($rowName eq "mill") {
			push(@exportLayer,'mill');
		}
		if ($rowName eq "mill_npth") {
			push(@exportLayer,'mill_npth');
		}
		if ($rowName eq "pt_mill") {
			push(@exportLayer,'pt_mill');
		}
		if ($rowName eq "pth") {
			push(@exportLayer,'pth');
		}
		if ($rowName eq "npth") {
			push(@exportLayer,'npth');
		}
	}
#print "@exportLayer\n";
	if (-e "$cestaZdroje/readme.txt") {
			unlink("$cestaZdroje/readme.txt");
	}
&readme_file;
	if ($layerCount > 2) {
				&copyPdf;
	}
foreach my $layerExport (@exportLayer) {
	$genesis -> COM ('output_layer_reset');	
	$genesis -> COM ('output_layer_set',layer=>"$layerExport",angle=>'0',mirror=>'no',x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
	$genesis -> COM ('output',job=>"$jobName",step=>"$myStep",format=>'Gerber274x',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>"$pripona",break_sr=>'yes',break_symbols=>'yes',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
}

$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/mill_npth",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$genesis->COM('delete_layer',layer=>"mill_npth");
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/pt_mill",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$genesis->COM('delete_layer',layer=>"pt_mill");
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/pth",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$genesis->COM('delete_layer',layer=>"pth");
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/mill",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$genesis->COM('delete_layer',layer=>"mill");
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/pth_map",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$genesis->COM('print',title=>"",layer_name=>'pth_map',mirrored_layers=>"",draw_profile=>'yes',drawing_per_layer=>'yes',dest=>'pdf_file',num_copies=>'1',dest_fname=>"$cestaZdroje/${jobName}-pth_map.pdf",paper_size=>'A4',scale_to=>'0',nx=>'1',ny=>'1',orient=>'none',paper_orient=>'portrait',paper_width=>'0',paper_height=>'0',auto_tray=>'no',top_margin=>'5',bottom_margin=>'5',left_margin=>'5',right_margin=>'5',x_spacing=>'0',y_spacing=>'0');
    		$genesis->COM('delete_layer',layer=>"pth_map");
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStep/first_mill_npth",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
    		$genesis->COM('delete_layer',layer=>"first_mill_npth");
		}
&drill_map_create;

			#$statusLabel = sprintf "Koperace vyexportovana...";
			#$status->update;

sub readme_file {
	open (README,">>$cestaZdroje/readme.txt");
		print README "Information to the pcb number $jobName\n";
		print README "pcb:			$layerCount layers\n";
		print README "export time:		$datumHodnota at $dateString\n";
		print README "created:		$userName\n";
		print README "Gatema s.r.o.:		www.gatema.cz\n";
		print README "------------------------------------------\n";
	foreach my $layerExport (@exportLayer) {
		if ($layerExport eq 'gc') {
			print README "gc			graphite component\n";
		}elsif ($layerExport eq 'lc') {
			print README "lc			peelable mask component\n";
		}elsif ($layerExport eq 'pc') {
			print README "pc			print component\n";
		}elsif($layerExport eq 'mc') {
			print README "mc			mask component\n";
		}elsif($layerExport eq 'c') {
			print README "c			side component\n";
		}elsif($layerExport eq 'v2') {
			print README "v2,v3...vX		inner layers\n";
		}elsif($layerExport eq 's') {
			print README "s			side solder\n";
		}elsif($layerExport eq 'ms') {
			print README "ms			mask solder\n";
		}elsif($layerExport eq 'ps') {
			print README "ps			print solder\n";
		}elsif($layerExport eq 'ls') {
			print README "ls			peelable mask solder\n";
		}elsif($layerExport eq 'gs') {
			print README "gs			graphite solder\n";
		}elsif($layerExport eq 'pth') {
			print README "pth			plated through holes\n";
		}elsif($layerExport eq 'npth') {
			print README "npth			non plated through holes\n";
		}elsif($layerExport eq 'mill_npth') {
			print README "mill_npth		non plated through holes + mill\n";
		}elsif($layerExport eq 'mill') {
			print README "mill			non plated mill\n";
		}elsif($layerExport eq 'score') {
			print README "score			V-scoring\n";
		}elsif($layerExport eq 'pt_mill') {
			print README "pt_mill			plated mill\n";
		}elsif($layerExport =~ /s([1-4][c,s])([1-9])([1-9])/) {
   			print README "$layerExport			blind VIA drilled from layer $2 to layer $3\n";
   		} 
   	}
   		if ($layerCount > 2) {
   			print README "${jobName}-cm.pdf		stack-up in format PDF\n";
   		}
   		   	print README "\n\n";
   		if ($layerCount > 2) {
   		   	print README "c-v2-v3-..-s		order of layers\n\n";
   		}
   			print README "ALL DIAMETERS IN DATA ARE FINISH DIAMETERS!!!";

#final_delivery	border of panel
#drawing		plan with special information
	close README;
}

sub copyPdf {
	my $pathTmp = getPath($jobName);
	$cestaPdf  = "$pathTmp/pdf";

cp("$cestaPdf/${jobName}-cm.pdf","$cestaZdroje/${jobName}-cm.pdf");
}

sub infoLayers {
	$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    for ($counts=0;$counts<=$totalRows;$counts++) {
		my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$counts];
		my $rowName = ${$genesis->{doinfo}{gROWname}}[$counts];
		my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$counts];
		my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$counts];

			if ($rowFilled ne "empty" && $rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground")) {
	            $layerXXVV ++;
			}
	}
}

sub calculateDrill {
	
								    		$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStep/pth",data_type => 'NUM_TOOL');
													$pocetTool = $genesis->{doinfo}{gNUM_TOOL}; 
											$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStep/pth",data_type => 'TOOL_USER');
													$tooluser = $genesis->{doinfo}{gTOOL_USER}; 
											$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStep/pth",data_type => 'TOOL');
															@numVrtaku = @{$genesis->{doinfo}{gTOOLnum}};
															@finishSize = @{$genesis->{doinfo}{gTOOLfinish_size}};
															@type = @{$genesis->{doinfo}{gTOOLtype}};
															@type2 = @{$genesis->{doinfo}{gTOOLtype2}};
															@min_tools = @{$genesis->{doinfo}{gTOOLmin_tol}};
															@max_tools = @{$genesis->{doinfo}{gTOOLmax_tol}};
															
															$genesis -> COM('tools_tab_reset');
															$pocetTool -= 1;
																for($countDrill = 0;$countDrill <= $pocetTool;$countDrill++) {
																		if ($type[$countDrill] eq "plated") {
																				$type[$countDrill] = "plate";
																		}elsif ($type[$countDrill] eq "non_plated") {
																				$type[$countDrill] = "nplate";
																		}
																		if ($tooluser eq 'vrtane') {
																				if ($layerXXVV > 1) {
																					if ($type[$countDrill] eq "plate") {
																						$finishSize[$countDrill] = ($finishSize[$countDrill] - 100);
																					}
																				}
																		}
																		$min_tools[$countDrill] = $min_tools[$countDrill] + 80;
																		$max_tools[$countDrill] = $max_tools[$countDrill] + 80;
																	$drill_bit = 0;
																	$drill_bit = sprintf "%1.3f",($finishSize[$countDrill]/1000);
																		if ($finishSize[$countDrill] == 0) {
																				$main = MainWindow->new();
																				$topmain = $main->Frame(-width=>10, -height=>20)->pack(-side=>'top');
																				$botmain = $main->Frame(-width=>10, -height=>20)->pack(-side=>'bottom');

																				$topmain->Frame(-width=>10, -height=>20)->pack(-side=>'right');	
																				$logomain = $topmain->Frame(-width=>10, -height=>20)->pack(-side=>'left');
																				$radek = $main->Message(-justify=>'center', -aspect=>5000, -text=>"Zavazny problem, v tabulce vrtaku, ve sloupci Finish Size je nulova hodnota,oprav to,a pak exportuj znovu!");
																				$radek->pack();
																				$radek->configure(-font=>'times 12 bold');
																			 	$logo_frame = $logomain->Frame(-width=>50, -height=>50)->pack(-side=>'left');
																				$error_logo = $logo_frame->Photo(-file=>"$logo_way");
																				$logo_frame->Label(-image=>$error_logo)->pack();
																				$button = $main ->Button(-text=>'konec',-command=>\&konec)->pack(-padx=>5,-pady=>5);
																				$main->waitWindow;
																		}
																	$genesis -> COM('tools_tab_add',num=>"$numVrtaku[$countDrill]",type=>"$type[$countDrill]",type2=>"$type2[$countDrill]",min_tol=>"$min_tools[$countDrill]",max_tol=>"$max_tools[$countDrill]",bit=>"$drill_bit",finish_size=>"$finishSize[$countDrill]",drill_size=>"$finishSize[$countDrill]");
																	$genesis -> COM('tools_set',layer=>'pth',thickness=>'0',user_params=>'');
																	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStepMap/pth_pth",data_type=>'exists');
							    													if ($genesis->{doinfo}{gEXISTS} eq "yes") {
																								$genesis->COM ('delete_layer',layer=>'pth_map');
																					}
																	$genesis -> COM('cre_drills_map',layer=>'pth',map_layer=>'pth_map',preserve_attr=>'yes',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150',sr=>'no',slots=>'no',columns=>'Tool\;Count\;Type\;+Tol\;-Tol',notype=>'plt',table_pos=>'right',table_align=>'bottom');
																   		$genesis->COM ('display_layer',name=>'pth_map',display=>'yes',number=>'1');
																		$genesis->COM ('work_layer',name=>'pth_map');			
																			$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',text=>'*Drill*');
																			$genesis -> COM ('filter_area_strt');
																			$genesis -> COM ('filter_area_end',layer=>'pth_map',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
																			$genesis -> COM ('sel_change_txt',text=>'Finish',x_size=>'3.048',y_size=>'3.048',w_factor=>'0.75',polarity=>'positive',mirror=>'no',fontname=>'standard');
																			$genesis -> COM ('filter_reset',filter_name=>'popup');
																			$genesis-> COM ('display_layer',name=>'pth_map',display=>'no',number=>'1');
																}
}

sub calculateRout {
	
								    		$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStep/first_mill_npth",data_type => 'NUM_TOOL');
													$pocetToolF = $genesis->{doinfo}{gNUM_TOOL}; 
											$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStep/first_mill_npth",data_type => 'TOOL');
															@numVrtakuF = @{$genesis->{doinfo}{gTOOLnum}};
															@finishSizeF = @{$genesis->{doinfo}{gTOOLfinish_size}};
															@drillSizeF = @{$genesis->{doinfo}{gTOOLdrill_size}};
															@typeF = @{$genesis->{doinfo}{gTOOLtype}};
															@type2F = @{$genesis->{doinfo}{gTOOLtype2}};
															@min_toolsF = @{$genesis->{doinfo}{gTOOLmin_tol}};
															@max_toolsF = @{$genesis->{doinfo}{gTOOLmax_tol}};
															@shapeF = @{$genesis->{doinfo}{gTOOLshape}};
															
															$genesis -> COM('tools_tab_reset');
															$pocetToolF -= 1;
																for($countDrillF = 0;$countDrillF <= $pocetToolF;$countDrillF++) {
																		if ($typeF[$countDrillF] eq "plated") {
																				$typeF[$countDrillF] = "plate";
																		}elsif ($typeF[$countDrillF] eq "non_plated") {
																				$typeF[$countDrillF] = "nplate";
																		}
																			if ($shapeF[$countDrillF] eq 'hole') {
																					$min_toolsF[$countDrillF] = $min_toolsF[$countDrillF] + 70;
																					$max_toolsF[$countDrillF] = $max_toolsF[$countDrillF] + 70;
																						$drill_bitF = 0;
																						if ($finishSizeF[$countDrillF] == 0) {
																							$drill_bitF = sprintf "%1.3f",($drillSizeF[$countDrillF]/1000);
																							$drill_sizeF = sprintf "%1.3f",($drillSizeF[$countDrillF]);
																						}else{
																							$drill_bitF = sprintf "%1.3f",($finishSizeF[$countDrillF]/1000);
																							$drill_sizeF = sprintf "%1.3f",($finishSizeF[$countDrillF]);
																						}
																						$genesis -> COM('tools_tab_add',num=>"$numVrtakuF[$countDrillF]",type=>"$typeF[$countDrillF]",type2=>"$type2F[$countDrillF]",min_tol=>"$min_toolsF[$countDrillF]",max_tol=>"$max_toolsF[$countDrillF]",bit=>"$drill_bitF",finish_size=>"$finishSizeF[$countDrillF]",drill_size=>"$drill_sizeF");
																						$genesis -> COM('tools_set',layer=>'first_mill_npth',thickness=>'0',user_params=>'');
																			}
																}
																
	
}


sub drill_map_create {
			#$genesis -> COM ('open_entity',job=>"$jobName",type=>'step',name=>"$myStepMap",iconic=>'no');
			#						$genesis->AUX('set_group', group => $genesis->{COMANS});
									$genesis->COM ('set_step',name=>"$myStepMap");
										$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStepMap/pth",data_type=>'exists');
							    				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
														$genesis->COM ('delete_layer',layer=>'pth');
												}
														$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$myStepMap/m",data_type=>'exists');
															if ($genesis->{doinfo}{gEXISTS} eq "yes") {
																	$genesis->COM('copy_layer',source_job=>"$jobName",source_step=>"$myStepMap",source_layer=>'m',dest=>'layer_name',dest_layer=>'pth',mode=>'replace',invert=>'no');
																	&calculateDrillmap;
																	&export_pdf;
															}
															
}

sub calculateDrillmap {
									$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$myStepMap",data_type => 'PROF_LIMITS');
										$jobX = sprintf "%3.1f",((($genesis->{doinfo}{gPROF_LIMITSxmax}) / 2) -15);
										$jobY = sprintf "%3.1f",($genesis->{doinfo}{gPROF_LIMITSymax} + 2);
								    		$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStepMap/pth",data_type => 'NUM_TOOL');
													$pocetTool = $genesis->{doinfo}{gNUM_TOOL}; 
											$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStepMap/pth",data_type => 'TOOL_USER');
													$tooluser = $genesis->{doinfo}{gTOOL_USER}; 
											$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$myStepMap/pth",data_type => 'TOOL');
															@numVrtaku = @{$genesis->{doinfo}{gTOOLnum}};
															@finishSize = @{$genesis->{doinfo}{gTOOLfinish_size}};
															@type = @{$genesis->{doinfo}{gTOOLtype}};
															@type2 = @{$genesis->{doinfo}{gTOOLtype2}};
															@min_tools = @{$genesis->{doinfo}{gTOOLmin_tol}};
															@max_tools = @{$genesis->{doinfo}{gTOOLmax_tol}};
															
															$genesis -> COM('tools_tab_reset');
															$pocetTool -= 1;
																for($countDrill = 0;$countDrill <= $pocetTool;$countDrill++) {
																		if ($type[$countDrill] eq "plated") {
																				$type[$countDrill] = "plate";
																		}elsif ($type[$countDrill] eq "non_plated") {
																				$type[$countDrill] = "nplate";
																		}
																		if ($tooluser eq 'vrtane') {
																				if ($layerXXVV > 1) {
																					if ($type[$countDrill] eq "plate") {
																						$finishSize[$countDrill] = ($finishSize[$countDrill] - 100);
																					}
																				}
																		}
																		$min_tools[$countDrill] = $min_tools[$countDrill] + 80;
																		$max_tools[$countDrill] = $max_tools[$countDrill] + 80;
																	$drill_bit = 0;
																	$drill_bit = sprintf "%1.3f",($finishSize[$countDrill]/1000);
																	$genesis -> COM('tools_tab_add',num=>"$numVrtaku[$countDrill]",type=>"$type[$countDrill]",type2=>"$type2[$countDrill]",min_tol=>"$min_tools[$countDrill]",max_tol=>"$max_tools[$countDrill]",bit=>"$drill_bit",finish_size=>"$finishSize[$countDrill]",drill_size=>"$finishSize[$countDrill]");
																	$genesis -> COM('tools_set',layer=>'pth',thickness=>'0',user_params=>'');
																	$genesis -> COM('cre_drills_map',layer=>'pth',map_layer=>'pth_map',preserve_attr=>'yes',draw_origin=>'no',define_via_type=>'yes',units=>'mm',mark_dim=>'1270',mark_line_width=>'150',sr=>'no',slots=>'no',columns=>'Tool\;Count\;Type\;+Tol\;-Tol',notype=>'plt',table_pos=>'right',table_align=>'bottom');
																   		
  																		$genesis->COM('clear_layers');                                    
                																$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
                
																		$genesis->COM ('display_layer',name=>'pth_map',display=>'yes',number=>'1');
																		$genesis->COM ('work_layer',name=>'pth_map');
																		$addText = "\u$jobName";
																		$genesis->COM ('add_text',attributes=>'no',type=>'string',x=>"$jobX",y=>"$jobY",text=>"$addText",x_size=>5.08,y_size=>5.08,w_factor=>2,polarity=>'positive',angle=>0,mirror=>'no',fontname=>'standard',ver=>'1');			
																			$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',text=>'*Drill*');
																			$genesis -> COM ('filter_area_strt');
																			$genesis -> COM ('filter_area_end',layer=>'pth_map',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
																			$genesis -> COM ('sel_change_txt',text=>'Finish',x_size=>'3.048',y_size=>'3.048',w_factor=>'0.75',polarity=>'positive',mirror=>'no',fontname=>'standard');
																			$genesis -> COM ('filter_reset',filter_name=>'popup');
																			$genesis-> COM ('display_layer',name=>'pth_map',display=>'no',number=>'1');
																}
}

sub export_pdf {
	$genesis -> COM('print',title=>'',layer_name=>'pth_map',mirrored_layers=>'',draw_profile=>'yes',drawing_per_layer=>'yes',label_layers=>'no',dest=>'pdf_file',num_copies=>'1',dest_fname=>"$cestaExportu/${jobName}-drillmap.pdf",paper_size=>'A4',scale_to=>'0',nx=>'1',ny=>'1',orient=>'none',paper_orient=>'portrait',paper_width=>'0',paper_height=>'0',auto_tray=>'yes',top_margin=>'12.7',bottom_margin=>'12.7',left_margin=>'12.7',right_margin=>'12.7',x_spacing=>'0',y_spacing=>'0',color1=>'990000',color2=>'9900',color3=>'99',color4=>'990099',color5=>'999900',color6=>'9999',color7=>'0');
$genesis -> COM ('editor_page_close');
}



sub konec {
	exit;
	break;
}