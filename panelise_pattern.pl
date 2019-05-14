#!/usr/bin/perl
#####################################################
#   Script Name         :   Panelise_pattern.pl     #
#   Version             :   2.00                    #
#   Last Modification   :   2011			        #
#####################################################
use Genesis;
use Tk;
use Tk::BrowseEntry;
use Time::localtime;
use Win32::OLE;
use untilityScript;
#
#	Set basic variables
#
my $archiveDPS = 'r:/Archiv';
my $logo_way = "$ENV{GENESIS_DIR}/sys/scripts/gatema/error.gif";
my $jobName = "$ENV{JOB}";
my $panelStepName = "pattern_panel";
my $logoDir = "$ENV{GENESIS_DIR}/sys/scripts/gatema";
my $genesis = new Genesis;
$genesis->COM('get_user_name');
my $userName = "$genesis->{COMANS}";
my $userCode;
if ($userName eq "radek") {
    $userCode = "rc";
} elsif ($userName eq "martin") {
    $userCode = "mku";
} elsif ($userName eq "radim") {
    $userCode = "rvi";
} elsif ($userName eq "lukas") {
    $userCode = "lba";
} elsif ($userName eq "josef") {
    $userCode = "jkr";
} elsif ($userName eq "stepan") {
    $userCode = "spr";
} elsif ($userName eq "vasek") {
    $userCode = "va";
} elsif ($userName eq "tomas") {
    $userCode = "th";
} elsif ($userName eq "ondra") {
    $userCode = "os";
} else {
    $userCode = "none";
}
my $stdPanelX = 300;
my $stdPanelY = 480;
my $smallHole = "r1050";
my $largeHole = "r5100";
my $maxXforSemach = 400;
my $maxYforSemach = 555;
my $okoliSemachX = 73;
my $okoliSemachY = 73;
&info_from_noris;

my $wayArchiv = getPath($jobName);

$zakaznik =~ s/,/ /g;
if ($zakaznik =~ /EMP-Centauri/) {
			$largeHoleDist = 12.5;
}else{
			$largeHoleDist = 15;
}
my $spacingX = 500;
my $spacingY = 500;

#
#	Prompt user when they are not in a job
#
unless ($jobName) {
	$main = MainWindow->new();
	$main->iconify;
	$main->deiconify;
	$main->optionAdd('*foreground'=>'black');
	$main->optionAdd('*background'=>'white');
	$main->optionAdd('*activeForeground'=>'white');
	$main->optionAdd('*activeBackground'=>'black');
	$main->optionAdd('*selectForeground'=>'white');
	$main->optionAdd('*selectBackground'=>'black');
	$main->optionAdd('*font'=>'helvetica 10 bold');
	$main->bind('all','<Return>'=>focusNext);
	$main->bind('all','<KP_Enter>'=>focusNext);
	$main->bind('all','<Tab>'=>focusNext);
	$main->title('Peplertech LTD Automation');
	$main_title = $main->Label(-text=>"Gatema Pattern Panelisation Script")->grid(-column=>1,-row=>0,-sticky=>"news");
	$main_title->configure(-font=>'helvetica 16 bold');
	$status = $main->Label(-textvariable=>\$status_label,-fg=>"black",-bg=>"red")->grid(-column=>0,-row=>2,-sticky=>"ew",-columnspan=>2);
	$status->configure(-font=>'helvetica 16 bold');
	$status_label = sprintf "YOU MUST BE IN A JOB TO RUN SCRIPT";
	$main->Button(-text=>"CLOSE AND QUIT",-command=>\&exit_script)->grid(-column=>0,-row=>3,-sticky=>"ew",-columnspan=>2);
	$main->waitWindow;
	exit (0);
}

    $genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/sa-ori",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
						push(@layerList,'sa-ori');
				}
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/sb-ori",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
						push(@layerList,'sb-ori');
				}
#
#	Present main GUI for user 
#
$main = MainWindow->new();
$main->iconify;
$main->deiconify;
$main->optionAdd('*foreground'=>'black');
$main->optionAdd('*background'=>'Paleturquoise');
$main->optionAdd('*activeForeground'=>'grey');
$main->optionAdd('*activeBackground'=>'black');
$main->optionAdd('*selectForeground'=>'grey');
$main->optionAdd('*selectBackground'=>'black');
$main->optionAdd('*font'=>'helvetica 10 bold');
$main->bind('all','<Return>'=>focusNext);
$main->bind('all','<KP_Enter>'=>focusNext);
$main->bind('all','<Tab>'=>focusNext);
$main->title('Peplertech LTD Automation');
$main->geometry('+100+0');
$main->gridColumnconfigure(0,-minsize=>150);
$main->gridColumnconfigure(1,-minsize=>150);
$main->gridColumnconfigure(2,-minsize=>150);
$main->gridColumnconfigure(3,-minsize=>150);

$logo_frame = $main->Frame()->grid(-column=>0,-row=>1,-sticky=>"ew",-columnspan=>5);



$main_title = $logo_frame->Label(-text=>"Gatema create stencil")->grid(-column=>0,-row=>1,-sticky=>"news");
$main_title->configure(-font=>'helvetica 16 bold');
$main->Label(-text=>"Reference : ")->grid(-column=>0,-row=>2,-sticky=>"news",-columnspan=>2);
$main->Label(-text=>"$jobName")->grid(-column=>2,-row=>2,-sticky=>"news",-columnspan=>2);

$main->Label(-text=>"Panel Size X: ")->grid(-column=>0,-row=>3,-sticky=>"news",-columnspan=>1);
$panel_x_entry = $main->Entry(-width=>10,-bg=>'lightgrey')->grid(-column=>1,-row=>3,-sticky=>"nsew",-columnspan=>1);
$panel_x_entry->insert('end',"$stdPanelX");
$main->Label(-text=>"Panel Size Y: ")->grid(-column=>2,-row=>3,-sticky=>"news",-columnspan=>1);
$panel_y_entry = $main->Entry(-width=>10,-bg=>'lightgrey')->grid(-column=>3,-row=>3,-sticky=>"nsew",-columnspan=>1);
$panel_y_entry->insert('end',"$stdPanelY");

