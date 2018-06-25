#!/usr/bin/perl-w
##################################################################################################################################
#Sript name: mpanel.pl
#Verze     : 1.02
#Use       : Panelizace multipanelu.
#update    : pridani okoli pro RACOM a ATM 
#Vytvoril      : RV
##################################################################################################################################
use Genesis;
use Tk;
use Tk::LabFrame;
use Tk::BrowseEntry;
use sqlNoris;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;


use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Connectors::HeliosConnector::HegMethods';

my $jobName = "$ENV{JOB}";
my $StepName = "o+1";
my $genesis = new Genesis;
$offsetXX = "0";
my $znacky = "GATEMA";
my $atmMaxX = 240;  #maximalni prirez pro ATM
my $atmMaxY = 280;	#maximalni prirez pro ATM
my $racomMaxX = 270; #maximalni prirez pro RACOM
my $racomMaxY = 400; #maximalni prirez pro RACOM	
my $vypln = 1;
my $poolMpanel = 0;
	
	if (HegMethods->GetPcbIsPool($jobName) == 1) {
			$poolMpanel = 1;
	}
	
	
my $main = MainWindow->new;
$main->title('Macro pro mPanel');
$frame0 = $main ->Frame(-width=>100, -height=>20,-bg=>'lightblue')->pack(-side=>'bottom',-fill=>'x');
	if ($StepName eq "") {
		$statusLabel = sprintf "NEPOKRACUJ, NEMAS OTEVRENY ZADNY STEP";
		$status = $frame0 ->Label(-textvariable=>\$statusLabel,-fg=>"red",-bg=>'lightblue',-font=>'normal 9 {bold }')->pack(-side=>'top');
	} else {
		$statusLabel = sprintf "Vypln parametry a proved";
		$status = $frame0 ->Label(-textvariable=>\$statusLabel,-fg=>"black",-bg=>'lightblue',-font=>'normal 9 {bold }')->pack(-side=>'top');
	}

my $customer = getValueNoris($jobName, 'customer');

	if ($customer =~ /[Aa][Tt][Mm][\s][Ee]/) {
		$znacky = "ATM";
}elsif ($customer =~ /[Ee][Ll][Oo][Kk]/) {
		$znacky = "ATM";
}elsif ($customer =~ /[Bb][Mm][Rr]/) {
		$znacky = "BMR";
}



