#!/usr/bin/perl
#####################################################
#   Script Name         :   score.pl	             #
#   Version             :   1.00                    #
#   Last Modification   :   Initial Creation        #
#####################################################
use Genesis;

my $genesis = new Genesis;

$minimumDraz = 25; 

unless ($ENV{JOB}) {
	$jobName = shift;
	$stepName = shift;
} else {
	$jobName = "$ENV{JOB}";
	$stepName = "panel";
}
&odmazani_pro_premnozeni; #odmazani starych dlouhych znacek

   $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$stepName/v2",data_type=>'exists');
		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
						$odskokX = 28;
						$odskokY = 18;
						
						my $infoFile = $genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/panel/m",'data_type'=>'FEATURES',parse=>'no');
						open (INFOFILE,$infoFile);
								while(<INFOFILE>) {
										if ($_ =~ /\.orig_features=olec_origin/) {
												my @infoLine = split /\s/,$_;
														$drOtvorX = $infoLine[1];
														$drOtvorY = $infoLine[2];
										}
								}
						close (INFOFILE);
		} else { 
				$odskokX = 18;
				$odskokY = 18;
						my $infoFile = $genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/panel/m",'data_type'=>'FEATURES',parse=>'no');
						open (INFOFILE,$infoFile);
								while(<INFOFILE>) {
										if ($_ =~ /\.orig_features=olec_origin/) {
												my @infoLine = split /\s/,$_;
														$drOtvorX = $infoLine[1];
														$drOtvorY = $infoLine[2];
										}
								}
						close (INFOFILE);
		}