$main->Label(-text=>"Step k panelizaci : ")->grid(-column=>0,-row=>4,-sticky=>"news",-columnspan=>2);
$panelise_step_entry = $main->BrowseEntry(-label=>"",-variable=>\$pcbStep,-listcmd=>\&fill_pcb_list,-state=>"readonly",-width=>10)->grid(-column=>2,-row=>4,-sticky=>"nsew",-columnspan=>2);

$main->Label(-text=>"Vrstva k panelizaci")->grid(-column=>0,-row=>5,-sticky=>"news",-columnspan=>2);
$layer_entry = $main->BrowseEntry(-label=>"",-variable=>\$layerToPanel,-listcmd=>\&fill_layer_list,-state=>"readonly",-width=>10)->grid(-column=>2,-row=>5,-sticky=>"nsew",-columnspan=>2);

$main->Label(-text=>"Tloustka sablony ")->grid(-column=>0,-row=>6,-sticky=>"news",-columnspan=>2);
$tloustka_entry = $main->BrowseEntry(-label=>"",-variable=>\$tlSablony,-listcmd=>\&fill_tl_list,-state=>"readonly",-width=>10)->grid(-column=>2,-row=>6,-sticky=>"nsew",-columnspan=>2);


$main->Label(-text=>"Hole Mezera X: ")->grid(-column=>0,-row=>7,-sticky=>"news",-columnspan=>2);
$hole_spacing_entry = $main->Entry(-width=>10)->grid(-column=>2,-row=>7,-sticky=>"nsew",-columnspan=>2);
$hole_spacing_entry->insert('end',"$largeHoleDist");

$main->Label(-text=>"Circuit Orientation: ")->grid(-column=>0,-row=>8,-sticky=>"news",-columnspan=>2);
$orientation_button = $main->Button(-text=>"any",-command=>\&change_orientation,-bd=>'0')->grid(-column=>2,-row=>8,-sticky=>"news",-columnspan=>2);

$main->Label(-text=>"Obe strany na 1 sablonu")->grid(-column=>0,-row=>9,-sticky=>"news",-columnspan=>2);
$main->Checkbutton(-text=>"",-variable=>\$bothYes)->grid(-column=>2,-row=>9,-sticky=>"news",-columnspan=>2);

$main->Label(-text=>"Rucne vlozit desku do panelu")->grid(-column=>0,-row=>10,-sticky=>"news",-columnspan=>2);
$main->Checkbutton(-text=>"",-variable=>\$rucneYes)->grid(-column=>2,-row=>10,-sticky=>"news",-columnspan=>2);

$main->Label(-text=>"Vyroba v Gateme",-bg=>'grey')->grid(-column=>0,-row=>11,-sticky=>"news",-columnspan=>2);
$main->Checkbutton(-text=>"",-variable=>\$gatemaYes,-bg=>'grey')->grid(-column=>2,-row=>11,-sticky=>"news",-columnspan=>2);

$main->Label(-text=>"Kooperace v Semachu",-bg=>'grey')->grid(-column=>0,-row=>12,-sticky=>"news",-columnspan=>2);
$main->Checkbutton(-text=>"",-variable=>\$semachYes,-bg=>'grey')->grid(-column=>2,-row=>12,-sticky=>"news",-columnspan=>2);

$main->Label(-text=>"Kooperace laser",-bg=>'grey')->grid(-column=>0,-row=>13,-sticky=>"news",-columnspan=>2);
$main->Checkbutton(-text=>"",-variable=>\$laserYes,-bg=>'grey')->grid(-column=>2,-row=>13,-sticky=>"news",-columnspan=>2);

$porovnani = $zakaznik;
open (AREAFILE,"r:/Pcb/Pcb/INFORMACE_O_ZAKAZNIKOVI/INFO_sablona.ini");
            while (<AREAFILE>) {
                if ($_ =~ /$porovnani/g) {
                            @fields= split/$porovnani/,"$_";
                            		chomp(@fields);
                                    push (@poznamky,@fields);
                            @policko = split/-/,"@poznamky";
                }
            }
close AREAFILE;
$lenghtRow = length("$policko[1]");
$pocetRadku = sprintf "%d",($lenghtRow / 80);

		$pocetRadku += 1;

$customerMessage = $main->LabFrame(-width=>100, -height=>40,-label=>"Pozmanky k zakaznikovi - $porovnani",-font=>'normal 9 {bold }',-labelside=>'top',-bg=>'grey',-borderwidth=>'2',-fg=>'white')->grid(-column=>0,-row=>14,-sticky=>"news",-columnspan=>4);
$helpItem = 0;
	for ($rad=1;$rad<=$pocetRadku;$rad++) {
				
				$prvniRadek{$rad} = substr("$policko[1]",$helpItem,80);
					
					
		$poznamky{$rad} = $customerMessage -> Label(-text=>"$prvniRadek{$rad}",-bg=>'grey',-fg=>'white',-font=>'normal 12',-justify=>left)->grid(-column=>0,-row=>"$rad",-sticky=>"w",-columnspan=>'4');
	$helpItem += 80;
	}

$main->Checkbutton(-text=>" Export Pdf",-variable=>\$exportPdf,-fg=>'white',-bg=>'red',-selectcolor=>'grey',-indicatoron=>'')->grid(-column=>0,-row=>15,-sticky=>"news",-columnspan=>1);
$main->Checkbutton(-text=>" Export Gerber dat",-variable=>\$exportGerber,-fg=>'white',-bg=>'red',-selectcolor=>'grey',-indicatoron=>'')->grid(-column=>1,-row=>15,-sticky=>"news",-columnspan=>1);
$main->Checkbutton(-text=>" Vykreslit",-variable=>\$exportPlotr,-fg=>'white',-bg=>'red',-selectcolor=>'grey',-indicatoron=>'')->grid(-column=>2,-row=>15,-sticky=>"news",-columnspan=>2);


$status2 = $main->Label(-textvariable=>\$statusLabel,-fg=>"black",-bg=>"PaleGoldenrod")->grid(-column=>0,-row=>50,-sticky=>"news",-columnspan=>5);
$statusLabel = sprintf "Please select parameters then continue";