$frame1 = $main->Frame(-width=>100, -height=>80)->pack(-side=>'top',-fill=>'x');
$frame1->Label(-text=>"Aktualni deska $jobName",-font=>'normal 10 {bold }',-fg=>'red')->pack(-side=>'left');
$frame2 = $main->Frame(-width=>100, -height=>80)->pack(-side=>'top',-fill=>'x');
$frame2->Label(-text=>"Script pro panelizaci mPanelu",-font=>'normal 9 {bold}',-fg=>'black')->pack(-side=>'top');
$frame2->Label(-text=>"Zakaznik>>>> $customer",-font=>'normal 10',-fg=>'black')->pack(-side=>'top');
# Vytvoreni Labframe3
$frame3 = $main->LabFrame(-width=>100, -height=>80,-label=>"Nasobnost v ose",-font=>'normal 9 {bold }')->pack(-side=>'top',-fill=>'x');	
$frame3->Label(-text => " X ")->pack(-padx => 24, -pady => 5,-side=>'left');
$X = $frame3->Entry(-width=>10)->pack(-padx => 5, -pady => 5,-side=>'left');
$Y = $frame3->Entry(-width=>10)->pack(-padx => 5, -pady => 5,-side=>'right');
$frame3->Label(-text => " Y ")->pack(-padx => 24, -pady => 5,-side=>'right');
# Vytvoreni frame4
$frame4 = $main->LabFrame(-width=>100, -height=>80,-label=>"Mezera",-font=>'normal 9 {bold }')->pack(-side=>'top',-fill=>'x');
$zadna = $frame4->Radiobutton(-value=>"0", -variable=>\$mezera, -text=>"Zadna")->pack(-padx => 5, -pady => 5,-side=>left);
$mm1 = $frame4->Radiobutton(-value=>"1", -variable=>\$mezera, -text=>"1mm")->pack(-padx => 5, -pady => 5,-side=>left);
$mm2 = $frame4->Radiobutton(-value=>"2", -variable=>\$mezera, -text=>"2mm")->pack(-padx => 5, -pady => 5,-side=>left);
$mm45 = $frame4->Radiobutton(-value=>"4.5", -variable=>\$mezera, -text=>"4.5mm")->pack(-padx => 5, -pady => 5,-side=>left);
$mm10 = $frame4->Radiobutton(-value=>"10", -variable=>\$mezera, -text=>"10.0mm")->pack(-padx => 5, -pady => 5,-side=>left);
$mmXX = $frame4->Entry(-width=>5)->pack(-padx => 0, -pady => 5,-side=>'left');
$frame4->Label(-text => "mm")->pack(-padx => 0, -pady => 0,-side=>'left');
#$mezeraX = $frame4->Entry(-width=>10)->pack(-padx => 5, -pady => 5,-side=>'left');
#$mezeraY = $frame4->Entry(-width=>10)->pack(-padx => 11, -pady => 5,-side=>'right');
#$frame4->Label(-text => " Mezera Y ")->pack(-padx => 5, -pady => 5,-side=>'right');
# Vytvoreni Labframe5
$frame5 = $main->LabFrame(-width=>100, -height=>80,-label=>"Rozmer okoli",-font=>'normal 9 {bold }')->pack(-side=>'top',-fill=>'x');
$zadne = $frame5->Radiobutton(-value=>"zadne", -variable=>\$okoli, -text=>"Zadne")->pack(-side=>left);
$mm5 = $frame5->Radiobutton(-value=>"5", -variable=>\$okoli, -text=>"5mm")->pack(-side=>left);
$mm7 = $frame5->Radiobutton(-value=>"7", -variable=>\$okoli, -text=>"7mm")->pack(-side=>left);
$mm10 = $frame5->Radiobutton(-value=>"10", -variable=>\$okoli, -text=>"10mm")->pack(-side=>left); 
$mm12 = $frame5->Radiobutton(-value=>"12", -variable=>\$okoli, -text=>"12mm")->pack(-side=>left); 
##frame 7
$frame7 = $main->LabFrame(-width=>100, -height=>80,-label=>"Pridat do okoli znacky firmy:",-font=>'normal 9 {bold }',-height=>'20')->pack(-side=>'top',-fill=>'x');
#$atm = $frame7->Radiobutton(-value=>"GATEMA", -variable=>\$znacky, -text=>"GATEMA")->pack(-side=>left);
#$atm = $frame7->Radiobutton(-value=>"ATM", -variable=>\$znacky, -text=>"ATM")->pack(-side=>left);
#$racom = $frame7->Radiobutton(-value=>"RACOM", -variable=>\$znacky, -text=>"RACOM")->pack(-side=>left);
#$wendel = $frame7->Radiobutton(-value=>"WENDEL", -variable=>\$znacky, -text=>"WENDEL")->pack(-side=>left);
$construct_znacky = $frame7->BrowseEntry(-label=>"Vyber okoli",-variable=>\$znacky,-listcmd=>\&fill_znacky,-state=>"readonly",-width=>'15',-font=>'normal 8 {bold }',-fg=>'blue')->pack(-padx => 10, -pady => 10,-side=>bottom); 

# Vytvoreni frame6
$frame6 = $main->Frame(-width=>100, -height=>80)->pack(-side=>'top',-fill=>'x');
$frame6L = $frame6->Frame(-width=>100, -height=>80)->pack(-side=>'left',-fill=>'x');
$frame6P = $frame6->Frame(-width=>100, -height=>80)->pack(-side=>'right',-fill=>'x');

$frame6P->Checkbutton(-variable=>\$poolMpanel, -text=>"POOL mpanel = flatten")->pack(-side=>bottom); 
$frame6P->Label(-text=>"")->pack(-side=>bottom); 