my $scoreLayerName = "score";
		if ($jobName && $stepName) {
				$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$stepName",data_type => 'PROF_LIMITS');
				my $hLineStartX = $genesis->{doinfo}{gPROF_LIMITSxmin};
				my $hLineEndX = $genesis->{doinfo}{gPROF_LIMITSxmax};
				my $vLineStartY = $genesis->{doinfo}{gPROF_LIMITSymin};
				my $vLineEndY = $genesis->{doinfo}{gPROF_LIMITSymax};
				$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$stepName",data_type => 'ACTIVE_AREA');
				my $hLineLeftX = $genesis->{doinfo}{gACTIVE_AREAxmin} - 1;
				my $hLineRightX = $genesis->{doinfo}{gACTIVE_AREAxmax} + 1;
				my $vLineBotY  = $genesis->{doinfo}{gACTIVE_AREAymin} - 1;
				my $vLineTopY = $genesis->{doinfo}{gACTIVE_AREAymax} + 1;
				
				   $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$stepName/v2",data_type=>'exists');
					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
						$hLineEndX = $hLineEndX - 5;
						$hLineStartX = $hLineStartX + 5;
						$vLineStartY = $vLineStartY + 20;
						$vLineEndY = $vLineEndY - 20;
					}
			
				 $genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$stepName",iconic=>'no');
				 $genesis->AUX('set_group', group => $genesis->{COMANS});
				 $genesis->COM('units',type=>'mm');
				 $genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
			     $genesis->COM('filter_reset',filter_name=>"popup");
				 $genesis->COM('clear_layers');
			
				$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$stepName/$scoreLayerName",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					$genesis->COM('flatten_layer',source_layer=>"$scoreLayerName",target_layer=>"__score_flat__");
					$genesis->COM('affected_layer',name=>"__score_flat__",mode=>'single',affected=>'yes');
					$genesis->COM('filter_reset',filter_name=>"popup");
			     $genesis->COM('filter_set',filter_name=>'popup',update_popup=>'no',feat_types=>"line");
			     $genesis->COM('filter_area_strt');
			     $genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'yes',lines_only=>'no',ovals_only=>'no',min_len=>0,max_len=>0,min_angle=>0,max_angle=>0);
			     $genesis->COM('get_select_count');
			     if ($genesis->{COMANS}) {
						my $featureFile = $genesis->INFO(units=>'mm',entity_type=>"layer",entity_path=>"$jobName/$stepName/__score_flat__",data_type=>'FEATURES',options=>"select",parse=>"no");
						open (FEATUREFILE,"$featureFile");
						while (<FEATUREFILE>) {
							if ($_ =~ /^#L/) {
								my @fields = split /\s+/;
								my $startX = $fields[1];
								my $startY = $fields[2];
								my $endX = $fields[3];
								my $endY = $fields[4];
								if ($startX == $endX) {
									push @unsortedVerticalLineList,$startX;
								} else {
									push @unsortedHorizontalLineList,$startY;
								}
							}
						}
						close FEATUREFILE;
						unlink "$featureFile";
			my $lastCoord = "";
			foreach my $currentCoord (sort @unsortedVerticalLineList) {
				if ($currentCoord != $lastCoord) {
					push @verticalLineList,$currentCoord;
					$lastCoord = $currentCoord;
				}
			}
			$lastCoord = "";
			foreach my $currentCoord (sort @unsortedHorizontalLineList) {
				if ($currentCoord != $lastCoord) {
					push @horizontalLineList,$currentCoord;
					$lastCoord = $currentCoord;
				}
			}
        }
		$genesis->COM('affected_layer',name=>"__score_flat__",mode=>'single',affected=>'no');
		$genesis->COM('affected_filter',filter=>"(type=signal|power_ground|mixed|solder_mask&context=board&side=top|bottom)");
		$genesis->COM('cur_atr_set',attribute=>".rout_flag",int=>"999");
		foreach my $xCoord (@verticalLineList) {
			$genesis->COM('add_line',attributes=>'yes',xs=>"$xCoord",ys=>"$vLineStartY",xe=>"$xCoord",ye=>"$vLineBotY",symbol=>"r300",polarity=>'positive');
			$genesis->COM('add_line',attributes=>'yes',xs=>"$xCoord",ys=>"$vLineTopY",xe=>"$xCoord",ye=>"$vLineEndY",symbol=>"r300",polarity=>'positive');
		}
		foreach my $yCoord (@horizontalLineList) {
			$genesis->COM('add_line',attributes=>'yes',xs=>"$hLineStartX",ys=>"$yCoord",xe=>"$hLineLeftX",ye=>"$yCoord",symbol=>"r300",polarity=>'positive');
			$genesis->COM('add_line',attributes=>'yes',xs=>"$hLineRightX",ys=>"$yCoord",xe=>"$hLineEndX",ye=>"$yCoord",symbol=>"r300",polarity=>'positive');
		}
	    $genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
	}
	
	@vertcalDrazkovaci = @verticalLineList;
	@horizontalDrazkovaci = @horizontalLineList;
	@verticalUprava = @verticalLineList;
	@verticalLineList = sort ({$a<=>$b} @verticalUprava);
	$testRozmeruX1 = @verticalLineList[1] - @verticalLineList[0];
	$testRozmeruX2 = @verticalLineList[2] - @verticalLineList[1];
	
			if (($testRozmeruX1 > $minimumDraz) and ($testRozmeruX2 > $minimumDraz)) {
					pop (@verticalLineList);
			}

	$i = 0;
			foreach my $xCoord (@verticalLineList) {
					   $celkempolix = @verticalLineList;
					   
					   if ($i ne $celkempolix-1) {
					   	   $rozdelx = ((@verticalLineList[$i+1] - @verticalLineList[$i])/2);
					   }
					   if (($testRozmeruX1 < $minimumDraz) and ($testRozmeruX2 < $minimumDraz)) {
					   	   $xxx = $xCoord;
					   }
					   	else {   
					    $xxx = ($xCoord + $rozdelx);
					    }
					    
					    $i=$i+1;
					    $endX = ($vLineEndY - $odskokX);	
			}
	
  				@horizontalUprava = @horizontalLineList;
  				@horizontalLineList = sort ({$a<=>$b} @horizontalUprava);
  				$testRozmeruY1 = @horizontalLineList[1] - @horizontalLineList[0];
  				$testRozmeruY2 = @horizontalLineList[2] - @horizontalLineList[1];
	
			if (($testRozmeruY1 > $minimumDraz) and ($testRozmeruY2 > $minimumDraz)) {
						pop (@horizontalLineList);
			}
			
			
			$t = 0;
			foreach my $yCoord (@horizontalLineList) {
					   $celkempoliy = @horizontalLineList;
					   
					   if ($t ne $celkempoliy-1) {
					   	   $rozdely = ((@horizontalLineList[$t+1] - @horizontalLineList[$t])/2);
					   }
					   if (($testRozmeruY1 < $minimumDraz) and ($testRozmeruY2 < $minimumDraz)) {
					   		$yyy = $yCoord;
					   }
					   else {
					    $yyy = ($yCoord + $rozdely);
					   }
					   
					    $t=$t+1;
					    $endY = ($hLineEndX - $odskokY);
		  }
        	