$main->Button(-text=>"Panelise",-command=>\&panelise_job,-bg=>'MediumAquamarine')->grid(-column=>0,-row=>51,-sticky=>"news",-columnspan=>2);
$main->Button(-text=>"Close and Quit",-command=>\&exit_script,-bg=>'MediumAquamarine')->grid(-column=>2,-row=>51,-sticky=>"news",-columnspan=>2);
$panelSizeCheck = "std";
$panelTypeCheck = "fixed_single";

$main->waitWindow;

exit (0);


#########################################################################################
#   Subroutines
########################################################################################s#

sub exit_script {
	#	Close the GUI and exit script
	#
	if ($main) {
		$main->destroy;
	}
	exit (0);
}


sub fill_pcb_list {
	$panelise_step_entry->delete(0,'end');
        $genesis->INFO(entity_type => 'job',entity_path => "$jobName",data_type => 'STEPS_LIST');
        my @stepsList = @{$genesis->{doinfo}{gSTEPS_LIST}};
        foreach my $stepName (@stepsList) {
        	if ($stepName ne "panel") {
	        	$panelise_step_entry->insert('end',"$stepName");
	        }
        }
}

sub fill_tl_list {
    $tloustka_entry->delete(0,'end');
    foreach my $tlSablony (qw /0.10 0.125 0.15 0.175 0.20 0.25 0.30/) {
        $tloustka_entry->insert('end',"$tlSablony");
    }
}
sub fill_layer_list {
		$layer_entry->delete(0,'end');
    foreach my $layerToPanel (@layerList) {
        $layer_entry->insert('end',"$layerToPanel");
    }
}
sub change_orientation {
	my $currentOrientation = $orientation_button->cget(-text);
	if ($currentOrientation =~ /any/) {
		$orientation_button->configure(-text=>"horizontal");
		$orientation_button->update;
	} elsif ($currentOrientation =~ /horizontal/) {
		$orientation_button->configure(-text=>"vertical");
		$orientation_button->update;
	} else {
		$orientation_button->configure(-text=>"any");
		$orientation_button->update;
	}
}
sub panelise_job {
	$StepNameSemach = $pcbStep;
	
	$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    	my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
	    for ($count=0;$count<=$totalRows;$count++) {
			my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
			my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
			if ($rowContext eq "misc") {
				if($rowName =~ /\+\+\+/g) {
					$genesis->COM('delete_layer',layer=>"$rowName");
				}
				if($rowName =~ /_cdr/g) {
					$genesis->COM('delete_layer',layer=>"$rowName");
				}
				if($rowName =~ /ag__/g) {
					$genesis->COM('delete_layer',layer=>"$rowName");
				}
				if($rowName =~ /c\+s/g) {
					$genesis->COM('delete_layer',layer=>"$rowName");
				}
				if($rowName =~ /^_t/g) {
					$genesis->COM('delete_layer',layer=>"$rowName");
				}
				if($rowName =~ /^_m/g) {
					$genesis->COM('delete_layer',layer=>"$rowName");
				}
				if($rowName =~ /^_b/g) {
					$genesis->COM('delete_layer',layer=>"$rowName");
				}
			}
    	}
	
	
	
	
	if ($tlSablony eq '') {
		    			$statusLabel = sprintf "Neni zadana tloustka sablony.";
						return ();
			}
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/sa-ori",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
									$saExist = 1;
			    }else{
									$saExist = 0;
			    }
	$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/o+1/sb-ori",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
									$sbExist = 1;
			    }else{
									$sbExist = 0;
			    }
		if ($bothYes == 1) {
					if ($saExist == 0) {
	    						$statusLabel = sprintf "Pro sablonu na obe strany potrebuji vrstvu sa-ori i sb-ori a ty jsem nenasel.";
								return ();
					}
					if ($sbExist == 0) {
	    						$statusLabel = sprintf "Pro sablonu na obe strany potrebuji vrstvu sa-ori i sb-ori a ty jsem nenasel.";
								return ();
					}
		} else {
					unless ($saExist == 1 or $sbExist == 1) {
						    	$statusLabel = sprintf "Pro sablonu potrebuji jednu z vrstev sa-ori nebo sb-ori a ty jsem nenasel.";
								return ();
					}
		}



       $currentStep;
    my $panelXsize;
    my $panelYsize;
    my $pcbXsize;
    my $pcbYsize;
    my $borderXsize;
    my $borderYsize;
    my $stepRotation;
    my $panelScheme;
    my $pcbType;
    my $currentSpacingX;
    my $currentSpacingY;
    my $activeXsize;
    my $activeYsize;

	my $currentPanelX = $panel_x_entry->get;
	my $currentPanelY = $panel_y_entry->get;
	my $currentSpacingX = $spacingX;
	my $currentSpacingY = $spacingY;
	my $currentOrientation = $orientation_button->cget(-text);
	my $currentHoleSpacing = $hole_spacing_entry->get;
 		$panelX = $currentPanelX;
		$panelY = $currentPanelY;
	unless (defined $pcbStep) {
		$statusLabel = sprintf "Neni zadan STEP k panelizaci";
		return ();
	}
	 $currentStep = $pcbStep;
    $genesis->INFO('entity_type'=>'job','entity_path'=>"$jobName",'data_type'=>'STEPS_LIST');
    my @stepList = @{$genesis->{doinfo}{gSTEPS_LIST}};
    	foreach $stepName (@stepList) {
				if ($stepName eq $panelStepName) {
						    $genesis->COM('delete_entity',job=>"$jobName",type=>'step',name=>"$stepName");
				}
    	}
    
    	if($semachYes == 1) {
    					&flatmpanel;
						&semach_kompen;
						&createStep;
						&semach_sablona;
						&niffile;
						  if ($exportGerber == 1) {
				    				&export_gerber_semach;
				    	   }
		}
		
    	if ($laserYes == 1) {
						&createStep;
						&okolilaser;
						&niffile;
				    		if ($exportGerber == 1) {
				    				&export_gerber_laser;
				    		}
		}

				    if ($exportPdf == 1) {
				    			&export_pdf;
				    }
				    if ($exportPlotr == 1) {
					    		&export_plotr;
				    }
				    

    	
