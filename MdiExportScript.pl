#!/usr/bin/perl-w
#################################
# do vyexportovaneho xml doplnit tloustku a kompenzace
# v
#################################
use Genesis;
use untilityScript;
use XML::Simple;
use Data::Dumper;
use sqlNoris;
use LoadLibrary;
use Time::localtime;

#local library
use Enums;
use FileHelper;
use GeneralHelper;
use DrillHelper;
use StackupHelper;
use StackupLayerHelper;
use GenesisHelper;
use AlignmentMDI_InCAM;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::TifFile::TifSigLayers';
use aliased 'Packages::Stackup::StackupOperation';
use aliased 'Packages::Technology::EtchOperation';


my $genesis = new Genesis;
my $cestaZdroje = 'r:/MDI';
my $cestaExportGerber = 'r:/PCB/mdi';


my @dpsINproduc = get_veVyrobe(); 


my $countJOB = @dpsINproduc;
foreach my $jobName (@dpsINproduc) {
				$jobName = lc$jobName;
				#print "$countJOB = $jobName\n";
						if(getValueNoris ($jobName,'typ_desky') eq "Vicevrstvy" or getValueNoris ($jobName,'typ_desky') eq "Oboustranny" or getValueNoris ($jobName,'typ_desky') eq "Jednostranny"){
												my $existGerbFile = check_gerber_exist($jobName);
												if ($existGerbFile == 0) {	# kdyz neexistuje gerberfile - tak se vytvori
														#if(_CheckGenesisInCAM($jobName)) { # vrati 1 kdyz je deska v InCAMu
																	$genesis -> COM ('check_inout',ent_type=>'job',job=>"$jobName",mode=>'test');
																	my @stav = split /\s/, $genesis->{COMANS};
																	if ($stav[0] eq 'no') {
																			make_layer_genesis($jobName);
																	}
														#}
												}
						}
		$countJOB--;
}

$genesis->COM('close_toolkit');