#  						  $genesis -> COM ('filter_reset',filter_name=>'popup');
#  							$genesis->COM ('affected_layer',affected=>'no',mode=>'all');
#  							$genesis -> COM ('display_layer',name=>'m',display=>'yes',number=>'1');
#  							$genesis -> COM ('work_layer',name=>'m');
#  							$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/panel",data_type => 'PROF_LIMITS');
#  						  		$Ymax = (($genesis->{doinfo}{gPROF_LIMITSymax})-$drOtvorY);
#  						  		$Xmax = (($genesis->{doinfo}{gPROF_LIMITSxmax})-$drOtvorX);
#  						
#  						  	$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$drOtvorY",symbol=>'r3000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  							$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$Ymax",symbol=>'r3000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  							$genesis->COM('add_pad',attributes=>'no',x=>"$Xmax",y=>"$drOtvorY",symbol=>'r3000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  							
#  							####
#  							#negativ do motivu
#  							$genesis -> COM ('display_layer',name=>'m',display=>'no',number=>'1');
#  							$genesis->COM('filter_reset',filter_name=>'popup');
#  							$genesis->COM('affected_layer',affected=>'no',mode=>'all');
#  							$genesis->COM('affected_layer',name=>'c',mode=>'single',affected=>'yes');
#  							
#  							$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$stepName/s",data_type=>'exists');
#  							if ($genesis->{doinfo}{gEXISTS} eq "yes") {
#  										$genesis->COM('affected_layer',name=>'s',mode=>'single',affected=>'yes'); 
#  							}
#  						
#  						    $genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$drOtvorY",symbol=>'r5000',polarity=>'negative',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  							$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$Ymax",symbol=>'r5000',polarity=>'negative',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  							$genesis->COM('add_pad',attributes=>'no',x=>"$Xmax",y=>"$drOtvorY",symbol=>'r5000',polarity=>'negative',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  							$genesis -> COM ('filter_reset',filter_name=>'popup');
#  							$genesis->COM ('affected_layer',affected=>'no',mode=>'all');
#  							
#  							#Negativ do masky
#  							$genesis->COM('filter_reset',filter_name=>'popup');
#  							$genesis->COM('affected_layer',affected=>'no',mode=>'all');
#  							        $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/mc",data_type=>'exists');
#  									if ($genesis->{doinfo}{gEXISTS} eq "yes") {
#  									  				$genesis->COM('affected_layer',name=>'mc',mode=>'single',affected=>'yes');
#  									  				
#  									  				$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$drOtvorY",symbol=>'r4000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  									  				$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$Ymax",symbol=>'r4000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  									  				$genesis->COM('add_pad',attributes=>'no',x=>"$Xmax",y=>"$drOtvorY",symbol=>'r4000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  									  				$genesis->COM('filter_reset',filter_name=>'popup');
#  									  				$genesis->COM('affected_layer',affected=>'no',mode=>'all');
#  									}
#  									$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/ms",data_type=>'exists');
#  									if ($genesis->{doinfo}{gEXISTS} eq "yes") {
#  												$genesis->COM('affected_layer',name=>'ms',mode=>'single',affected=>'yes'); 
#  								
#	  						  						$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$drOtvorY",symbol=>'r4000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  													$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$Ymax",symbol=>'r4000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  													$genesis->COM('add_pad',attributes=>'no',x=>"$Xmax",y=>"$drOtvorY",symbol=>'r4000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
#  													$genesis->COM('filter_reset',filter_name=>'popup');
#  													$genesis->COM('affected_layer',affected=>'no',mode=>'all');
#  									}
  				}

    	$genesis->COM('delete_layer',layer=>"__score_flat__");

    	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/panel/draz_prog",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "no") {
    						$genesis->COM('create_layer',layer=>'draz_prog',context=>'misc',type=>'drill',polarity=>'positive',ins_layer=>'');
        		}
    					$genesis -> COM ('filter_reset',filter_name=>'popup');
						$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
						$genesis -> COM ('display_layer',name=>'draz_prog',display=>'yes',number=>'1');
						$genesis -> COM ('work_layer',name=>'draz_prog');
						
						
        	foreach my $xDrProg (@vertcalDrazkovaci) {
        			$genesis->COM('add_pad',attributes=>'no',x=>"$xDrProg",y=>"$drOtvorY",symbol=>'r1100',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
			}
        	foreach my $yDrProg (@horizontalDrazkovaci) {	
       				$genesis->COM('add_pad',attributes=>'no',x=>"$drOtvorX",y=>"$yDrProg",symbol=>'r1000',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
        	}
    		
    		$genesis->COM('editor_page_close');

sub odmazani_pro_premnozeni {
	$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$stepName/c",data_type=>'exists');
			if ($genesis->{doinfo}{gEXISTS} eq "yes") {
						$genesis->COM ('affected_layer',name=>'c',mode=>'single',affected=>'yes');
			}
		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$stepName/s",data_type=>'exists');
			if ($genesis->{doinfo}{gEXISTS} eq "yes") {			
						$genesis->COM ('affected_layer',name=>'s',mode=>'single',affected=>'yes');
			}	
$genesis->COM ('filter_reset',filter_name=>'popup');		
$genesis->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.rout_flag',min_int_val=>'999',max_int_val=>'999');
$genesis->COM ('filter_area_strt');
$genesis->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');

		$genesis->COM ('get_select_count');
			if ($genesis->{COMANS} >= 1) {
					$genesis->COM ('sel_delete');
			}
$genesis->COM ('filter_reset',filter_name=>'popup');
$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
$genesis->COM ('zoom_home');
}