sub createStep {
	$statusLabel = sprintf "Create panel step";
	
    $genesis->COM('create_entity',job=>"$jobName",is_fw=>'no',type=>'step',name=>"$panelStepName",db=>'incam',fw_type=>'form');

	$genesis->COM ('set_step',name=>"$panelStepName");

    $genesis->COM('units',type=>'mm');
    $genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
	$statusLabel = sprintf "Start Adding Step and Repeats";
	$genesis->COM('sr_auto',step=>"$currentStep",num_mode=>"multiple",xmin=>0,ymin=>0,width=>"$currentPanelX",height=>"$currentPanelY",panel_margin=>0,step_margin=>1,gold_plate=>'no',gold_side=>'right',orientation=>"$currentOrientation",evaluate=>'no',active_margins=>'yes',top_active=>20,bottom_active=>20,left_active=>0,right_active=>0,step_xy_margin=>'yes',step_margin_x=>"$currentSpacingX",step_margin_y=>"$currentSpacingY");

	 $largeYbottom = 12;
	 $largeYtop = ($currentPanelY - 12);
	 $largeXstart = 0;
	 $largeNumX = (int ($currentPanelX / $currentHoleSpacing) + 1);
	 $largeDistX = ($currentHoleSpacing * 1000);
	 
}
sub niffile {	
	$datumHodnota = get_info_datum();
    open (NIFFILE,">>$wayArchiv/$jobName.nif");
    print NIFFILE "[Sablona]\n";
    print NIFFILE "reference=$jobName\n";
    print NIFFILE "zpracoval=$userCode\n";
	print NIFFILE "single_x=$currentPanelX\n";
	print NIFFILE "single_y=$currentPanelY\n";
    print NIFFILE "nasobnost=1\n";
    print NIFFILE "rozmer_x=$currentPanelX\n";
	print NIFFILE "rozmer_y=$currentPanelY\n";
	print NIFFILE "typ_dps=sablona\n";
	print NIFFILE "tl.Sablony=$tlSablony\n";
	print NIFFILE "datum_pripravy=$datumHodnota\n";
    close NIFFILE;
}


		$statusLabel = sprintf "Finished Panelisation of JOB";
		$status2 ->update;

}