$frame6L->Checkbutton(-variable=>\$rotace90{otoceni}, -text=>"Rotovat o 90 stupnu")->pack(-side=>bottom); 
$frame6L->Checkbutton(-variable=>\$vypln, -text=>"Vyplnit ramecek medi")->pack(-side=>bottom); 




# do hlavniho menu
$tl_no=$main->Button(-text => "Konec",-command=> \&exite);
$tl_no->pack(-padx => 10, -pady => 5,-side=>'right');

$tl_ok=$main->Button(-bg=>'grey',-width=>30,-text => "Proved",-command=> \&Proved);
$tl_ok->pack(-padx => 10, -pady => 5,-side=>'right');
MainLoop ();

#$main->waitWindow; 

sub Proved {
	
	if ($StepName eq "") { 
	$main1 = MainWindow->new;
	$main1->title('A co STEP?');
	$f1 = $main1->Frame(-width=>100, -height=>80)->pack(-side=>'top',-fill=>'x');
	$f1->Label(-text=>"Nemas otevrenej STEP?",-font=>'normal 25 {italic}',-fg=>'red',-bg=>'black')->pack(-side=>'top');
	$tlac_ok=$main1->Button(-text => "Konec",-command=> \&exite);
	$tlac_ok->pack(-padx => 10, -pady => 5,-side=>'bottom');
	$main1->waitWindow; 

	}
$genesis ->COM ('set_step',name=>'o+1');
#Startpan
	$genesis->COM('create_layer',layer=>'__pomocna__',context=>'misc',type=>'document',polarity=>'positive',ins_layer=>'');
	$nx = $X -> get;
	$ny = $Y -> get;
	unless ($mezera) {
		$mezera = $mmXX -> get;
	}	
#Zjisteni rozmeru DPS
$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$StepName",data_type => 'PROF_LIMITS');
$pcbXsize = sprintf "%3.6f",($genesis->{doinfo}{gPROF_LIMITSxmax} - $genesis->{doinfo}{gPROF_LIMITSxmin});
$pcbYsize = sprintf "%3.6f",($genesis->{doinfo}{gPROF_LIMITSymax} - $genesis->{doinfo}{gPROF_LIMITSymin});
	
	if ($rotace90{otoceni}==1) {
				    $rotace = "90";	
					$newsize = $pcbXsize; 
					$pcbXsize = $pcbYsize;
					$pcbYsize = $newsize;
					$panelX = (($nx*$pcbXsize)+(($nx*$mezera)-$mezera));
					$panelY = (($ny*$pcbYsize)+(($ny*$mezera)-$mezera));
					$pcbXsize+= $mezera;
					$pcbYsize+= $mezera;
					$offsetXX = ($pcbYsize-$mezera);
	}
	else {
		$panelX = (($nx*$pcbXsize)+(($nx*$mezera)-$mezera));
		$panelY = (($ny*$pcbYsize)+(($ny*$mezera)-$mezera));
		$pcbXsize+= $mezera;
		$pcbYsize+= $mezera;
		$rotace = "0";
	}
	$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/mpanel",data_type=>'exists');
			if ($genesis->{doinfo}{gEXISTS} eq "yes") {	
					$genesis -> COM ('delete_entity',job=>"$jobName",type=>'step',name=>'mpanel');
			}
				

$genesis ->COM ('create_entity',job=>"$jobName",name=>'mpanel',db=>'incam',is_fw=>'no',type=>'step',fw_type=>'form');

$genesis->COM('set_step',name=>'mpanel');


$genesis ->COM ('affected_layer',mode=>'all',affected=>'no');
$genesis ->COM ('sr_popup');
$genesis ->COM ('set_step',name=>'mpanel');

			$genesis->INFO(entity_type=>'step',entity_path=>"$jobName/panel",data_type=>'exists');
					if ($genesis->{doinfo}{gEXISTS} eq "yes") {
								$genesis ->COM ('delete_entity',job=>"$jobName",name=>'panel',type=>'step');
					}
					
$genesis ->COM ('sr_tab_add',line=>'1',step=>'o+1',x=>'0',y=>"$offsetXX",nx=>"$nx",ny=>"$ny",dx=>"$pcbXsize",dy=>"$pcbYsize",angle=>"$rotace",flip=>'no',mirror=>'no');
$genesis ->COM ('display_layer',name=>'__pomocna__',display=>'yes',number=>'1');
$genesis ->COM ('work_layer',name=>'__pomocna__');
$genesis ->COM ('add_polyline_strt');
$genesis ->COM ('add_polyline_xy',x=>'0',y=>'0');
$genesis ->COM ('add_polyline_xy',x=>"$panelX",y=>'0');
$genesis ->COM ('add_polyline_xy',x=>"$panelX",y=>"$panelY");
$genesis ->COM ('add_polyline_xy',x=>'0',y=>"$panelY");
$genesis ->COM ('add_polyline_xy',x=>'0',y=>'0');
$genesis ->COM ('add_polyline_end',attributes=>'no',symbol=>'r300',polarity=>'positive');

#  nastaveni attributu frezovani
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/mpanel/f",data_type=>'exists');
    if ($genesis->{doinfo}{gEXISTS} eq "yes") {
        $genesis->COM('set_attribute',type=>'step',job=>"$jobName",name1=>'mpanel',name2=>'',name3=>'',attribute=>"NPTH",value=>"f",units=>'inch');
	}else{
		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/mpanel/d",data_type=>'exists');
    		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
        			$genesis->COM('set_attribute',type=>'step',job=>"$jobName",name1=>'mpanel',name2=>'',name3=>'',attribute=>"NPTH",value=>"d",units=>'inch');
			}
	}
