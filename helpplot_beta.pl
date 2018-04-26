#!/usr/bin/perl
#use strict;
#use warnings;
use Genesis;

my $genesis = new Genesis;
my $jobName = "1";
my $stepName = "$ENV{STEP}";
my $pocitadlo_global = 0;
my $pocitadlo = 1;
my @novepole =(); 
my %hash_pcnpsn=();
my %hash_pcnppsnp=();
my %hash_pcpnpspn=();
my %hash_cnsn=();

#=====RADIM=====================
&checkMatrix;
&kompenzace;
#=====RADIM=====================
&vyhledani_pcn_psn;

&vyhledani_cn_sn;

&vyhledani_pcnp_psnp;

&vyhledani_pcpn_pspn;

&positiv_na_negativ;

&positiv_na_negativ_cnsn;

&negativ_na_positiv;

&positiv_mirror_negativ;

#=====RADIM=====================
#	&checkMatrix;
#  &kompenzace;	
	&controlBig;
	&rotBig;
#	&rowArange;
  &singleWork;
#=====RADIM=====================

#=====LUKAS=====================
&vrstvy_pole;

&tisk_nove_pole;

&copy_nova_vrstva;

sub vyhledani_pcn_psn {

      $genesis ->INFO(entity_type => 'matrix',
                    entity_path => "$jobName/matrix",
                      data_type => 'ROW');
      my @ROWname = @{$genesis->{doinfo}{gROWname}};
      
      foreach my $pcn_psn (@ROWname) {
    #regularni vyraz hleda pcn nebo psn a pridava jmena vrstev do tabulky $hash_pcnpsn  
          if ($pcn_psn =~ /(pcn|psn)[^p]/) {
          $hash_pcnpsn {"$pcn_psn"}=$pocitadlo;        
          }              
      ++$pocitadlo;    
      }
$pocitadlo = 1;      
}

sub vyhledani_pcnp_psnp {

      $genesis ->INFO(entity_type => 'matrix',
                    entity_path => "$jobName/matrix",
                      data_type => 'ROW');
      my @ROWname = @{$genesis->{doinfo}{gROWname}};
      
      foreach my $pcnp_psnp (@ROWname) {
      #regularni vyraz hleda pcnp nebo psnp a pridava jmena vrstev do tabulky $hash_pcnppsnp  
          if ($pcnp_psnp =~ /(pcnp|psnp)/) {
          $hash_pcnppsnp {"$pcnp_psnp"}=$pocitadlo;        
          }              
      ++$pocitadlo;    
      }
$pocitadlo = 1;      
}

sub vyhledani_pcpn_pspn {

      $genesis ->INFO(entity_type => 'matrix',
                    entity_path => "$jobName/matrix",
                      data_type => 'ROW');
      my @ROWname = @{$genesis->{doinfo}{gROWname}};
      
      foreach my $pcpn_pspn (@ROWname) {
      #regularni vyraz hleda pcnp nebo psnp a pridava jmena vrstev do tabulky $hash_pcpnpspn  
          if ($pcpn_pspn =~ /(pcpn|pspn)/) {
          $hash_pcpnpspn {"$pcpn_pspn"}=$pocitadlo;        
          }              
      ++$pocitadlo;    
      }
$pocitadlo = 1;
}

sub vyhledani_cn_sn {

      $genesis ->INFO(entity_type => 'matrix',
                    entity_path => "$jobName/matrix",
                      data_type => 'ROW');
      my @ROWname = @{$genesis->{doinfo}{gROWname}};
      
      foreach my $cn_sn (@ROWname) {
    #regularni vyraz hleda cn nebo sn a pridava jmena vrstev do tabulky $hash_cnsn  
          if ($cn_sn =~ /[^p](cn|sn)[^p]/) {
          $hash_cnsn {"$cn_sn"}=$pocitadlo;        
          }              
      ++$pocitadlo;    
      }
$pocitadlo = 1;      
}

