#-------------------------------------------------------------------------------------------#
# Description: Vyhleda OLEC znacky v Genesisu a jejich souradnice zapise do Gerber file pod nový DCODE.
# Author:RVI
#-------------------------------------------------------------------------------------------#


 
 


package Packages::Mdi::ExportFiles::FiducMark;

use Genesis;
 
use LoadLibrary;

#local library
 
 
 
my $FIDMARK_MM = "5.16120000";
my $FIDMARK_INCH = "0.202815";


sub AddalignmentMark {
		my $self   = shift;
		my $genesis = shift;
		my $jobName = shift;
		my $layerName = shift;
		my $units = shift;
		my $pathGerber = shift;
		my $searchMark = shift;
		my $stepName = 'panel';
		my @arrFiducialPosition = ();
		my $valueDcode = 0;
		
		$self->_GetCoorFiducial($genesis, $layerName,$units, $jobName, $stepName, $searchMark);

			push(@arrFiducialPosition,'G54D' . ($self->_GetHighestDcode("$pathGerber") + 1) . '*');
			for ( my $i = 1 ; $i <=4 ; $i++ ) {
					push(@arrFiducialPosition,  sprintf("X%010d", sprintf "%3.0f",$featCoor->{"fid$i"}->{'x'} * 1000000) . 
												  sprintf("Y%010d", sprintf "%3.0f",$featCoor->{"fid$i"}->{'y'} * 1000000) . 
												  'D03*');
			};
		
			open (NEWFILE,">>${pathGerber}_temp");
			open (SOURCEFILE,"$pathGerber");
					my $lastDcode = '%ADD' . $self->_GetHighestDcode("$pathGerber");
					my $existFiduc = 0;
			while (<SOURCEFILE>) {
					if ($_ =~ /G75*/ and $existFiduc == 0) {
							print NEWFILE "$_";
							foreach my $line (@arrFiducialPosition) {
										print NEWFILE "$line\n";
							};
							$existFiduc = 1;
					}elsif ($_ =~ /$lastDcode/) {
										print NEWFILE "$_";
									    if($units eq 'mm') {
												$valueDcode = $FIDMARK_MM;
 										}else{
												$valueDcode = $FIDMARK_INCH;
 										};
										my $newDcode = '%ADD' . ($self->_GetHighestDcode("$pathGerber") + 1) . 'C,' . $valueDcode . '*%';
										print NEWFILE "$newDcode\n";
					}else{
							print NEWFILE "$_";
					};
					
				
		
			}
			close SOURCEFILE;
			close NEWFILE;
			unlink "$pathGerber";
			rename("${pathGerber}_temp","$pathGerber");
			
	return($self->_GetHighestDcode("$pathGerber"));
}
sub _GetCoorFiducial {
		my $self = shift;
		my $genesis = shift;
		my $layer = shift;
		my $units = shift;
		my $jobName = shift;
		my $stepName = shift;
		my $searchMark = shift;
		#$searchMark = 'cross_outer*';
		#$searchMark = 'mask_fiduc*';
 		
 				$genesis->COM ('clear_layers');					
 				$genesis->COM ('display_layer',name=>"$layer",display=>'yes',number=>'1');
 				$genesis->COM ('work_layer',name=>"$layer");
 				
				$genesis->COM ('filter_reset',filter_name=>"popup");		
				$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>"$searchMark");
				$genesis->COM ('filter_area_strt');
				$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
				$genesis->COM ('get_select_count');
				unless ($genesis->{COMANS}) {
						$genesis->COM ('filter_reset',filter_name=>"popup");
						$genesis->COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');		
						$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>"$searchMark",min_int_val=>'999',max_int_val=>'999');
						$genesis->COM ('filter_area_strt');
						$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
						$genesis->COM ('get_select_count');
				}
			
 				if ($genesis->{COMANS}) {
 						my $infoFile = $genesis->INFO('units'=>"$units",'entity_type'=>'layer','entity_path'=>"$jobName/$stepName/$layer",'data_type'=>'FEATURES',options=>'select',parse=>'no');
 						open (INFOFILE,$infoFile);
 						
 								my $count = 1;
 								while(<INFOFILE>) {
 										if ($_ =~ /^#P/) {
 												my @points = split /\s+/;
# 												if (GenesisHelper->countSignalLayers($jobName) > 2) {   							# for multilayer
# 														unless(GenesisHelper->GetLayerSide($jobName,$stepName,$layer) eq 'inner'){	# for innerlayer
#																my ($coorXfr, $coorYfr) = _GetCoorRoutFR("$units", $jobName, $stepName);	
#																				# recalculate value with rout layer FR
#																		$points[1] = $points[1] - $coorXfr;
#																		$points[2] = $points[2] - $coorYfr;
#														}
#												};
 												$featCoor->{"fid$count"} = {
 																		'x' => $points[1],
 																		'y' => $points[2],
 																		};
 											$count++;
 										}
 								}
 				}
 				close INFOFILE;
 				unlink $infoFile;
 				$genesis->COM ('display_layer',name=>"$layer",display=>'no',number=>'1');
 				$genesis->COM ('filter_reset',filter_name=>"popup");
	return(); 
}
 

sub _GetHighestDcode {
		my $layerPath = shift;
		my $highestDcode;
			open (AREAFILE,"$layerPath");
        		   while (<AREAFILE>) {
		            	if ($_ =~ /$\%ADD(\d{1,4})/) {
        			    		$highestDcode = $1;
            			}
					}
			close AREAFILE;
	return($highestDcode);
}
1;