sub info_from_noris {
	
my $dbConnection = Win32::OLE->new("ADODB.Connection");
$dbConnection->Open("DSN=dps;uid=genesis;pwd=genesis");
$sqlStatement = "select top 1
d.nazev_subjektu board_name,
c.nazev_subjektu customer,
m.nazev_subjektu material,
d.maska_c_1 c_mask_colour,
d.maska_c_2 s_mask_colour,
d.potisk c_silk_screen_colour,
d.potisk_typ s_silk_screen_colour,
d.zlaceni golding,
d.strihani cutting,
d.drazkovani slotting,
d.frezovani_pred milling_before,
d.frezovani_po milling_after,
d.hal surface_finishing,
dn.nasobnost_x n_x_multiplicity,
dn.nasobnost_y n_y_multiplicity,
dn.nasobnost n_multiplicity,
dn.konstr_trida n_construction_class,
mn.nazev_subjektu n_material,
dn.strihani n_cutting,
dn.drazkovani n_slotting,
dn.frezovani_pred n_milling_before,
dn.frezovani_po n_milling_after,
prijal.nazev_subjektu n_prijal,
dn.rozmer_x n_x_size,
dn.rozmer_y n_y_size,
z.kusy_pozadavek pocet,
lcs.nf_edit_style('ddlb_22_hal', dn.hal) n_surface
from lcs.desky_22 d 
left outer join lcs.subjekty c on c.cislo_subjektu=d.zakaznik 
left outer join lcs.subjekty m on m.cislo_subjektu=d.material 
left outer join lcs.zakazky_dps_22_hlavicka z on z.deska=d.cislo_subjektu 
left outer join lcs.vztahysubjektu vs on vs.cislo_subjektu=z.cislo_subjektu and vs.cislo_vztahu=22175 
left outer join lcs.zakazky_dps_22_hlavicka n on vs.cislo_vztaz_subjektu=n.cislo_subjektu 
left outer join lcs.subjekty prijal on prijal.cislo_subjektu=n.prijal 
left outer join lcs.desky_22 dn on n.deska=dn.cislo_subjektu 
left outer join lcs.subjekty mn on mn.cislo_subjektu=dn.material 
where d.reference_subjektu='$jobName' 
order by n.cislo_subjektu desc,z.cislo_subjektu desc
";
$sqlExecute = $dbConnection->Execute("$sqlStatement");



	 $zakaznik = convert_from_czech ($sqlExecute->Fields('customer')->Value);
     $boardName = convert_from_czech ($sqlExecute->Fields('board_name')->Value);

$dbConnection->Close();

}
sub convert_from_czech {
	my $lineToConvert = shift;
	my $char;
	my $ret;
	my @str = split(//,$lineToConvert);

	foreach my $char (@str) {
		$char =~ tr/\xE1\xC1\xE8\xC8\xEF\xCF\xE9\xC9\xEC\xCC\xED\xCD\xF3\xD3\xF8\xD8\xB9\xA9\xBB\xAB\xFA\xDA\xF9\xD9\xFD\xDD\xBE\xAE\xF2\xD2/\x61\x41\x63\x43\x64\x44\x65\x45\x65\x45\x69\x49\x6F\x4F\x72\x52\x73\x53\x74\x54\x75\x55\x75\x55\x79\x59\x7A\x5A\x6E\x4E/;
		$ret .= $char;
	}
	return ($ret);
}


sub export_pdf {
		$cestaZdroje = "$wayArchiv/Zdroje";
			$genesis -> COM ('output_layer_reset');
			$genesis -> COM ('output_layer_set',layer=>'_t',angle=>'0',mirror=>'no',x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>"",setupfiletmp=>"",line_units=>'mm',gscl_file=>"");
			$genesis -> COM ('output',job=>"$jobName",step=>"$panelStepName",format=>'PostScript',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>"_${panelX}x${panelY}_${tlSablony}.ps",break_sr=>'yes',break_symbols=>'yes',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',x_anchor=>'0',y_anchor=>'0',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',params_opt=>'yes',orientation=>'automatic',title_opt=>'fix+auto',title=>"",size_mode=>'A4',width=>'0',height=>'0',scale=>'0',output_files=>'multiple');
}
sub export_plotr {
	$cestaZdroje = "$wayArchiv/Zdroje";
	# layer sa
		$genesis->COM('output_layer_reset');
		$genesis->COM('output_layer_set',layer=>"sa",angle=>'0',mirror=>'yes',x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'negative',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
		$genesis->COM('output',job=>"$jobName",step=>"$panelStepName",format=>'LP7008',dir_path=>"$cestaZdroje",prefix=>'',suffix=>'',break_sr=>'yes',break_symbols=>'no',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',units=>'mm',x_anchor=>'0',y_anchor=>'0',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size=>'24x20',local_copy=>"no",send_to_plotter=>"yes",plotter_group=>'imager6',units_factor=>'0.1',auto_purge=>'no',entry_num=>'5',plot_copies=>'1',imgmgr_name=>'',deliver_date=>'',plot_mode=>'single');
	# layer sb	
		$genesis->COM('output_layer_reset');
		$genesis->COM('output_layer_set',layer=>"sb",angle=>'0',mirror=>'no',x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'negative',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
		$genesis->COM('output',job=>"$jobName",step=>"$panelStepName",format=>'LP7008',dir_path=>"$cestaZdroje",prefix=>'',suffix=>'',break_sr=>'yes',break_symbols=>'no',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',units=>'mm',x_anchor=>'0',y_anchor=>'0',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size=>'24x20',local_copy=>"no",send_to_plotter=>"yes",plotter_group=>'imager6',units_factor=>'0.1',auto_purge=>'no',entry_num=>'5',plot_copies=>'1',imgmgr_name=>'',deliver_date=>'',plot_mode=>'single');
}

sub get_info_datum {
	my $datumHodnota = sprintf "%04.f-%02.f-%02.f",(localtime->year() + 1900),(localtime->mon() + 1),localtime->mday();
	return ($datumHodnota);
}

sub semach_sablona {
    				
    		$genesis->COM ('set_step',name=>"$panelStepName");
				
			$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/pattern_panel",data_type => 'PROF_LIMITS');
				$placeForOkoli = $maxYforSemach - $panelY;
			if ($placeForOkoli >= $okoliSemachY) {
							$YdimSemach = 37.50;
							$YmarkSemach = 30.778;
							$Ypolygon = -35;
			}else{
					if ($placeForOkoli < 2) {
							$preskoc = 1;
 					}else{
						$YdimSemach = $placeForOkoli / 2;
						$YmarkSemach = (($placeForOkoli / 2) - 6.70);
						$Ypolygon = -(($placeForOkoli / 2) - 2.50);
					}
			}
							
					$profXmin = ($genesis->{doinfo}{gPROF_LIMITSxmin} - 25);
					$profYmin = ($genesis->{doinfo}{gPROF_LIMITSymin} - $YdimSemach);
					$profXmax = ($genesis->{doinfo}{gPROF_LIMITSxmax} + 25);
					$profYmax = ($genesis->{doinfo}{gPROF_LIMITSymax} + $YdimSemach);
					$profilXmax = $genesis->{doinfo}{gPROF_LIMITSxmax};
					$profilYmax = $genesis->{doinfo}{gPROF_LIMITSymax};
					$rozmerSemachX = ($profXmax - $profXmin);
					$rozmerSemachY = ($profYmax - $profYmin);
			
		unless ($preskoc == 1) {
			$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$panelStepName/_t",data_type=>'exists');
			if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					my $targetLeftBotX = (0 - 15.630);
					my $targetLeftBotY = (0 - $YmarkSemach);
					my $targetLeftTopX = (0 - 15.630);
					my $targetLeftTopY = ($profilYmax + $YmarkSemach);
					my $targetRightTopX = ($profilXmax + 15.630);
					my $targetRightTopY = ($profilYmax + $YmarkSemach);
					my $targetRightBotX = ($profilXmax + 15.630);
					my $targetRightBotY = (0 - $YmarkSemach);
        			$genesis->COM('affected_layer',name=>"_t",mode=>"single",affected=>"yes");
				   	
			        $genesis->COM('add_pad',attributes=>'no',x=>"$targetLeftBotX",y=>"$targetLeftBotY",symbol=>'semach_mark',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
			        $genesis->COM('add_pad',attributes=>'no',x=>"$targetLeftTopX",y=>"$targetLeftTopY",symbol=>'semach_mark',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
			        $genesis->COM('add_pad',attributes=>'no',x=>"$targetRightTopX",y=>"$targetRightTopY",symbol=>'semach_mark',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
			        $genesis->COM('add_pad',attributes=>'no',x=>"$targetRightBotX",y=>"$targetRightBotY",symbol=>'semach_mark',polarity=>'positive',angle=>0,mirror=>'no',nx=>1,ny=>1,dx=>0,dy=>0,xscale=>1,yscale=>1);
			        
					$genesis -> COM ('add_surf_strt',surf_type=>'feature');
					$genesis -> COM ('add_polyline_xy',x=>"$profXmin",y=>"$profYmin");
					$genesis -> COM ('add_polyline_xy',x=>"$profXmax",y=>"$profYmin");
					$genesis -> COM ('add_polyline_xy',x=>"$profXmax",y=>"$profYmax");
					$genesis -> COM ('add_polyline_xy',x=>"$profXmin",y=>"$profYmax");
					$genesis -> COM ('add_polyline_xy',x=>"$profXmin",y=>"$profYmin");
					$genesis -> COM ('add_polyline_end',attributes=>'no',symbol=>'r300',polarity=>'positive');

					$genesis -> COM ('add_text',attributes=>'no',type=>'string',x=>'20',y=>'2.80',text=>"\u$jobName",x_size=>'5.08',y_size=>'5.08',w_factor=>'2',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');
					
					$XtextDim = $profXmin + 3;
					$YtextDim = $profYmin + 3;
						$genesis -> COM ('sr_fill',polarity=>'positive',step_margin_x=>'-20.2',step_margin_y=>"$Ypolygon",step_max_dist_x=>'0',step_max_dist_y=>'0',sr_margin_x=>'0',sr_margin_y=>'0',sr_max_dist_x=>'0',sr_max_dist_y=>'0',nest_sr=>'no',consider_feat=>'yes',feat_margin=>'1',consider_drill=>'no',consider_rout=>'no',dest=>'affected_layers',attributes=>'no');
						$genesis -> COM ('add_pad',attributes=>'no',x=>"$largeXstart",y=>"$largeYbottom",symbol=>"$largeHole",polarity=>'positive',angle=>0,mirror=>'no',nx=>"$largeNumX",ny=>1,dx=>"$largeDistX",dy=>0,xscale=>1,yscale=>1);
						$genesis -> COM ('add_pad',attributes=>'no',x=>"$largeXstart",y=>"$largeYtop",symbol=>"$largeHole",polarity=>'positive',angle=>0,mirror=>'no',nx=>"$largeNumX",ny=>1,dx=>"$largeDistX",dy=>0,xscale=>1,yscale=>1);	        
						$genesis -> COM ('add_text',attributes=>'no',type=>'string',x=>'-10',y=>'400',text=>"$panelX x $panelY mm",x_size=>'4.20',y_size=>'4.20',w_factor=>'1',polarity=>'negative',angle=>'90',mirror=>'no',fontname=>'standard',ver=>'1');
						$genesis -> COM ('add_text',attributes=>'no',type=>'string',x=>"$XtextDim",y=>"$YtextDim",text=>"$rozmerSemachX x $rozmerSemachY",x_size=>'2.00',y_size=>'2.00',w_factor=>'1',polarity=>'positive',angle=>'270',mirror=>'no',fontname=>'standard',ver=>'1');
						
						$genesis->COM ('set_step',name=>"o+1");

						$genesis -> COM ('display_layer',name=>'_t',display=>'yes',number=>'1');
						$genesis -> COM ('work_layer',name=>'_t');
						$genesis -> COM ('sel_copy_other',dest=>'layer_name',target_layer=>'_b',invert=>'no',dx=>'0',dy=>'0',size=>'0',x_anchor=>'0',y_anchor=>'0',rotation=>'0',mirror=>'none'); 
						$genesis -> COM ('affected_layer',name=>"_b",mode=>"single",affected=>"no");
						$genesis->COM('editor_page_close');
			}
		}else {
			$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$panelStepName/_t",data_type=>'exists');
				if ($genesis->{doinfo}{gEXISTS} eq "yes") {
					$genesis -> COM ('profile_to_rout',layer=>'_t',width=>'300');
					$genesis -> COM('affected_layer',name=>"_t",mode=>"single",affected=>"yes");
					$genesis -> COM ('add_text',attributes=>'no',type=>'string',x=>'20',y=>'2.80',text=>"\u$jobName",x_size=>'5.08',y_size=>'5.08',w_factor=>'2',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');

					$genesis -> COM ('add_pad',attributes=>'no',x=>"$largeXstart",y=>"$largeYbottom",symbol=>"$largeHole",polarity=>'positive',angle=>0,mirror=>'no',nx=>"$largeNumX",ny=>1,dx=>"$largeDistX",dy=>0,xscale=>1,yscale=>1);
					$genesis -> COM ('add_pad',attributes=>'no',x=>"$largeXstart",y=>"$largeYtop",symbol=>"$largeHole",polarity=>'positive',angle=>0,mirror=>'no',nx=>"$largeNumX",ny=>1,dx=>"$largeDistX",dy=>0,xscale=>1,yscale=>1);
					$genesis -> COM('affected_layer',name=>"_t",mode=>"single",affected=>"no");
				}
		}
						
						$genesis->COM ('set_step',name=>"$panelStepName");
						$genesis->COM('affected_layer',name=>"_t",mode=>"single",affected=>"no");
						$genesis->COM('copy_layer',source_job=>"$jobName",source_step=>'pattern_panel',source_layer=>'_t',dest=>'layer_name',dest_layer=>'_b',mode=>'append',invert=>'no');
						$genesis -> COM ('display_layer',name=>'_b',display=>'yes',number=>'1');
						$genesis -> COM ('work_layer',name=>'_b');
						$genesis -> COM ('filter_set',filter_name=>'popup',update_popup=>'no',feat_types=>'text');
						$genesis -> COM ('filter_area_strt');
						$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
						$genesis -> COM ('sel_delete');
						$genesis -> COM ('filter_reset',filter_name=>'popup');
						$genesis -> COM ('affected_layer',name=>"_b",mode=>"single",affected=>"no");
						$genesis->COM('editor_page_close');
}




sub semach_kompen {
	
	#$genesis -> COM ('save_job',job=>"$jobName",override=>'no');
	
	#$genesis -> COM ('editor_page_close');
	#$genesis ->	COM ('close_job',job=>"$jobName");
	#$genesis ->	COM ('close_form',job=>"$jobName");
	#$genesis ->	COM ('close_flow',job=>"$jobName");
	
	
	$genesis->COM ('set_step',name=>"$StepNameSemach");

			if ($bothYes == 1) {
						$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$StepNameSemach/sa-ori",data_type=>'exists');
									if ($genesis->{doinfo}{gEXISTS} eq "yes") {
												$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$StepNameSemach",source_layer=>'sa-ori',dest=>'layer_name',dest_layer=>'_t',mode=>'replace',invert=>'no');
												$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
												$genesis -> COM ('display_layer',name=>'_t',display=>'yes',number=>'1');
												$genesis -> COM ('work_layer',name=>'_t');
												#konturizace tam musi zustat, aby kdyz budeme mit vycaranou plosku LINE , tak by se nezkompenzovala.
												$genesis -> COM ('sel_contourize',accuracy=>'6.35',break_to_islands=>'yes',clean_hole_size=>'60',clean_hole_mode=>'x_and_y');
												
												&vypocetKo;
												$genesis -> COM ('sel_cont2pad',match_tol=>'25.4',restriction=>'',min_size=>'127',max_size=>'12000');
												$genesis -> COM ('display_layer',name=>'_t',display=>'no',number=>'1');
									}
						$genesis->INFO(entity_type=>'layer',entity_path=>"$jobName/$StepNameSemach/sb-ori",data_type=>'exists');
									if ($genesis->{doinfo}{gEXISTS} eq "yes") {
												$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$StepNameSemach",source_layer=>'sb-ori',dest=>'layer_name',dest_layer=>'_b',mode=>'replace',invert=>'no');
												$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
												$genesis -> COM ('display_layer',name=>'_b',display=>'yes',number=>'1');
												$genesis -> COM ('work_layer',name=>'_b');
#konturizace tam musi zustat, aby kdyz budeme mit vycaranou plosku LINE , tak by se nezkompenzovala.
												$genesis -> COM ('sel_contourize',accuracy=>'6.35',break_to_islands=>'yes',clean_hole_size=>'60',clean_hole_mode=>'x_and_y');
												&vypocetKo;
												$genesis -> COM ('sel_cont2pad',match_tol=>'25.4',restriction=>'',min_size=>'127',max_size=>'12000');
												$genesis -> COM ('display_layer',name=>'_b',display=>'no',number=>'1');
									}
							$genesis -> COM ('matrix_auto_rows',job=>"$jobName",matrix=>'matrix',rename=>'no');
							$genesis -> COM ('flip_step',job=>"$jobName",step=>"$StepNameSemach",flipped_step=>"$StepNameSemach+flip+1",new_layer_suffix=>'_flp',mode=>'center',board_only=>'yes');
							$genesis -> COM ('copy_entity',type=>'step',source_job=>"$jobName",source_name=>"$StepNameSemach+flip+1",dest_job=>"$jobName",dest_name=>"$StepNameSemach+flip",dest_database=>'');
							$genesis -> COM ('delete_entity',job=>"$jobName",type=>'step',name=>"$StepNameSemach+flip+1");
							
								foreach $itemLayer ("$StepNameSemach","$StepNameSemach+flip") {
									$genesis->COM ('set_step',name=>"$itemLayer");
								    $genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
									$genesis -> COM ('display_layer',name=>'_b',display=>'yes',number=>'1');
									$genesis -> COM ('work_layer',name=>'_b');
									$genesis -> COM ('sel_delete');
									$genesis -> COM ('display_layer',name=>'_b',display=>'no',number=>'1');
									$genesis -> COM ('display_layer',name=>'_t',display=>'yes',number=>'1');
									$genesis -> COM ('work_layer',name=>'_t');
									$genesis -> COM ('sel_copy_other',dest=>'layer_name',target_layer=>'_b',invert=>'no',dx=>0,dy=>0,size=>0,x_anchor=>0,y_anchor=>0,rotation=>0,mirror=>'none');
									$genesis -> COM ('display_layer',name=>'_t',display=>'no',number=>'1'); 
								}
			}else{
												$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$StepNameSemach",source_layer=>"$layerToPanel",dest=>'layer_name',dest_layer=>'_t',mode=>'replace',invert=>'no');
												$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$StepNameSemach",source_layer=>"$layerToPanel",dest=>'layer_name',dest_layer=>'_m',mode=>'replace',invert=>'no');
												$genesis -> COM ('affected_layer',affected=>'no',mode=>'all');
												$genesis -> COM ('display_layer',name=>'_t',display=>'yes',number=>'1');
												$genesis -> COM ('work_layer',name=>'_t');
#konturizace tam musi zustat, aby kdyz budeme mit vycaranou plosku LINE , tak by se nezkompenzovala.
												$genesis -> COM ('sel_contourize',accuracy=>'6.35',break_to_islands=>'yes',clean_hole_size=>'60',clean_hole_mode=>'x_and_y');
												&vypocetKo;
												$genesis -> COM ('sel_cont2pad',match_tol=>'25.4',restriction=>'',min_size=>'127',max_size=>'12000');
												
												$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$StepNameSemach",source_layer=>"_t",dest=>'layer_name',dest_layer=>'_b',mode=>'replace',invert=>'no');
												$genesis -> COM ('display_layer',name=>'_t',display=>'no',number=>'1');
			}
				$genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    				my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
					    for ($count=0;$count<=$totalRows;$count++) {
							my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
							my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
								if ($rowContext eq "misc") {
										if($rowName =~ /\+\+\+/g) {
												$genesis->COM('delete_layer',layer=>"$rowName");
										}
								}
				    	}
}
sub vypocetKo {
	if ($tlSablony == 0.1) {
			$minWidth = 0.169;#0.17
			$maxWidth = 0.22;#0.21
			$rezisePads = -30;
		&resize;
			$minWidth = 0.22;
			$maxWidth = 50;
			$rezisePads = -50;
		&resize;
	}
	if ($tlSablony == 0.125) {
			$minWidth = 0.18;#0.18
			$maxWidth = 0.241;#0.24
			$rezisePads = -30;
		&resize;
			$minWidth = 0.242;
			$maxWidth = 50;
			$rezisePads = -60;
		&resize;
	}
	if ($tlSablony == 0.15) {
			$minWidth = 0.219;#0.22
			$maxWidth = 0.261;#0.26
			$rezisePads = -30;
		&resize;
			$minWidth = 0.261;
			$maxWidth = 50;
			$rezisePads = -75;
		&resize;
	}
	if ($tlSablony == 0.175) {
			$minWidth = 0;
			$maxWidth = 0;
			$rezisePads = -87.5;
		&resize;
	}
	if ($tlSablony == 0.20) {
			$minWidth = 0;
			$maxWidth = 0;
			$rezisePads = -100;
		&resize;
	}
	if ($tlSablony == 0.25) {
			$minWidth = 0;
			$maxWidth = 0;
			$rezisePads = -125;
		&resize;
	}
	if ($tlSablony == 0.30) {
			$minWidth = 0;
			$maxWidth = 0;
			$rezisePads = -150;
		&resize;
	}
}

sub resize {
	#unless ($minWidth == 0 and $maxWidth == 0) {
		$genesis -> COM ('adv_filter_set',filter_name=>'popup',update_popup=>'yes',bound_box=>'yes',min_width=>"$minWidth",max_width=>"$maxWidth",min_length=>'0',max_length=>'0');
		$genesis -> COM ('filter_area_strt');
		$genesis -> COM ('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'no');
	#}
				if ($genesis->{COMANS} > 0) {
								$genesis -> COM ('sel_resize',size=>"$rezisePads",corner_ctl=>'no'); 
				}
	$genesis -> COM ('filter_reset',filter_name=>'popup');
}

sub export_gerber {
	foreach $once(sa,sb) {
		if($once eq 'sa') {
			$mirrorGerber = 'yes';
		}else{
			$mirrorGerber = 'no';
		}
		$cestaZdroje = "$wayArchiv";
		$genesis -> COM ('output_layer_reset');	
		$genesis -> COM ('output_layer_set',layer=>"$once",angle=>'0',mirror=>"$mirrorGerber",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
		$genesis -> COM ('output',job=>"$jobName",step=>"$panelStepName",format=>'Gerber274x',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>'n-.ger',break_sr=>'no',break_symbols=>'yes',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
	}
}
sub export_gerber_semach {
	foreach $once(_t,_b,_m) {
		if($once eq '_t') {
			$mirrorGerber = 'yes';
			$suffix = '.gbr';
		}else{
			$mirrorGerber = 'no';
			$suffix = '.gbr';
		}
		$cestaZdroje = "$wayArchiv/Zdroje/semach";
		$genesis -> COM ('output_layer_reset');	
		$genesis -> COM ('output_layer_set',layer=>"$once",angle=>'90',mirror=>"$mirrorGerber",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
		$genesis -> COM ('output',job=>"$jobName",step=>"$panelStepName",format=>'Gerber274x',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>"$suffix",break_sr=>'yes',break_symbols=>'yes',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
	}
}
sub export_gerber_laser {
	foreach $once(_t) {
		if($once eq '_t') {
			$mirrorGerber = 'no';
			$suffix = '_laser.gbr';
		}else{
			$mirrorGerber = 'no';
			$suffix = '.gbr';
		}
		$cestaZdroje = "$wayArchiv/Zdroje/laser";
		$genesis -> COM ('output_layer_reset');	
		$genesis -> COM ('output_layer_set',layer=>"$once",angle=>'0',mirror=>"$mirrorGerber",x_scale=>'1',y_scale=>'1',comp=>'0',polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
		$genesis -> COM ('output',job=>"$jobName",step=>"$panelStepName",format=>'Gerber274x',dir_path=>"$cestaZdroje",prefix=>"$jobName",suffix=>"$suffix",break_sr=>'yes',break_symbols=>'yes',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',min_brush=>'25.4',units=>'inch',coordinates=>'absolute',zeroes=>'Leading',nf1=>'6',nf2=>'6',x_anchor=>'0',y_anchor=>'0',wheel=>'',x_offset=>'0',y_offset=>'0',line_units=>'mm',override_online=>'yes',film_size_cross_scan=>'0',film_size_along_scan=>'0',ds_model=>'RG6500');
	}
}

sub flatmpanel {
	if($currentStep eq 'mpanel') {
		$genesis->COM('copy_entity',type=>'step',source_job=>"$jobName",source_name=>'mpanel',dest_job=>"$jobName",dest_name=>'mpanel_1',dest_database=>'');
				$flatenStep = $currentStep;
				#$genesis->COM('open_job',job=>"$jobName");
				
				$genesis->COM ('set_step',name=>"$flatenStep");
				
			    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
							$totalRows = @{$genesis->{doinfo}{gROWname}};
									for ($count=0;$count<$totalRows;$count++) {
											if( $genesis->{doinfo}{gROWtype}[$count] ne "empty" ) {
														$rowName = ${$genesis->{doinfo}{gROWname}}[$count];
														$rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
														$rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
														$rowSide = ${$genesis->{doinfo}{gROWside}}[$count];

													if ($rowName ne "fr" && $rowName ne "v1" && $rowName ne "f" && $rowName ne "pc" && $rowName ne "ps") {
																push(@layersFlatten, $rowName );
													}
											}
									}
				foreach $oneLayer (@layersFlatten) {
					$genesis->COM('flatten_layer',source_layer=>"$oneLayer",target_layer=>"${oneLayer}_flat_");
				}
				foreach $oneLayer (@layersFlatten) {
					$genesis -> COM ('copy_layer',source_job=>"$jobName",source_step=>"$currentStep",source_layer=>"${oneLayer}_flat_",dest=>'layer_name',dest_layer=>"$oneLayer",mode=>'replace',invert=>'no');
					$genesis -> COM ('delete_layer',layer=>"${oneLayer}_flat_");
				}
  				$genesis->INFO(units=>'mm',entity_type => 'step',entity_path => "$jobName/$currentStep",data_type => 'NUM_SR');
			    	    $numStepMpanel = $genesis->{doinfo}{gNUM_SR};
			    	      		for($z=1;$z<=$numStepMpanel;$z++) {
  						 			$genesis->COM('sr_tab_del',line=>'1');
  						 		}
	}
}
sub okolilaser {
				#$genesis->COM('open_job',job=>"$jobName");
				$genesis->COM ('set_step',name=>"$StepNameSemach");

				$genesis -> COM('copy_layer',source_job=>"$jobName",source_step=>"$StepNameSemach",source_layer=>"$layerToPanel",dest=>'layer_name',dest_layer=>'_t',mode=>'replace',invert=>'no');
				$genesis -> COM('editor_page_close');
				
				$genesis->COM ('set_step',name=>"$panelStepName");
				$genesis -> PAUSE('Zkontroluj zkopirovani pads');
			    
			    $genesis -> COM('display_layer',name=>'_t',display=>'yes',number=>'1');
				$genesis -> COM('work_layer',name=>'_t');
		 		$genesis -> COM('add_pad',attributes=>'no',x=>"$largeXstart",y=>"$largeYbottom",symbol=>"$largeHole",polarity=>'positive',angle=>0,mirror=>'no',nx=>"$largeNumX",ny=>1,dx=>"$largeDistX",dy=>0,xscale=>1,yscale=>1);
				$genesis -> COM('add_pad',attributes=>'no',x=>"$largeXstart",y=>"$largeYtop",symbol=>"$largeHole",polarity=>'positive',angle=>0,mirror=>'no',nx=>"$largeNumX",ny=>1,dx=>"$largeDistX",dy=>0,xscale=>1,yscale=>1);	        
				$genesis -> COM ('add_text',attributes=>'no',type=>'string',x=>'20',y=>'2.80',text=>"\u$jobName",x_size=>'5.08',y_size=>'5.08',w_factor=>'2',polarity=>'positive',angle=>'0',mirror=>'no',fontname=>'standard',ver=>'1');
				$genesis -> COM('profile_to_rout',layer=>'_t',width=>'300');
				$genesis -> COM('zoom_home');
}