if ($okoli == 5) {
	$ramecek = 10000;
	$datumX = -5;
	$datumY = -5;
	if ($znacky eq "GATEMA") {
	 		$fid_schema = 'mpanel_5';
	} elsif ($znacky eq "GATEMA_OLD_5mm") {
			$fid_schema = 'gatema_old_5';
	} elsif ($znacky eq "ATM") {
			$fid_schema = 'cust_atm_5';
	} elsif ($znacky eq "RACOM") {
			$fid_schema = 'cust_racom_5';
	} elsif ($znacky eq "APPLIED") {
			$fid_schema = 'cust_applied_okoli_5';
	} elsif ($znacky eq "TOROLA") {
		    $fid_schema = 'cust_torola_5';
	} elsif ($znacky eq "WENDEL") {
			$fid_schema = 'cust_wendel_5';
	}elsif ($znacky eq "ELMATICA") {
			$fid_schema = 'cust_elmatica_5';
	}elsif ($znacky eq "BMR") {
			$fid_schema = 'cust_bmr_5';
	} elsif ($znacky eq "BEZ_FIDUCIALU") {
			$fid_schema = 'mpanel_bez_fid';
#	} elsif ($znacky eq "PRINCITEC_5x8") {
#			$fid_schema = 'cust_princitec_5x8';
	} else {
			$fid_schema = 0;
	}
}
elsif ($okoli == 10) {
	$ramecek = 20000;
	$datumX = -10;
	$datumY = -10;
	if ($znacky eq "GATEMA") {
			$fid_schema = 'mpanel_10';
	} elsif ($znacky eq "ATM") {
			$fid_schema = 'cust_atm_10';
	} elsif ($znacky eq "AZITECH_10") {
			$fid_schema = 'cust_azitech_10';
	} elsif ($znacky eq "RACOM") {
			$fid_schema = 'cust_racom_10';
	} elsif ($znacky eq "WENDEL") {
			$fid_schema = 'cust_wendel_10';
	} elsif ($znacky eq "APPLIED") {
			$fid_schema = 'cust_applied_okoli_10';
	} elsif ($znacky eq "TOROLA") {
			$fid_schema = 'cust_torola_10';
	} elsif ($znacky eq "BETACONTROL_10mm") {
			$fid_schema = 'cust_betacontrol_okoli_10mm';
	} elsif ($znacky eq "SMT_10mm_12mm") {
			$fid_schema = 'cust_smt_10';
	} elsif ($znacky eq "KVARK_10") {
			$fid_schema = 'cust_kvark_10';
	} elsif ($znacky eq "ELMATICA") {
			$fid_schema = 'cust_elmatica_10';
	} elsif ($znacky eq "PIERONKIEWICZ_10") {
			$fid_schema = 'cust_pieronkiewicz_10';
	} elsif ($znacky eq "BARDAS_10") {
			$fid_schema = 'cust_bardas_10';
	}elsif ($znacky eq "BMR") {
			$fid_schema = 'cust_bmr_10';
	} elsif ($znacky eq "BEZ_FIDUCIALU") {
			$fid_schema = 'mpanel_bez_fid';
	} else {
		$fid_schema = 0;
	}
}
elsif ($okoli == 7) {
	$ramecek = 14000;
	$datumX = -7;
	$datumY = -7;
	if ($znacky eq "GATEMA") {
			$fid_schema = 'mpanel_7';
	} elsif ($znacky eq "ATM") {
			$fid_schema = 'cust_atm_7';
	} elsif ($znacky eq "RACOM") {
			$fid_schema = 'cust_racom_7';
	} elsif ($znacky eq "APPLIED") {
			$fid_schema = 'cust_applied_okoli_7';
	} elsif ($znacky eq "TOROLA") {
			$fid_schema = 'cust_torola_7';
	} elsif ($znacky eq "ELMATICA") {
			$fid_schema = 'cust_elmatica_7';
	}elsif ($znacky eq "BMR") {
			$fid_schema = 'cust_bmr_7';
	}elsif ($znacky eq "C.SAM_7") {
			$fid_schema = 'cust_csam_7';
	} elsif ($znacky eq "BEZ_FIDUCIALU") {
			$fid_schema = 'mpanel_bez_fid';
	} else {
		$fid_schema = 0;
	}
}
elsif ($okoli == 12) {
	$ramecek = 24000;
	$datumX = -12;
	$datumY = -12;
	if ($znacky eq "DICOM_12mm") {
			$fid_schema = 'cust_dicom_12';
	} elsif ($znacky eq "GATEMA") {
			$fid_schema = 'mpanel_12';
	} elsif ($znacky eq "DVORSKY_12mm") {
			$fid_schema = 'cust_dvorsky_12';
	}elsif ($znacky eq "SMT_10mm_12mm") {
			$fid_schema = 'cust_smt_10';
	} elsif ($znacky eq "CST_12mm") {
			$fid_schema = 'cust_cst_12';
	} elsif ($znacky eq "BEZ_FIDUCIALU") {
			$fid_schema = 'mpanel_bez_fid';
	} else {
		$fid_schema = 0;
	}
}
else {
	$ramecek = 0;
	$datumX = 0;
	$datumY = 0;
}
$genesis ->COM ('filter_reset',filter_name=>"popup");
$genesis ->COM ('filter_set',filter_name=>'popup',update_popup=>'no',include_syms=>'r300');
$genesis ->COM ('filter_area_strt');
$genesis ->COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no',lines_only=>'no',ovals_only=>'no',min_len=>'0',max_len=>'0',min_angle=>'0',max_angle=>'0');
$genesis ->COM ('sel_resize_poly',size=>"$ramecek");
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/mpanel/mc",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis ->COM ('sel_copy_other',dest=>'layer_name',target_layer=>'mc',invert=>'no',dx=>'0',dy=>'0',size=>'0');
		}