sub positiv_na_negativ {

        #prohledani klicu v tabulce %hash_pcnpsn
        foreach my $pcnpsn_name (keys %hash_pcnpsn) {
              print "$pcnpsn_name\n";
   
          #rozmer vrstvy
          $genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$pcnpsn_name",data_type => 'LIMITS');
    	    my $myDpsXsize = $genesis->{doinfo}{gLIMITSxmin};
          my $myDpsYsize = $genesis->{doinfo}{gLIMITSymin};
          my $myDpsXsizeMAX = $genesis->{doinfo}{gLIMITSxmax};
	        my $myDpsYsizeMAX = $genesis->{doinfo}{gLIMITSymax};
	     
	        print "Rozmer X je ".$myDpsXsize."\n";
          print "Rozmer Y je ".$myDpsYsize."\n";
          print "Rozmer X je ".$myDpsXsizeMAX."\n";
          print "Rozmer Y je ".$myDpsYsizeMAX."\n";
       
          my $minusmyDpsXsize = ($myDpsXsize-1);
          my $minusmyDpsYsize = ($myDpsYsize-1);
          my $plusmyDpsXsizeMAX = ($myDpsXsizeMAX+1);
          my $plusmyDpsYsizeMAX = ($myDpsYsizeMAX+1);

          $genesis-> COM ("matrix_add_row",job=>"$jobName",matrix=>"matrix");
          $genesis-> COM ("matrix_refresh",job=>"$jobName",matrix=>"matrix");
          $genesis->INFO(units => 'mm', entity_type => 'matrix',entity_path => "$jobName/matrix",data_type => 'NUM_ROWS');
          my $row = $genesis->{doinfo}{gNUM_ROWS};
          $genesis-> COM ("matrix_add_layer",job=>"$jobName",matrix=>"matrix",layer=>"docasna",row=>"$row",context=>"misc",type=>"signal",polarity=>"positive");

          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
					$genesis -> COM ('display_layer',name=>"docasna",display=>'yes',number=>'1');
					$genesis -> COM ('work_layer',name=>"docasna");      	
	       
    #prida surface 
          $genesis->COM ('add_surf_strt',surf_type=>'feature');
      		$genesis->COM ('add_surf_poly_strt',x=>"$minusmyDpsXsize",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_seg',x=>"$minusmyDpsXsize",y=>"$plusmyDpsYsizeMAX");
      		$genesis->COM ('add_surf_poly_seg',x=>"$plusmyDpsXsizeMAX",y=>"$plusmyDpsYsizeMAX");
      		$genesis->COM ('add_surf_poly_seg',x=>"$plusmyDpsXsizeMAX",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_seg',x=>"$minusmyDpsXsize",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_end');
      		$genesis->COM ('add_surf_end',attributes=>'no',polarity=>'positive');

          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
          $genesis -> COM ('display_layer',name=>"$pcnpsn_name",display=>'yes',number=>'1');
          $genesis -> COM ('work_layer',name=>"$pcnpsn_name");   
          						
          $genesis-> COM ("sel_move_other",target_layer=>"docasna",invert=>"yes",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
          $genesis -> COM ('display_layer',name=>"docasna",display=>'yes',number=>'1');
          $genesis -> COM ('work_layer',name=>"docasna");
          $genesis-> COM ("sel_move_other",target_layer=>"$pcnpsn_name",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
          $genesis -> COM ('display_layer',name=>"docasna",display=>'no',number=>'1');
          		
          
          $genesis-> COM ("matrix_delete_row",job=>"$jobName",matrix=>"matrix",row=>"$row");	
    
        }          
}

sub positiv_na_negativ_cnsn {

        #prohledani klicu v tabulce %hash_cnsn
        foreach my $cnsn_name (keys %hash_cnsn) {
              print "$cnsn_name\n";
   
          #rozmer vrstvy
          $genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$cnsn_name",data_type => 'LIMITS');
    	    my $myDpsXsize = $genesis->{doinfo}{gLIMITSxmin};
          my $myDpsYsize = $genesis->{doinfo}{gLIMITSymin};
          my $myDpsXsizeMAX = $genesis->{doinfo}{gLIMITSxmax};
	        my $myDpsYsizeMAX = $genesis->{doinfo}{gLIMITSymax};
	     
	        print "Rozmer X je ".$myDpsXsize."\n";
          print "Rozmer Y je ".$myDpsYsize."\n";
          print "Rozmer X je ".$myDpsXsizeMAX."\n";
          print "Rozmer Y je ".$myDpsYsizeMAX."\n";
       
          my $minusmyDpsXsize = ($myDpsXsize-1);
          my $minusmyDpsYsize = ($myDpsYsize-1);
          my $plusmyDpsXsizeMAX = ($myDpsXsizeMAX+1);
          my $plusmyDpsYsizeMAX = ($myDpsYsizeMAX+1);

          $genesis-> COM ("matrix_add_row",job=>"$jobName",matrix=>"matrix");
          $genesis-> COM ("matrix_refresh",job=>"$jobName",matrix=>"matrix");
          $genesis->INFO(units => 'mm', entity_type => 'matrix',entity_path => "$jobName/matrix",data_type => 'NUM_ROWS');
          my $row = $genesis->{doinfo}{gNUM_ROWS};
          $genesis-> COM ("matrix_add_layer",job=>"$jobName",matrix=>"matrix",layer=>"docasna",row=>"$row",context=>"misc",type=>"signal",polarity=>"positive");

          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
					$genesis -> COM ('display_layer',name=>"docasna",display=>'yes',number=>'1');
					$genesis -> COM ('work_layer',name=>"docasna");      	
	       
    #prida surface 
          $genesis->COM ('add_surf_strt',surf_type=>'feature');
      		$genesis->COM ('add_surf_poly_strt',x=>"$minusmyDpsXsize",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_seg',x=>"$minusmyDpsXsize",y=>"$plusmyDpsYsizeMAX");
      		$genesis->COM ('add_surf_poly_seg',x=>"$plusmyDpsXsizeMAX",y=>"$plusmyDpsYsizeMAX");
      		$genesis->COM ('add_surf_poly_seg',x=>"$plusmyDpsXsizeMAX",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_seg',x=>"$minusmyDpsXsize",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_end');
      		$genesis->COM ('add_surf_end',attributes=>'no',polarity=>'positive');

          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
          $genesis -> COM ('display_layer',name=>"$cnsn_name",display=>'yes',number=>'1');
          $genesis -> COM ('work_layer',name=>"$cnsn_name");   
          						
          $genesis-> COM ("sel_move_other",target_layer=>"docasna",invert=>"yes",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
          $genesis -> COM ('display_layer',name=>"docasna",display=>'yes',number=>'1');
          $genesis -> COM ('work_layer',name=>"docasna");
          $genesis-> COM ("sel_move_other",target_layer=>"$cnsn_name",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
          $genesis -> COM ('display_layer',name=>"docasna",display=>'no',number=>'1');
          		
          
          $genesis-> COM ("matrix_delete_row",job=>"$jobName",matrix=>"matrix",row=>"$row");	
    
        }          
}

sub negativ_na_positiv {

      #prohledani klicu v tabulce %hash_pcnppsnp
        foreach my $pcnp_psnp_name (keys %hash_pcnppsnp) {
          print "$pcnp_psnp_name\n";
   
          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
					$genesis -> COM ('display_layer',name=>"$pcnp_psnp_name",display=>'yes',number=>'1');
					$genesis -> COM ('work_layer',name=>"$pcnp_psnp_name");   
          $genesis-> COM ("sel_transform",mode=>"anchor",oper=>"mirror",duplicate=>"no",x_anchor=>"0",y_anchor=>"0",angle=>"90",x_scale=>"1",y_scale=>"1",x_offset=>"0",y_offset=>"0");
          $genesis -> COM ('display_layer',name=>"$pcnp_psnp_name",display=>'no',number=>'1');						
        }

}

sub positiv_mirror_negativ {

        foreach my $pcpnpspn_name (keys %hash_pcpnpspn) {
          print "$pcpnpspn_name\n";

          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
					$genesis -> COM ('display_layer',name=>"$pcpnpspn_name",display=>'yes',number=>'1');
					$genesis -> COM ('work_layer',name=>"$pcpnpspn_name");   
          $genesis -> COM ("sel_transform",mode=>"anchor",oper=>"mirror",duplicate=>"no",x_anchor=>"0",y_anchor=>"0",angle=>"90",x_scale=>"1",y_scale=>"1",x_offset=>"0",y_offset=>"0");
          $genesis -> COM ('display_layer',name=>"$pcpnpspn_name",display=>'no',number=>'1');

          #rozmer vrstvy
          $genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$pcpnpspn_name",data_type => 'LIMITS');
    	    my $myDpsXsize = $genesis->{doinfo}{gLIMITSxmin};
          my $myDpsYsize = $genesis->{doinfo}{gLIMITSymin};
          my $myDpsXsizeMAX = $genesis->{doinfo}{gLIMITSxmax};
	        my $myDpsYsizeMAX = $genesis->{doinfo}{gLIMITSymax};
	     
	        print "Rozmer X je ".$myDpsXsize."\n";
          print "Rozmer Y je ".$myDpsYsize."\n";
          print "Rozmer X je ".$myDpsXsizeMAX."\n";
          print "Rozmer Y je ".$myDpsYsizeMAX."\n";
       
          my $minusmyDpsXsize = ($myDpsXsize-1);
          my $minusmyDpsYsize = ($myDpsYsize-1);
          my $plusmyDpsXsizeMAX = ($myDpsXsizeMAX+1);
          my $plusmyDpsYsizeMAX = ($myDpsYsizeMAX+1);

          $genesis-> COM ("matrix_add_row",job=>"$jobName",matrix=>"matrix");
          $genesis-> COM ("matrix_refresh",job=>"$jobName",matrix=>"matrix");
          $genesis->INFO(units => 'mm', entity_type => 'matrix',entity_path => "$jobName/matrix",data_type => 'NUM_ROWS');
          my $row = $genesis->{doinfo}{gNUM_ROWS};
          $genesis-> COM ("matrix_add_layer",job=>"$jobName",matrix=>"matrix",layer=>"docasna",row=>"$row",context=>"misc",type=>"signal",polarity=>"positive");

          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
					$genesis -> COM ('display_layer',name=>"docasna",display=>'yes',number=>'1');
					$genesis -> COM ('work_layer',name=>"docasna");
					
					#prida surface 
          $genesis->COM ('add_surf_strt',surf_type=>'feature');
      		$genesis->COM ('add_surf_poly_strt',x=>"$minusmyDpsXsize",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_seg',x=>"$minusmyDpsXsize",y=>"$plusmyDpsYsizeMAX");
      		$genesis->COM ('add_surf_poly_seg',x=>"$plusmyDpsXsizeMAX",y=>"$plusmyDpsYsizeMAX");
      		$genesis->COM ('add_surf_poly_seg',x=>"$plusmyDpsXsizeMAX",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_seg',x=>"$minusmyDpsXsize",y=>"$minusmyDpsYsize");
      		$genesis->COM ('add_surf_poly_end');
      		$genesis->COM ('add_surf_end',attributes=>'no',polarity=>'positive');

          $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
          $genesis -> COM ('display_layer',name=>"$pcpnpspn_name",display=>'yes',number=>'1');
          $genesis -> COM ('work_layer',name=>"$pcpnpspn_name");   
          						
          $genesis-> COM ("sel_move_other",target_layer=>"docasna",invert=>"yes",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
          $genesis -> COM ('display_layer',name=>"docasna",display=>'yes',number=>'1');
          $genesis -> COM ('work_layer',name=>"docasna");
          $genesis-> COM ("sel_move_other",target_layer=>"$pcpnpspn_name",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
          $genesis -> COM ('display_layer',name=>"docasna",display=>'no',number=>'1');
          		          
          $genesis-> COM ("matrix_delete_row",job=>"$jobName",matrix=>"matrix",row=>"$row");

        }
}

sub test {

        foreach my $pcn_psn_name (values %hash_pcnpsn) {
          print "$pcn_psn_name\n";
        }
}



#=====================================================
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
    	$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$rowNameNew",data_type => 'LIMITS');
        	 $myDpsXsize = $genesis->{doinfo}{gLIMITSxmin};
	         $myDpsYsize = $genesis->{doinfo}{gLIMITSymin};
	         $myDpsXsizeMAX = $genesis->{doinfo}{gLIMITSxmax};
    	     $myDpsYsizeMAX = $genesis->{doinfo}{gLIMITSymax};
	          if ($movoSwitch == 0) {
	       			  $myDpsXsize = (($myDpsXsize * (-1)) + 0.1) ; #0.2 za 0.1 
	       	 		  $myDpsYsize = (($myDpsYsize * (-1)) + 0.1);  #0.2 za 0.1 
	       	 		  $movoSwitch = 1;
	       	  }else{
	       	  	      $myDpsXsize = ((($myDpsXsizeMAX * (-1)) + 609.6) - 0.7);  #0.2 za 0.7 
	       	 		  $myDpsYsize = ((($myDpsYsize 	  * (-1)) +   0.0) + 0.1);   #0.2 za 0.1
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
			$genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$rowNameNew",data_type => 'LIMITS');
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
		$genesis -> INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$rowNameNew",data_type => 'LIMITS');
        	  $dimYlayer = (($genesis->{doinfo}{gLIMITSymax}) - ($genesis->{doinfo}{gLIMITSymin}));
        	 
        	 if ($dimYlayer > 507.8) {
        	 		        $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
							$genesis -> COM ('display_layer',name=>"$rowNameNew",display=>'yes',number=>'1');
							$genesis -> COM ('work_layer',name=>"$rowNameNew");
							$genesis -> COM ('sel_transform',mode=>'anchor',oper=>'rotate',duplicate=>'no',x_anchor=>'0',y_anchor=>'0',angle=>'90',x_scale=>'1',y_scale=>'1',x_offset=>'0',y_offset=>'0');
					    	$genesis -> INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$rowNameNew",data_type => 'LIMITS');
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
			
			  $genesis->INFO(units=>'mm',entity_type => 'layer',entity_path => "$jobName/$stepName/$rowNameNew",data_type => 'LIMITS');
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

sub vrstvy_pole {
     $genesis ->INFO(entity_type => 'matrix',
                    entity_path => "$jobName/matrix",
                      data_type => 'ROW');
      my @ROWname = @{$genesis->{doinfo}{gROWname}};
      my $pocitadlo = 0;
      foreach (@ROWname) {
          if ($ROWname[$pocitadlo] ne "") {          
              push (@novepole,"$ROWname[$pocitadlo]");                      
              ++$pocitadlo;
          }
      }     
}

sub tisk_nove_pole {    
     my $pocitadlo = 0;
        foreach (@novepole) {
            print $novepole[$pocitadlo]."\n";
            ++$pocitadlo;
             
        } 
               
}

sub copy_nova_vrstva {
my $pocet_pole = @novepole;   

my $pocitadlo_global=0;
print $pocitadlo_global."\n";
print $pocet_pole."\n";

    foreach (@novepole) {
        
            if ($novepole[$pocitadlo_global] eq "") {        
            last;
            }        
                                            
        $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]",mode=>"single",affected=>"yes");
        $genesis -> COM ("sel_copy_other",dest=>"layer_name",target_layer=>"_$novepole[$pocitadlo_global]_xx_$novepole[$pocitadlo_global+1]",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");
        $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]",mode=>"single",affected=>"no");                           
        ++$pocitadlo_global;
       
            if ($novepole[$pocitadlo_global] eq "") {        
            last;
            }
                
        $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]",mode=>"single",affected=>"yes");
        $genesis -> COM ("sel_copy_other",dest=>"layer_name",target_layer=>"_$novepole[$pocitadlo_global-1]_xx_$novepole[$pocitadlo_global]",invert=>"no",dx=>"0",dy=>"0",size=>"0",x_anchor=>"0",y_anchor=>"0",rotation=>"0",mirror=>"none");                        
        $genesis -> COM ("affected_layer",name=>"$novepole[$pocitadlo_global]",mode=>"single",affected=>"no");       
        ++$pocitadlo_global; 
              
    } 
}