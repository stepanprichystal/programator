#!/usr/bin/perl-w
#################################
#Sript name: plotting.pl
#Verze     : 1.00
#Use       : nahrada kresleni
#Made      : RV
	# POZADAVKY
	# nastaveni negativu
	# automaticky import gerberu
	# kontrola citelnosti
	#
#################################
use Genesis;

my $jobName = "$ENV{JOB}";
my $genesis = new Genesis;



	&checkMatrix;
	&kompenzace;
	&controlBig;
	&rotBig;
	&rowArange;
    &singleWork;
    
    
sub checkMatrix {
	    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    			my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
					    for ($count=0;$count<=$totalRows;$count++) {
									my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$count];
								       $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
									my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
									my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
			  								 if ($rowName) {
											   	   push(@alllayer,$rowName);
											   }
						}
}
sub singleWork {
	foreach my $rowNameNew (@alllayer) {
    	$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/1/$rowNameNew",data_type => 'LIMITS');
        	 $myDpsXsize = $genesis->{doinfo}{gLIMITSxmin};
	         $myDpsYsize = $genesis->{doinfo}{gLIMITSymin};
	         $myDpsXsizeMAX = $genesis->{doinfo}{gLIMITSxmax};
    	     $myDpsYsizeMAX = $genesis->{doinfo}{gLIMITSymax};
	          if ($movoSwitch == 0) {
	       			  $myDpsXsize = (($myDpsXsize * (-1)) + 0.2) ;
	       	 		  $myDpsYsize = (($myDpsYsize * (-1)) + 0.2);
	       	 		  $movoSwitch = 1;
	       	  }else{
	       	  	      $myDpsXsize = ((($myDpsXsizeMAX * (-1)) + 609.6) - 0.2);
	       	 		  $myDpsYsize = ((($myDpsYsize 	  * (-1)) +   0.0) + 0.2);
	       	 		  $movoSwitch = 0;
	       	  }
	        
	       	$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
			$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'yes',number=>'1');
			$genesis -> COM ('work_layer',name=>"$rowNameNew");
	       	$genesis -> COM ('sel_move',dx=>"$myDpsXsize",dy=>"$myDpsYsize");
	       	$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'no',number=>'1');
	}
}
sub controlBig {
	foreach my $rowNameNew (@alllayer) {
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/1/$rowNameNew",data_type => 'LIMITS');
			        $myDpsXsize = sprintf "%3.3f",($genesis->{doinfo}{gLIMITSxmax} - $genesis->{doinfo}{gLIMITSxmin});
		    	    $myDpsYsize = sprintf "%3.3f",($genesis->{doinfo}{gLIMITSymax} - $genesis->{doinfo}{gLIMITSymin});
		    	    
		    	  if ($myDpsYsize > 500) {
		    	    	$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
						$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'yes',number=>'1');
						$genesis -> COM ('work_layer',name=>"$rowNameNew");
						$genesis -> PAUSE ('Smaz ramecek');
	       				$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'no',number=>'1');
	       			}
	}
	
}
sub kompenzace {
	foreach my $rowNameNew (@alllayer) {
			if ($rowNameNew =~ /(\d{1,3})um/) {
						$enlarge = $1;
						$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
						$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'yes',number=>'1');
						$genesis -> COM ('work_layer',name=>"$rowNameNew");
						$genesis -> PAUSE ("$rowNameNew $enlarge");
						$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',polarity=>'positive');
						$genesis -> COM ('filter_area_strt');
						$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
						$genesis -> COM ('sel_resize',size=>"$enlarge",corner_ctl=>'no');
	       				$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'no',number=>'1');
	       				$genesis -> COM ('filter_reset',filter_name=>'popup');
	       	}
	}
}

sub rotBig {
	foreach my $rowNameNew (@alllayer) {
		$dimXlayer = shift;
		$genesis -> INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/1/$rowNameNew",data_type => 'LIMITS');
        	  $dimYlayer = (($genesis->{doinfo}{gLIMITSymax}) - ($genesis->{doinfo}{gLIMITSymin}));
        	 
        	 if ($dimYlayer > 507.8) {
        	 		        $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
							$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'yes',number=>'1');
							$genesis -> COM ('work_layer',name=>"$rowNameNew");
							$genesis -> COM ('sel_transform',mode=>'anchor',oper=>'rotate',duplicate=>'no',x_anchor=>'0',y_anchor=>'0',angle=>'90',x_scale=>'1',y_scale=>'1',x_offset=>'0',y_offset=>'0');
					    	$genesis -> INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/1/$rowNameNew",data_type => 'LIMITS');
					        	 my $spodniXbod = $genesis->{doinfo}{gLIMITSxmin};
					        	 my $spodniYbod = $genesis->{doinfo}{gLIMITSymin};
	         
												$moveX = ($spodniXbod * (-1));
												$moveY = ($spodniYbod * (-1));

				
	       		$genesis -> COM ('sel_move',dx=>"$moveX",dy=>"$moveY");
		       	$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'no',number=>'1');
		       	$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
		     }
	}
}

sub rowArange {
	$maxRow = @alllayer;
	$maxRow = $maxRow + 1;
	$countRow = 1;
	foreach my $rowNameNew (@alllayer) {
			
	       	$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
			$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'yes',number=>'1');
			$genesis -> COM ('work_layer',name=>"$rowNameNew");
			
			  $genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/1/$rowNameNew",data_type => 'LIMITS');
		        	 $myDpsXsize = (($genesis->{doinfo}{gLIMITSxmax}) - ($genesis->{doinfo}{gLIMITSxmin}));
	    		     $myDpsYsize = (($genesis->{doinfo}{gLIMITSymax}) - ($genesis->{doinfo}{gLIMITSymin}));
			if ($myDpsXsize > 304.5) {
					$genesis -> COM ('matrix_add_row',job=>"$jobName",matrix=>'matrix');
					$genesis -> COM ('matrix_move_row',job=>"$jobName",matrix=>'matrix',row=>"$countRow",ins_row=>"$maxRow");
					$genesis -> COM ('matrix_refresh',job=>"$jobName",matrix=>'matrix');
					$genesis -> COM ('matrix_page_close',job=>"$jobName",matrix=>'matrix');
					#$maxRow ++;
					$countRow = $countRow - 1;
			}
	       	$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'no',number=>'1');
	       	$countRow ++;
	}
}