sub make_layer_genesis{
	my $jobName = shift;
	
			$katalog = XMLin("$ENV{'GENESIS_DIR'}/windows/e$ENV{'GENESIS_VER'}/all/perl/template.xml",ForceArray => 1, KeepRoot => 1);
			
			
				$genesis -> INFO (entity_type =>"job",entity_path=>"$jobName",data_type=>"EXISTS");
    				if ($genesis->{doinfo}{gEXISTS} eq "no") { 
    					$genesis -> VOF;
    					
        				my $archiveDir = getPath("$jobName");
						if (-e "$archiveDir/$jobName.tgz") {
					 				$genesis->COM('import_job',db=>'incam',path=>"$archiveDir/$jobName.tgz",name=>"$jobName",analyze_surfaces=>'no');
						}
        				$genesis -> VON;
        			}
						$genesis -> VOF;
						$genesis-> COM ('open_job',job=>"$jobName");
						my $stat2 = $genesis->{STATUS};
						$genesis -> VON;
						unless ($stat2) {
								$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/panel",data_type=>'exists');
										if ($genesis->{doinfo}{gEXISTS} eq "yes") {
	    			  		
	    			  								$genesis -> COM ('set_step',name=>'panel');
                           					
					  	   							my $layerCount = get_layer_count($jobName);
					  	   							my @innerList = get_inner_layers($jobName);
					  	   							my @maskList = GenesisHelper->GetLayerList($jobName, 'mask');
					  	   							
					  	   							my @plugList = ();
					  	   							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/plgc",data_type=>'exists');
															if ($genesis->{doinfo}{gEXISTS} eq "yes") {
																push (@plugList, 'plgc');
															}
					  	   							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/plgs",data_type=>'exists');
															if ($genesis->{doinfo}{gEXISTS} eq "yes") {
																push (@plugList, 'plgs');
															}
					  	   							
													my @goldList = ();
					  	   							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/goldc",data_type=>'exists');
															if ($genesis->{doinfo}{gEXISTS} eq "yes") {
																push (@goldList, 'goldc');
															}
					  	   							$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/golds",data_type=>'exists');
															if ($genesis->{doinfo}{gEXISTS} eq "yes") {
																push (@goldList, 'golds');
															}

					  	   							
					  	   							my @outerList = ();
					  	   							if (getValueNoris ($jobName,'typ_desky') eq "Jednostranny") {
					  	   											@outerList = qw (c);
					  	   							}else{
					  	   											@outerList = qw (c s);
									  	   			}
									  	   			
					  	   							if ($layerCount > 2) {
					  	   									foreach my $layer (@outerList) {
					  	   											removeALLoutFR($jobName, "$layer");
					  	   											copyFRtoLayer($jobName, "$layer");
					  	   											(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   											my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   											export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   									}
					  	   									foreach my $layer (@innerList) {
					  	   											removeALLoutPROF("$layer");
					  	   											(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   											my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   											export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   									}
					  	   									if (scalar @plugList > 0) {
					  	   											foreach my $layer (@plugList) {
					  	   													removeALLoutFR($jobName, "$layer");
					  	   													copyFRtoLayer($jobName, "$layer");
					  	   													(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   													my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   													export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   											}
					  	   									}
					if (scalar @goldList > 0) {
					  	   											foreach my $layer (@goldList) {
					  	   													removeALLoutFR($jobName, "$layer");
					  	   													copyFRtoLayer($jobName, "$layer");
					  	   													(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   													my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   													export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   											}
					  	   									}
					  	   									if (getValueNoris ($jobName,'construction_class') > 6) {
					  	   											foreach my $layer (@maskList) {
							  	   											removeALLoutFR($jobName, "$layer");
							  	   											copyFRtoLayer($jobName, "$layer");
							  	   											(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
							  	   											my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  			   											export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   											}
					  	   									}
					  	   							}else{
					  	   									foreach my $layer (@outerList) {
					  	   											removeALLoutPROF("$layer");
					  	   											(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   											my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   											export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   									}
					  	   									if (getValueNoris ($jobName,'construction_class') > 6) {
					  	   											foreach my $layer (@maskList) {
					  	   													removeALLoutPROF("$layer");
					  	   													(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   													my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   													export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   											}
					  	   									}
					  	   									if (scalar @plugList > 0) {
					  	   											foreach my $layer (@plugList) {
					  	   													removeALLoutPROF("$layer");
					  	   													(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   													my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   													export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   											}
					  	   									}
					if (scalar @goldList > 0) {
					  	   											foreach my $layer (@goldList) {
					  	   													removeALLoutPROF("$layer");
					  	   													(my $layerPath,my $nameGerber, my $layerPolarity, my $layerMirror) = get_gerber_mdi($jobName, "$layer");
					  	   													my $dcodeNum = AlignmentMDI_InCAM->AddalignmentMark($jobName, $layer, 'inch', $layerPath, 'cross_*');
					  	   													export_XML($jobName, $nameGerber,$dcodeNum, $layerPolarity, $layer, $layerMirror);
					  	   											}
					  	   									}
					  	   							}
					  	   							
					  	   				}
					  	   							#$genesis -> COM ('editor_page_close');
					  	   							
					  	   							$genesis -> COM('check_inout',job=>"$jobName",mode=>'in',ent_type=>'job');


					  	   							$genesis -> COM ('close_job',job=>"$jobName");
						   							$genesis -> COM ('close_form',job=>"$jobName");
						   							$genesis -> COM ('close_flow',job=>"$jobName");
						}
}
sub get_veVyrobe {
		my %tmpHash = ();
		my @tmpPole = ();

			$dbConnection = Win32::OLE->new("ADODB.Connection");
			$dbConnection->Open("DSN=dps;uid=genesis;pwd=genesis");

			my $sqlStatement =	"select distinct d.reference_subjektu from lcs.zakazky_dps_22_hlavicka z join lcs.desky_22 d on d.cislo_subjektu=z.deska left outer join lcs.vztahysubjektu vs on vs.cislo_vztahu = 23054 and vs.cislo_subjektu = z.cislo_subjektu where vs.cislo_vztaz_subjektu is null and z.stav='4'";
			my $sqlExecute = $dbConnection->Execute("$sqlStatement");

			$rec   = Win32::OLE->new("ADODB.Recordset");
			$rec->Open($sqlStatement, $dbConnection);

			until ($rec->EOF) {
  		 		my $value = $rec->Fields("reference_subjektu")->value;
  		 		
  		 		
				#open (REPORT,">>z:/sys/scripts/remote_script/report_selectu");
				#print REPORT "$value\n";
				#close REPORT;
  		 		
  		 		unless ($value =~ /-[Jj][\d]/) {
						my $job = substr($value,0, 6);
						$tmpHash{$job} = 1;
 		 		 }
  		 		
   	     		$rec->MoveNext();
			}
			$rec->Close();
			$dbConnection->Close();
			
			foreach my $item(keys %tmpHash) {
				push(@tmpPole, $item);
			}
			
	return (@tmpPole);
}

sub removeALLoutFR {
		my $jobName = shift;
		my $itemLayer = shift;
		my ($coverX, $coverY) = 0;
		if(_CheckGenesisInCAM($jobName)) {
				$coverX = -1; # -1 pro InCAM
				$coverY = -1;
		}else{
				$coverX = -3; # -3 pro Genesis
				$coverY = -3;
		}
			
			$genesis->COM ('display_layer',name=>"$itemLayer",display=>'yes',number=>'1');
			$genesis->COM ('work_layer',name=>"$itemLayer");
			
			$genesis->COM ('clip_area_strt');
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/panel/fr",data_type => 'LIMITS');
			$genesis->COM ('clip_area_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
			$genesis->COM ('clip_area_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$coverY");
			$genesis->COM ('clip_area_end',layers_mode=>'layer_name',layer=>"$itemLayer",area=>'manual',area_type=>'rectangle',inout=>'outside',contour_cut=>'yes',margin=>'0',feat_types=>'line\;pad\;surface\;arc\;text');
			
			$genesis->COM ('display_layer',name=>"$itemLayer",display=>'no',number=>'1');
			

			
			
}
sub removeALLoutPROF {
		my $itemLayer = shift;
		
		$genesis->COM ('display_layer',name=>"$itemLayer",display=>'yes',number=>'1');
		$genesis->COM ('work_layer',name=>"$itemLayer");
		
		$genesis->COM ('profile_to_rout', layer=>"$itemLayer", width=>'300');
		$genesis->COM ('clip_area_strt');
		$genesis->COM ('clip_area_end',layers_mode=>'layer_name',layer=>"$itemLayer",area=>'profile',area_type=>'rectangle',inout=>'outside',contour_cut=>'yes',margin=>'0',feat_types=>'line\;pad\;surface\;arc\;text');
		
		$genesis->COM ('display_layer',name=>"$itemLayer",display=>'no',number=>'1');
}

sub copyFRtoLayer {
		my $jobName = shift;
		my $itemLayer = shift;
		my ($coverX, $coverY) = 0;
		if(_CheckGenesisInCAM($jobName)) {
				$coverX = -1; # -1 pro InCAM
				$coverY = -1;
		}else{
				$coverX = -3; # -3 pro Genesis
				$coverY = -3;
		}
			
			$genesis->COM ('display_layer',name=>"$itemLayer",display=>'yes',number=>'1');
			$genesis->COM ('work_layer',name=>"$itemLayer");
			
			$genesis->COM ('add_polyline_strt');
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/panel/fr",data_type => 'LIMITS');
			
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmax}" + "$coverX",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymax}" + "$coverY");
			$genesis->COM ('add_polyline_xy',x=>"$genesis->{doinfo}{gLIMITSxmin}" - "$coverX",y=>"$genesis->{doinfo}{gLIMITSymin}" - "$coverY");
			$genesis->COM ('add_polyline_end',attributes=>'no',symbol=>'r100',polarity=>'positive');

			$genesis->COM ('display_layer',name=>"$itemLayer",display=>'no',number=>'1');
}

sub get_gerber_mdi {
	my $jobName = shift;
	my $mdiItem = shift;
	my $tmpSufix = 'mdi';
	my $tmpPolarita = 'empty';
	my $tmpMirrir = '0';
			
	#### hledani polarity
	unless ($mdiItem eq 'mc' or $mdiItem eq 'ms' or $mdiItem eq 'plgc' or $mdiItem eq 'plgs' or $mdiItem eq 'goldc' or $mdiItem eq 'golds') {	
			my $file   = TifSigLayers->new($jobName);
			my $fileExist = $file->TifFileExist();
			my %layers = $file->GetSignalLayers();

					if ($fileExist) {
							$tmpPolarita = $layers{$mdiItem}->{'polarity'};
							$tmpMirrir = $layers{$mdiItem}->{'mirror'};
					}else{
										if ($mdiItem eq 'c' or $mdiItem eq 's') {
												$findLayerOPFX = $mdiItem . 'v';
										}else{
												$findLayerOPFX = $mdiItem;
										}
										my $archivDir = getPath("$jobName");
										
										opendir ( DIRGERBER, "$archivDir/Zdroje");
												while( (my $oneItem = readdir(DIRGERBER))){
															if ($oneItem =~ /$jobName\@$findLayerOPFX/) {
																		open (OPFX,"$archivDir/Zdroje/$oneItem");
							  												while (<OPFX>) {
							  														if ($_ =~ /POLARITY = ([np][eo][gs][ai][t][i][v][e])/) {
							  																$tmpPolarita = $1;
							  														}elsif ($_ =~ /MIRRORX = yes/) {
							  																$tmpMirrir = 1;
								    													}elsif ($_ =~ /HDR_END/) {	# ukonceni hlavicky v OPFX souboru
								    															last;
								    													}
														          				}
																		close OPFX;
															}
												}
										closedir DIRGERBER;
					}
					
					if (getValueNoris ($jobName,'typ_desky') eq "Jednostranny") {
							if (getValueNoris ($jobName,'surface_finishing') eq 'G'){
									$tmpPolarita = 'positive';
							}else{
									$tmpPolarita = 'negative';
							}
					}
					log_file($jobName, $mdiItem, $fileExist, $tmpPolarita, $tmpMirrir);
	}else{
			$tmpPolarita = 'positive';
			if($mdiItem eq 'ms' or $mdiItem eq 'plgs' or $mdiItem eq 'golds') {
						$tmpMirrir = 1;
				}else{
						$tmpMirrir = 0;
			}
	}

	### konec hledani polarity	
	################################################################										

  			$genesis->COM ('clear_layers');
  					$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/${mdiItem}_$tmpSufix",data_type=>'exists');
  			    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
  			    			$genesis->COM ('delete_layer',layer=>"${mdiItem}_$tmpSufix");

  			    	}

  			$genesis -> COM ('flatten_layer',source_layer=>"$mdiItem",target_layer=>"${mdiItem}_$tmpSufix");
  			$genesis -> COM ('matrix_layer_type',job=>"$jobName",matrix=>'matrix',layer=>"${mdiItem}_$tmpSufix",type=>'silk_screen');
  			
  			$genesis -> COM ('display_layer',name=>"${mdiItem}_$tmpSufix",display=>'yes',number=>'1');
  			$genesis -> COM ('work_layer',name=>"${mdiItem}_$tmpSufix");
  			
  			{
  				my $valueReduction = 0;
  					if(getValueNoris ($jobName,'typ_desky') eq 'Vicevrstvy') {
  							my $pathToXML = get_xml_file($jobName);
							my %cuThickHash = get_cu_thick($pathToXML);
							my $constrClass = getValueNoris ($jobName,'construction_class');
							my $innerPosition = 0;
							
							unless ($mdiItem eq 'c' or $mdiItem eq 's') {
									$innerPosition = 1;
							}
							
									unless ($mdiItem eq 'mc' or $mdiItem eq 'ms' or $mdiItem eq 'plgc' or $mdiItem eq 'plgs') {	
												$valueReduction = EtchOperation->GetCompensation( $cuThickHash{$mdiItem}, $constrClass, $innerPosition);
									}
									
					}else{
							#print getValueNoris ($jobName,'material_tloustka');
							my $cuThick = getValueNoris ($jobName,'material_tloustka_medi');
							my $constrClass = getValueNoris ($jobName,'construction_class');
							
									unless ($mdiItem eq 'mc' or $mdiItem eq 'ms' or $mdiItem eq 'plgc' or $mdiItem eq 'plgs') {	
												$valueReduction = EtchOperation->GetCompensation( $cuThick, $constrClass, 0);
									}
					}
					
					unless ($mdiItem eq 'mc' or $mdiItem eq 'ms' or $mdiItem eq 'plgc' or $mdiItem eq 'plgs' or $mdiItem eq 'goldc' or $mdiItem eq 'golds') {	
								my $file   = TifSigLayers->new($jobName);
								my $fileExist = $file->TifFileExist();
								my %layers = $file->GetSignalLayers();
					
								if ($fileExist) {
										$valueReduction = $layers{$mdiItem}->{'comp'};
								}
					}
					if ($valueReduction) {
  							my $newItem = do_kompenzation ("${mdiItem}_$tmpSufix",$valueReduction);
  					}
  					
			}
  			$genesis -> COM ('output_layer_reset');	
  			$genesis -> COM ('output_layer_set',layer=>"${mdiItem}_$tmpSufix",angle=>'0',mirror=>"no",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'',step_scale=>'no');
  			$genesis -> COM ('output',job=>"$jobName",step=>'panel',format=>'Gerber274x',dir_path=>"$cestaExportGerber",prefix=>"$jobName",suffix=>".ger",break_sr=>'yes',break_symbols=>'no',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'0.01',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'inch',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
  			$genesis -> COM ('disp_on');
  			$genesis -> COM ('origin_on');
  			
  			#$genesis -> COM ('delete_layer',layer=>"${mdiItem}_$tmpSufix");
	return("$cestaExportGerber/$jobName${mdiItem}_$tmpSufix.ger", "$jobName${mdiItem}_$tmpSufix", "$tmpPolarita", "$tmpMirrir");
}
sub get_valueOFkomp {
		my $cuTMP = shift;
		my $returnKomp = 0;
		
					if($cuTMP == 5) {
							$returnKomp = 10;
				}elsif($cuTMP == 9) {
							$returnKomp = 9;
				}elsif($cuTMP == 18) {
							$returnKomp = 18;
				}elsif($cuTMP == 35) {
							$returnKomp = 35;
				}elsif($cuTMP == 70) {
							$returnKomp = 100;
				}elsif($cuTMP == 105) {
							$returnKomp = 160;
				}
		return($returnKomp);
}
sub get_inner_layers {
	my $jobName = shift;
	
	my @innerList;
    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    for ($count=0;$count<=$totalRows;$count++) {
		my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$count];
		my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
		my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
		my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
		my $rowSide = ${$genesis->{doinfo}{gROWside}}[$count];
		if ($rowFilled ne "empty" && $rowContext eq "board" && ($rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground") && $rowSide eq "inner") {
			push @innerList,$rowName;
		}
    }
    return (@innerList);
}
sub get_layer_count {
	my $jobName = shift;
    my $tmpCount = 0;
    
	    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
		    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    				for ($count=0;$count<=$totalRows;$count++) {
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

sub search_DCODE_layer {
		my $path = shift;
		my $tmpDcode = 0;

						open (DCODE,"$path");
    								while (<DCODE>) {
    										#if ($_ =~ /ADD(\d{2,4})C,5\.150/) {
    										if ($_ =~ /ADD(\d{2,4})C,0\.202756/) {
    													$tmpDcode = $1;
    													last;
    										}
  							          }
						close DCODE;
		return($tmpDcode);
}

sub do_kompenzation {
		my $layerActual = shift;
		my $kompLayer = shift;
		
		my $resizeOfPositiveFeature = $kompLayer * 1;
		my $resizeOfNegativeFeature = $kompLayer * (-1); 
		
		
		######### NEGATIVNI SYMBOLY
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
			$genesis -> COM ('display_layer',name=>"$layerActual",display=>'yes',number=>'1');
			$genesis -> COM ('work_layer',name=>"$layerActual");
			$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'negative');
			$genesis -> COM ('filter_area_strt');
			$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
			$genesis->COM ('get_select_count');
					if ($genesis->{COMANS} > 0) {
							$genesis -> COM ('sel_resize',size=>$resizeOfNegativeFeature,corner_ctl=>'no');
			}
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('zoom_home');
			$genesis -> COM ('display_layer',name=>"$layerActual",display=>'no',number=>'1');
		
			######### POSITIVNI SYMBOLY
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
			$genesis -> COM ('display_layer',name=>"$layerActual",display=>'yes',number=>'1');
			$genesis -> COM ('work_layer',name=>"$layerActual");
			$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
			$genesis -> COM ('filter_area_strt');
			$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
			$genesis -> COM ('get_select_count');
					if ($genesis->{COMANS} > 0) {
							$genesis -> COM ('sel_resize',size=>$resizeOfPositiveFeature,corner_ctl=>'no');
			}
			$genesis -> COM ('filter_reset',filter_name=>'popup');
			$genesis -> COM ('zoom_home');
			$genesis -> COM ('display_layer',name=>"$layerActual",display=>'no',number=>'1');
			#$genesis -> COM ('rename_layer',name=>"$layerActual",new_name=>"${layerActual}_${kompLayer}"); 
	return ("${layerActual}_${kompLayer}");
}

sub export_XML {
	my $jobName = shift;
	my $nameItem = shift;
	my $fiduc_layer = shift;
	my $polarity = shift;
	my $layerName = shift;
	my $mirror = shift; # muze byt hodnota 0!
	my $diameter;
	my ($lowerlimit,$upperlimit,$acceptance,$brightness,$power,$iterations,$upper,$lower);
	my $x_position;
	my $y_position; 
	
	  		if ($layerName eq 'c' or $layerName eq 's') {
	  				if (getValueNoris ($jobName,'tenting') eq 'A') {
  							$diameter = 2.87;
  							$brightness = 8;
  							$upperlimit = 0.08;
  							$lowerlimit = -0.08;
  							$acceptance = 70;
  							$x_position = 0.5;
  							$y_position = -1.0;
  							
  					}else{
  							if(sqlNoris->getValueNoris($jobName, 'flash') > 0) {
  										$diameter = 2.87;
  										$brightness = 8;
  										$upperlimit = 0.08;
  										$lowerlimit = -0.08;
  										$acceptance = 70;
  										$x_position = 0;
  										$y_position = 0;
  							}else{
  										$diameter = 3;
  										$brightness = 3;
  										$upperlimit = 0.06;
  										$lowerlimit = -0.06;
  										$acceptance = 70;
  										$x_position = 0;
  										$y_position = 0;
		  					}
  							
	  				}
	  		}elsif($layerName eq 'mc' or $layerName eq 'ms'){
	  									$power = 230;
	  			  						$diameter = 2.85;
  										$brightness = 3;
  										$upperlimit = 0.08;
  										$lowerlimit = -0.08;
  										$acceptance = 70;
  										$x_position = 0;
  										$y_position = 0;
	  			
  			}else{
  					$diameter = 3;
  					$brightness = 3;
  					$upperlimit = 0.04;
  					$lowerlimit = -0.04;
  					$acceptance = 70;
  					$x_position = 0.0;
  					$y_position = 0.0;
  			}
	
	
	$iterations = 3; 
	$upper = 0.02;
	$lower = -0.02;
	
	
	my $pocetPrirezu = getValueNoris($jobName, 'pocet_prirezu') + getValueNoris($jobName, 'prirezu_navic');
	
	$katalog->{job_params}->[0]->{job_name}->[0] = $nameItem;
	$katalog->{job_params}->[0]->{parts_total}->[0] = $pocetPrirezu;
	$katalog->{job_params}->[0]->{parts_remaining}->[0] = $pocetPrirezu;
	
    $katalog->{job_params}->[0]->{part_size}->[0]->{z} = StackupOperation->GetThickByLayer($jobName, $layerName);		#set thick
	$katalog->{job_params}->[0]->{image_size}->[0]->{x} = getValueNoris($jobName, 'x_size');		# rozmer prirezu X
	$katalog->{job_params}->[0]->{image_size}->[0]->{y} = getValueNoris($jobName, 'y_size');		# rozmer prirezu Y
	
	$katalog->{job_params}->[0]->{image_position}->[0]->{x} = $x_position;
	$katalog->{job_params}->[0]->{image_position}->[0]->{y} = $y_position;
	
	if ($mirror) {
			if (getValueNoris($jobName, 'y_size') > 520) {
						$katalog->{job_params}->[0]->{rotation}->[0] = 3;
			}else{
						$katalog->{job_params}->[0]->{rotation}->[0] = 0;
			}
	}else{
			if (getValueNoris($jobName, 'y_size') > 520) {
						$katalog->{job_params}->[0]->{rotation}->[0] = 3;
			}else{
						$katalog->{job_params}->[0]->{rotation}->[0] = 2;
			}
	}
	
	$katalog->{job_params}->[0]->{mirror}->[0]->{x} = 0;										# mirror
	$katalog->{job_params}->[0]->{mirror}->[0]->{y} = $mirror;										# mirror
	
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{diameter_x}->[0]->{iterations} = $iterations;
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{diameter_x}->[0]->{lowch} = $upper;
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{diameter_x}->[0]->{uppch} = $lower;
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{diameter_x}->[0]->{value} = $diameter;
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{diameter_x}->[0]->{upptol} = $upperlimit;
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{diameter_x}->[0]->{lowtol} = $lowerlimit;
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{image_recognition_acceptance}->[0] = $acceptance;
	$katalog->{job_params}->[0]->{image_object_default}->[0]->{image_object}->[0]->{image_acquisition_brightness}->[0] = $brightness;
	
	
	
	if ($polarity eq 'negative') {
			$katalog->{job_params}->[0]->{polarity}->[0] = 0;
	}else{
			$katalog->{job_params}->[0]->{polarity}->[0] = 1;
	}
	if ($power){
			$katalog->{job_params}->[0]->{exposure_energy}->[0] = $power;
	}
	$katalog->{job_params}->[0]->{fiducial_ID_global}->[0] = $fiduc_layer;

	
		XML::Simple::XMLout($katalog, 
    		KeepRoot   => 1,
    		AttrIndent => 0,
    		XMLDecl    => '<?xml version="1.0" encoding="utf-8"?>',
    		OutputFile => "$cestaZdroje/$nameItem.xml",
		)
}

sub get_xml_file {
		my $job = shift;
		my $multiPath = 'r:/PCB/pcb/VV_slozeni';
		my $xmlFileVV = 0;
		my $jobLower = lc($job);
		my $jobUpper = uc($job);
		
					   	opendir ( DIRXML, $multiPath);
							while((my $oneItem = readdir(DIRXML))){
									if ($oneItem =~ /^$jobLower/ or $oneItem =~ /^$jobUpper/) {
										 $xmlFileVV = $oneItem;
										 last;
									}
							}
						closedir DIRXML;
			return ("$multiPath/$xmlFileVV");
}


sub get_cu_thick {
		my $path = shift;
		my %hashCopper = ();
		my %hashCopperReturn = ();
			$katalogStackup = XMLin("$path",ForceArray => 0, KeepRoot => 0, KeyAttr => {item => 'element'});
			#print Dumper $katalogStackup;

			my $countOfelem = @{$katalogStackup->{element}};

			my $pocetVrstev = 0;
			for ($i=0; $i<$countOfelem; $i++){
					if ($katalogStackup->{element}->[$i]->{type} eq 'Copper') {
							$pocetVrstev++;
							$hashCopper{"v$pocetVrstev"} = id_convert($katalogStackup->{element}->[$i]->{id});
    				}
			}
			foreach my $item (sort keys %hashCopper) {
					if ($item eq 'v1') {
						$hashCopperReturn{'c'} = $hashCopper{$item};
				}elsif($item eq "v$pocetVrstev") {
						$hashCopperReturn{'s'} = $hashCopper{$item};
				}else{	
						$hashCopperReturn{$item} = $hashCopper{$item};
				}
			}
		return(%hashCopperReturn);
}
sub id_convert {
	my $id = shift;
	my $copper = 0;
					if($id == 1) {
							$copper = 5;
				}elsif($id == 2) {
							$copper = 9;
				}elsif($id == 4) {
							$copper = 18;
				}elsif($id == 5) {
							$copper = 35;
				}elsif($id == 8) {
							$copper = 70;
				}elsif($id == 9) {
							$copper = 105;
				}
	return($copper);
}
sub check_gerber_exist {
			my $job = shift;
			my $existGerFile = 0;
			
				   	opendir ( DIRGERBER, $cestaZdroje);
						while( (my $oneItem = readdir(DIRGERBER))){
								if ($oneItem =~ /$job/) {
										if ($oneItem =~ /gbr$/) {
												$existGerFile = 1;
												last;
										}
										if ($oneItem =~ /ger$/) {
												$existGerFile = 1;
												last;
										}
								}
						}
					closedir DIRGERBER;
					
					opendir ( DIRGERBER, $cestaExportGerber);
						while( (my $oneItem = readdir(DIRGERBER))){
								if ($oneItem =~ /$job/) {
										if ($oneItem =~ /ger$/) {
												$existGerFile = 1;
												last;
										}
								}
						}
					closedir DIRGERBER;
	return($existGerFile);
}


sub _CheckGenesisInCAM {
			my $jobName = shift;
			my $madeInCAM = 0;
			my $archivDir = getPath("$jobName");
			
			open (AREA,"$archivDir/$jobName.nif");
            		while (<AREA>) {
            				if ($_ =~ /\[============================ SEKCE DPS ============================\]/) {
                            		$madeInCAM = 1;
                            		last;
                			}
            		}	
            close AREA;
            
      return($madeInCAM);
}

sub log_file {
	my $logInfo = shift;
	my $layer = shift;
	my $difExist = shift;
	my $polaritaLog = shift;
	my $mirrLog = shift;
	
	my $dateString = get_current_date();
	my $timeString = get_current_time();
	my $logFile = "$ENV{'GENESIS_DIR'}/sys/scripts/remote_script/report/$dateString.mdi";
	
			open (LOGFILE,">>$logFile");
			print LOGFILE "TIME:$timeString job>$logInfo ; Layer>$layer ; DifExist>$difExist ; Polarity>$polaritaLog ; Mirror>$mirrLog  \n";
			close (LOGFILE);
	return();
}
sub get_current_date {
	my $datumHodnota = sprintf "%04.f-%02.f-%02.f",(localtime->year() + 1900),(localtime->mon() + 1),localtime->mday();
	return ($datumHodnota);
}
sub get_current_time {
	my $dateString = sprintf "%02.f:%02.f",localtime->hour(),localtime->min();
	return ($dateString);
}


#log_file($jobName, $mdiItem, $fileExist, $tmpPolarita, $tmpMirrir);
#				open (REPORT,">>c:/Export/test");
#				print REPORT "$layerPath\n";
#				close REPORT;