$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/mpanel/ms",data_type=>'exists');
    	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
				$genesis ->COM ('sel_copy_other',dest=>'layer_name',target_layer=>'ms',invert=>'no',dx=>'0',dy=>'0',size=>'0');
		}
$genesis ->COM ('filter_reset',filter_name=>'popup');
$genesis ->COM ('datum',x=>$datumX,y=>$datumY);
$genesis ->COM ('sel_net_feat',operation=>'select',x=>'0',y=>'0',tol=>'459.3775');
$genesis ->COM ('sel_create_profile');
$genesis ->COM ('zoom_home');
$genesis ->COM('delete_layer',layer=>'__pomocna__');
if ($ramecek ne 0) {
	if ($fid_schema ne 0) {
				$genesis ->COM ('open_auto_panelize',job=>"$jobName",panel=>"mpanel",pcb=>"o+1",scheme=>"");
				$genesis ->COM ('autopan_run_scheme',job=>"$jobName",panel=>'mpanel',pcb=>'o+1',scheme=>"$fid_schema");
				$genesis ->COM ('cur_atr_reset');
				$genesis ->COM ('close_auto_panelize');

#		$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/mpanel/f",data_type=>'exists');
#    		if ($genesis->{doinfo}{gEXISTS} eq "yes") {
#    			$genesis -> COM('profile_to_rout',layer=>'f',width=>'300');
#    		}
	}
		if ($vypln == 1) {
				$genesis ->COM ('clear_layers');
				
			#	$genesis ->COM ('open_auto_panelize',job=>"$jobName",panel=>"",pcb=>"",scheme=>"");
				$genesis ->COM ('autopan_fill',job=>"$jobName",panel=>'mpanel',pcb=>'o+1',scheme=>"vypln_mpanel");
				
				$genesis ->COM ('cur_atr_reset');
				$genesis ->COM ('clear_layers');
			#	$genesis ->COM ('close_auto_panelize');
		}
		
		
}
$panelXX = sprintf "%3.2f",($panelX + ($okoli * 2));
$panelYY = sprintf "%3.2f",($panelY + ($okoli * 2));
$genesis ->COM ('editor_page_close');






if ($znacky eq "ATM") {
		if ($panelXX > $panelYY) {
					$statusLabel = sprintf "!!!POZOR SPATNE!!! Prirez ATM musis panelizovat na vysku!";
					$status->configure(-fg=>"red");
					$status->update;
					
		}else{
				if (($panelXX > $atmMaxX) or ($panelYY > $atmMaxY)) {
						$statusLabel = sprintf "!!!POZOR!!! Nedovoleny rozmer panelu pro ATM! ... $panelXX x $panelYY";	
						$status->configure(-fg=>"red");
						$status->update;
				} else {
						$statusLabel = sprintf "...Hotovo...Rozmer panelu: $panelXX x $panelYY";
				}
		}	
} 
if ($znacky eq "RACOM") {
		if ($panelXX > $panelYY) {
					$statusLabel = sprintf "!!!POZOR SPATNE!!! Prirez RACOM musis panelizovat na vysku!";
					$status->configure(-fg=>"red");
					$status->update;
					
		}else{
				if (($panelXX > $racomMaxX) or ($panelYY > $racomMaxY)) {
						$statusLabel = sprintf "!!!POZOR!!! Nedovoleny rozmer panelu pro RACOM! ... $panelXX x $panelYY";
						$status->configure(-fg=>"red");
						$status->update;
				} else {
						$statusLabel = sprintf "...Hotovo...Rozmer panelu: $panelXX x $panelYY";
				}
		}
} 
unless ($znacky eq 'ATM' or $znacky eq 'RACOM') {
		$statusLabel = sprintf "...Hotovo...Rozmer panelu: $panelXX x $panelYY";
}

		if ($poolMpanel	== 1) {

				$genesis -> COM('script_run',name=>"y:/server/site_data/scripts/flatten_pool.pl",dirmode=>'global',params=>"$jobName mpanel");
		}
}
 
#########################################################################################################
###  SUBROUTINE
###
##########################################################################################################
sub fill_znacky {
    $construct_znacky->delete(0,'end');
    foreach my $className (qw /GATEMA GATEMA_OLD_5mm BMR C.SAM_7 BEZ_FIDUCIALU ATM AZITECH_10 RACOM WENDEL ELMATICA PRINCITEC_5x8 APPLIED DICOM_12mm TOROLA BETACONTROL_10mm DVORSKY_12mm SMT_10mm_12mm PIERONKIEWICZ_10 BARDAS_10 CST_12mm KVARK_10/) {
        $construct_znacky->insert('end',"$className");
    }
}
sub exite {
		foreach my $l ('mc','c','score') {
			if( CamHelper->LayerExists( $genesis, $jobName, $l) ) {
					$genesis->COM("display_layer","name" => $l,"display" => "yes"); 
			}
		}
   exit;
}

