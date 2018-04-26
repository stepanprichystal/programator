#!/usr/bin/perl
#####################################################################
#   Script Name         :   plot.pl		              		 		#
#   Version             :   2.0                     		 		#
#   Prerequisites       :   Needs panel schemes and    		 		#
#                           symbols                 		 		#
#   Last Modification   :   18.4.11 Kontrola kompenzaci v opfx file	#
# 	made modification   :   RVI								 		#
#####################################################################
use Genesis;
use Tk;
use Tk::BrowseEntry;
use Tk::LabEntry;
use Time::localtime;
use untilityScript;
#
#	Set basic variables
#
my $scriptVersion = 2.00;
my $jobName = "$ENV{JOB}";
my $stepAttention = "$ENV{STEP}";
my $panelStepName = "panel";
my $patternPanelStepName = "pattern_panel";
my $logoDir = "$ENV{GENESIS_DIR}/sys/scripts";
my $genesis = new Genesis;
my $filmSizeX = 610;
my $filmSizeY = 508;
my $filmCode = "24x16";
my $archivePath = "r:/Archiv";
my $sendToPlotter = "yes";
my $sendToArchive = "yes";
 $valuePad = 5001;
 $valuePadKom = 0;
 $valueLine = 5001;
 $valueLineKom = 0;
my $error = ' ERROR ' x 3;
my $logo_way = "$ENV{'GENESIS_DIR'}/sys/scripts/gatema/error.gif"; 
my $ploterPoslat = 1;


# Prepocet cesty Exportu
my $pathTmp = getPath ($jobName);
my $plotArchive = "$pathTmp/Zdroje";
#


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
	$gatema_logo = $main->Label(-text=>"Gatema Logo")->grid(-column=>0,-row=>0,-columnspan=>1,-sticky=>"news");
        if (-e "$logoDir/gatema_logo.gif") {
            $gatema_img = $gatema_logo->Photo( 'IMG1', -file =>"$logoDir/gatema_logo.gif" );
            $gatema_logo->configure(-image=>$gatema_img);
        }
	$main_title = $main->Label(-text=>"Gatema Plotting Script")->grid(-column=>1,-row=>0,-sticky=>"news");
	$main_title->configure(-font=>'helvetica 16 bold');
	$status = $main->Label(-textvariable=>\$status_label,-fg=>"black",-bg=>"red")->grid(-column=>0,-row=>2,-sticky=>"ew",-columnspan=>2);
	$status->configure(-font=>'helvetica 16 bold');
	$status_label = sprintf "YOU MUST BE IN A JOB TO RUN SCRIPT";
	$main->Button(-text=>"CLOSE AND QUIT",-command=>\&exit_script)->grid(-column=>0,-row=>3,-sticky=>"ew",-columnspan=>2);
	$main->waitWindow;
	exit (0);
}

$genesis->INFO(entity_type=>"step",entity_path=>"$jobName/$panelStepName",data_type=>'exists');
my $stdPanelExists = $genesis->{doinfo}{gEXISTS};
$genesis->INFO(entity_type=>"step",entity_path=>"$jobName/$patternPanelStepName",data_type=>'exists');
my $patternPanelExists = $genesis->{doinfo}{gEXISTS};
if ($stdPanelExists eq "yes" && $patternPanelExists eq "yes") {
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
	$gatema_logo = $main->Label(-text=>"Gatema Logo")->grid(-column=>0,-row=>0,-columnspan=>1,-sticky=>"news");
        if (-e "$logoDir/gatema_logo.gif") {
            $gatema_img = $gatema_logo->Photo( 'IMG1', -file =>"$logoDir/gatema_logo.gif" );
            $gatema_logo->configure(-image=>$gatema_img);
        }
	$main_title = $main->Label(-text=>"Gatema Plotting Script")->grid(-column=>1,-row=>0,-sticky=>"news",-columnspan=>2);
	$main_title->configure(-font=>'helvetica 16 bold');
	$status = $main->Label(-textvariable=>\$status_label,-fg=>"black",-bg=>"yellow")->grid(-column=>0,-row=>2,-sticky=>"news",-columnspan=>1);
	$main->Checkbutton(-text=>"Panel",-variable=>\$panelSelect,-onvalue=>"panel")->grid(-column=>1,-row=>2,-sticky=>"news",-columnspan=>1);
	$main->Checkbutton(-text=>"Pattern",-variable=>\$panelSelect,-onvalue=>"pattern")->grid(-column=>2,-row=>2,-sticky=>"news",-columnspan=>1);

	$status_label = sprintf "Choose panel step to plot";
	$main->Button(-text=>"Plot Selected",-command=>\&plot_selected_panel)->grid(-column=>0,-row=>51,-sticky=>"news",-columnspan=>3);
	$main->waitWindow;
} elsif ($stdPanelExists ne "yes" && $patternPanelExists eq "yes") {
	$panelStepName = $patternPanelStepName;
}
#
#	Gather basic info about job
#
$genesis->INFO('units'=>'mm','entity_type'=>'step','entity_path'=>"$jobName/$panelStepName",'data_type'=>'PROF_LIMITS');
my $panelXmax = $genesis->{doinfo}{gPROF_LIMITSxmax};
my $panelXmin = $genesis->{doinfo}{gPROF_LIMITSxmin};
my $panelYmax = $genesis->{doinfo}{gPROF_LIMITSymax};
my $panelYmin = $genesis->{doinfo}{gPROF_LIMITSymin};

my $panelXsize = sprintf "%3.0f",($panelXmax - $panelXmin);
my $panelYsize = sprintf "%3.0f",($panelYmax - $panelYmin);
my $panelCentreX = ($panelYmin + ($panelXsize / 2));
my $panelCentreY = ($panelXmin + ($panelYsize / 2));
my $panelLeft = $panelXmin;
my $panelRight = ($panelXmin + $panelXsize);
my $panelBottom = $panelYmin;
my $panelTop = ($panelYmin + $panelYsize);
my @boardList = get_board_layers($jobName);

#
#	Present main GUI for user 
#
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
$main->geometry('+100+0');
$main->gridColumnconfigure(0,-minsize=>150);
$main->gridColumnconfigure(1,-minsize=>150);
$main->gridColumnconfigure(2,-minsize=>150);
$main->gridColumnconfigure(3,-minsize=>150);

$logo_frame = $main->Frame()->grid(-column=>0,-row=>0,-sticky=>"ew",-columnspan=>6);
$gatema_logo = $logo_frame->Label(-text=>"Gatema Logo")->grid(-column=>0,-row=>0,-columnspan=>1,-sticky=>"news");
if (-e "$logoDir/gatema_logo.gif") {
    $gatema_img = $gatema_logo->Photo( 'IMG1', -file =>"$logoDir/gatema_logo.gif" );
    $gatema_logo->configure(-image=>$gatema_img);
}
$main_title = $logo_frame->Label(-text=>"Gatema Plotting Script")->grid(-column=>0,-row=>0,-sticky=>"news");
$main_title->configure(-font=>'helvetica 16 bold');
$main->Label(-text=>"Reference : ")->grid(-column=>0,-row=>1,-sticky=>"news",-columnspan=>3);
$main->Label(-text=>"$jobName",-relief=>"sunken")->grid(-column=>3,-row=>1,-sticky=>"news",-columnspan=>3);
$main->Label(-text=>"Step : ")->grid(-column=>0,-row=>2,-sticky=>"news",-columnspan=>3);
$main->Label(-text=>"$panelStepName",-relief=>"sunken")->grid(-column=>3,-row=>2,-sticky=>"news",-columnspan=>3);
#$main->Label(-text=>"Step : ")->grid(-column=>0,-row=>2,-sticky=>"news",-columnspan=>3);

#$main->Label(-text=>"Enlarge pads under (um)",-fg=>'red')         ->grid(-column=>0,-row=>3,-sticky=>"news",-columnspan=>2);
$main->Label(-text=>"Enlarge lines, pads and surface",-fg=>'red')          ->grid(-column=>0,-row=>4,-sticky=>"news",-columnspan=>3);


#$main->Label(-text=>"By (um)",-fg=>'red')          ->grid(-column=>3,-row=>3,-sticky=>"news",-columnspan=>2);
$main->Label(-text=>"By (um)",-fg=>'red')         ->grid(-column=>3,-row=>4,-sticky=>"news",-columnspan=>1);


#$pad_kompen = $main->Entry(-width=>10)      ->grid(-column=>2,-row=>3,-sticky=>"news",-columnspan=>1);
#$pad_kompen->insert('end',"$valuePad");
#$pad_kompen_value = $main->Entry(-width=>10)->grid(-column=>5,-row=>3,-sticky=>"news",-columnspan=>1);
#$pad_kompen_value->insert('end',"$valuePadKom");
#$line_kompen = $main->Entry(-width=>10)     ->grid(-column=>2,-row=>4,-sticky=>"news",-columnspan=>1);
#$line_kompen->insert('end',"$valueLine");
$line_kompen_value = $main->Entry(-width=>10)->grid(-column=>4,-row=>4,-sticky=>"news",-columnspan=>2);
$line_kompen_value->insert('end',"$valueLineKom");

$main->Checkbutton(-variable=>\$ploterPoslat,-text=>"Data jen do archivu",-fg=>"blue")->grid(-column=>0,-row=>5,-sticky=>"news",-columnspan=>3);
$film_entry = $main->BrowseEntry(-variable=>\$filmCode,-label=>"FILM",-fg=>"blue",-listcmd=>\&fill_film_list,-state=>"readonly")->grid(-column=>3,-row=>5,-sticky=>"news",-columnspan=>3);


$main->Label(-text=>"Layer Name")->grid(-column=>0,-row=>6,-sticky=>"news",-columnspan=>1);
$main->Label(-text=>"Plot Polarity")->grid(-column=>1,-row=>6,-sticky=>"news",-columnspan=>1);
$main->Label(-text=>"Emulsion")->grid(-column=>2,-row=>6,-sticky=>"news",-columnspan=>1);
$main->Label(-text=>"Stretch X Axis")->grid(-column=>3,-row=>6,-sticky=>"news",-columnspan=>1);
$main->Label(-text=>"Stretch Y Axis")->grid(-column=>4,-row=>6,-sticky=>"news",-columnspan=>1);
$main->Label(-text=>"Plot Layer")->grid(-column=>5,-row=>6,-sticky=>"news",-columnspan=>1);



my $rowCount = 10;
foreach my $boardLayer (@boardList) {
	$main->Label(-text=>"$boardLayer")->grid(-column=>0,-row=>"$rowCount",-sticky=>"news",-columnspan=>1);
	${$boardLayer._polarity_button} = $main->Button(-text=>"$currentPlotPolarity",-command=>[\&change_plot_polarity,"$boardLayer"])->grid(-column=>1,-row=>"$rowCount",-sticky=>"news",-columnspan=>1);
	${$boardLayer._mirror_button} = $main->Button(-text=>"$currentPlotMirror",-command=>[\&change_plot_mirror,"$boardLayer"])->grid(-column=>2,-row=>"$rowCount",-sticky=>"news",-columnspan=>1);
	${$boardLayer._stretchx} = $main->Entry(-width=>10)->grid(-column=>3,-row=>"$rowCount",-sticky=>"news",-columnspan=>1);
	${$boardLayer._stretchy} = $main->Entry(-width=>10)->grid(-column=>4,-row=>"$rowCount",-sticky=>"news",-columnspan=>1);
	${$boardLayer._plot} = $main->Checkbutton(-variable=>\${$boardLayer.PlotCheck})->grid(-column=>5,-row=>"$rowCount",-sticky=>"news",-columnspan=>1);
	get_layer_params($boardLayer);
	$rowCount ++;
}

	if ($stepAttention ne 'panel') {
			my $status = $main->Label(-textvariable=>\$statusLabel,-fg=>"white",-bg=>"red")->grid(-column=>0,-row=>50,-sticky=>"news",-columnspan=>6);
			$statusLabel = sprintf "$error Nepokracuj! Neni aktivni step - Panel $error";
			$statusDisable = 'disable';
	}else{
			my $status = $main->Label(-textvariable=>\$statusLabel,-fg=>"black",-bg=>"yellow")->grid(-column=>0,-row=>50,-sticky=>"news",-columnspan=>6);
			$statusLabel = sprintf "Please select parameters then continue";
			$statusDisable = 'normal';
	}

$main->Button(-text=>"Plot Selected",-command=>\&plot_selected_layers,-state=>"$statusDisable")->grid(-column=>0,-row=>51,-sticky=>"news",-columnspan=>3);
$main->Button(-text=>"Close and Quit",-command=>\&exit_script)->grid(-column=>3,-row=>51,-sticky=>"news",-columnspan=>3);


$main->waitWindow;
exit (0);

sub fill_film_list {
    $film_entry->delete(0,'end');
    foreach my $filmName (qw /24x16 24x20/) {
        $film_entry->insert('end',"$filmName");
    }
}

sub get_layer_params {
	#
	#	Retrieve production parameters for given layer
	#
	my $layerName = shift;
	$genesis->INFO(units=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$panelStepName/$layerName",'data_type'=>'LPM');
	@tempList = @{$genesis->{doinfo}{gLPMymirror}};
	my $currentMirror = $tempList[0];
	@tempList = @{$genesis->{doinfo}{gLPMpolarity}};
	my $currentPolarity = $tempList[0];
	@tempList = @{$genesis->{doinfo}{gLPMxstretch}};
	my $currentStretchX = $tempList[0] + 0.013;
	@tempList = @{$genesis->{doinfo}{gLPMystretch}};
	my $currentStretchY = $tempList[0] + 0.013;
	@tempList = @{$genesis->{doinfo}{gLPMswap_axes}};
	my $currentSwap = $tempList[0];
	${$layerName._polarity_button}->configure(-text=>"$currentPolarity");
	${$layerName._polarity_button}->update;
	${$layerName._stretchx}->delete(0,"end");
	${$layerName._stretchx}->insert("end","$currentStretchX");
	${$layerName._stretchy}->delete(0,"end");
	${$layerName._stretchy}->insert("end","$currentStretchY");
	if ($currentSwap eq "no_swap") {
		if ($currentMirror == 0) {
			${$layerName._mirror_button}->configure(-text=>"Up");
			${$layerName._mirror_button}->update;
		} elsif ($currentMirror != 0) {
			${$layerName._mirror_button}->configure(-text=>"Down");
			${$layerName._mirror_button}->update;
		}
	} else {
		if ($currentMirror == 0) {
			${$layerName._mirror_button}->configure(-text=>"Down");
			${$layerName._mirror_button}->update;
		} elsif ($currentMirror != 0) {
			${$layerName._mirror_button}->configure(-text=>"Up");
			${$layerName._mirror_button}->update;
		}
	}
}
sub get_board_layers {
    my $jobName = shift;
	my @boardList;
    $genesis->INFO('entity_type'=>'matrix','entity_path'=>"$jobName/matrix",'data_type'=>'ROW');
    my $totalRows = ${$genesis->{doinfo}{gROWrow}}[-1];
    for ($count=0;$count<=$totalRows;$count++) {
		my $rowFilled = ${$genesis->{doinfo}{gROWtype}}[$count];
		my $rowName = ${$genesis->{doinfo}{gROWname}}[$count];
		my $rowContext = ${$genesis->{doinfo}{gROWcontext}}[$count];
		my $rowType = ${$genesis->{doinfo}{gROWlayer_type}}[$count];
		my $rowSide = ${$genesis->{doinfo}{gROWside}}[$count];
		if ($rowFilled ne "empty" && $rowContext eq "board" && $rowType ne "drill" && $rowType ne "rout") {
			if ($panelStepName eq "panel") {
				push @boardList,$rowName;
			}
		} elsif ($rowFilled ne "empty" && ($rowName eq "sa" || $rowName eq "sb")) {
			if ($panelStepName eq "pattern_panel") {
				push @boardList,$rowName;
			}
		} elsif ($rowFilled ne "empty" && $rowName eq "ff") {
			if ($panelStepName eq "panel") {
				push @boardList,$rowName;
			}
		}
    }
    return (@boardList);
}
sub change_plot_polarity {
	#
	# Changes text on polarity button
	#
	my $layerName = shift;
	my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
	if ($currentPolarity eq "positive") {
		${$layerName._polarity_button}->configure(-text=>"negative");
		${$layerName._polarity_button}->update;
	} else {
		${$layerName._polarity_button}->configure(-text=>"positive");
		${$layerName._polarity_button}->update;
	}
	
}
sub change_plot_mirror {
	#
	# Changes text on layer side button
	#
	my $layerName = shift;
	my $currentSide = ${$layerName._mirror_button}->cget(-text);
	if ($currentSide eq "Up") {
		${$layerName._mirror_button}->configure(-text=>"Down");
		${$layerName._mirror_button}->update;
	} else {
		${$layerName._mirror_button}->configure(-text=>"Up");
		${$layerName._mirror_button}->update;
	}
	
}
sub exit_script {
	#
	#	Close the GUI and exit script
	#
	if ($main) {
		$main->destroy;
	}
	exit (0);
}
sub plot_selected_layers {
	
	if ($ploterPoslat == 1) {
			$sendToPlotter = "no";
	}else {
			$sendToPlotter = "yes";
	}
	
	
	#
	#	Will plot selected layers with parameters set
	#	Joining layers on 1 film
	#
	my $selectedCount = 0;
	foreach my $layerName (@boardList) {
		if (${$layerName.PlotCheck}) {
			$selectedCount ++;
		}
	}
	if ($selectedCount == 0) {
		$status_label = sprintf "NO LAYERS SELECTED FOR PLOTTING";
		$status->configure(-bg=>"red",-fg=>"black");
	} else {
		if ($panelXsize == 266 && $panelYsize == 308) {
			foreach my $layerName (@boardList) {
				if (${$layerName.PlotCheck}) {
					$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$panelStepName/$layerName",data_type=>'TYPE');
					if ($genesis->{doinfo}{gTYPE} ne "signal" && $genesis->{doinfo}{gTYPE} ne "mixed" && $genesis->{doinfo}{gTYPE} ne "power_ground") {
						my $joinTest = test_layer_for_join($jobName,$panelStepName,$layerName,"small");
						if ($joinTest eq "OK") {
							push @joinLayerList,$layerName;
						} else {
							my $currentEmulsion = ${$layerName._mirror_button}->cget(-text);
							my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
							my $currentStretchX = ${$layerName._stretchx}->get;
							my $currentStretchY = ${$layerName._stretchy}->get;
							plot_layer($layerName,$currentEmulsion,$currentPolarity,$currentStretchX,$currentStretchY);
						}
					} else {
						my $currentEmulsion = ${$layerName._mirror_button}->cget(-text);
						my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
						my $currentStretchX = ${$layerName._stretchx}->get;
						my $currentStretchY = ${$layerName._stretchy}->get;
						plot_layer($layerName,$currentEmulsion,$currentPolarity,$currentStretchX,$currentStretchY);
					}
				}
			}
			my $joinLayerCount = $#joinLayerList;
			$joinLayerCount ++;
			if ($joinLayerCount == 1) {
				foreach my $layerName (@boardList) {
					if (${$layerName.PlotCheck}) {
						my $currentEmulsion = ${$layerName._mirror_button}->cget(-text);
						my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
						my $currentStretchX = ${$layerName._stretchx}->get;
						my $currentStretchY = ${$layerName._stretchy}->get;
						plot_layer($layerName,$currentEmulsion,$currentPolarity,$currentStretchX,$currentStretchY);
					}
				}
			} elsif ($joinLayerCount > 1) {
				my $layersPlotted = 1;
				my $startLayerCount = 0;
				until ($startLayerCount == $joinLayerCount) {
					$layersPlotted = 0;
					my $layersJoined = 0;
					my $firstLayerName = $joinLayerList[$startLayerCount];
					my $firstStretchX = ${$firstLayerName._stretchx}->get;
					my $firstStretchY = ${$firstLayerName._stretchy}->get;
					my $firstPolarity = ${$firstLayerName._polarity_button}->cget(-text);
					my $firstEmulsion = ${$firstLayerName._mirror_button}->cget(-text);
					my $lastElementNumber = $#joinLayerList;
					for ($count=($startLayerCount + 1);$count<=$lastElementNumber;$count++) {
						my $secondLayerName = $joinLayerList[$count];
						my $secondStretchX = ${$secondLayerName._stretchx}->get;
						my $secondStretchY = ${$secondLayerName._stretchy}->get;
						if (($firstStretchX == $secondStretchX) && ($firstStretchY == $secondStretchY)) {
							$status_label = sprintf "Joining Layer $firstLayerName and $secondLayerName onto 1 film";
							$status->configure(-bg=>"green",-fg=>"black");
							$status->update;
							my $joinedLayerName = join_layer_pair($firstLayerName,$secondLayerName);
							plot_layer($joinedLayerName,$firstEmulsion,$firstPolarity,$firstStretchX,$firstStretchY);
							$layersJoined = 1;
							$layersPlotted = 2;
							$startLayerCount += 2;
							last;
						}
					}
					if ($layersJoined == 0) {
						plot_layer($firstLayerName,$firstEmulsion,$firstPolarity,$firstStretchX,$firstStretchY);
						$startLayerCount ++;
						$layersPlotted = 1;
					}
				}
			}
		} elsif ($panelXsize == 308 && $panelYsize == 355) {
			foreach my $layerName (@boardList) {
				if (${$layerName.PlotCheck}) {
					$genesis->INFO(entity_type=>"layer",entity_path=>"$jobName/$panelStepName/$layerName",data_type=>'TYPE');
					if ($genesis->{doinfo}{gTYPE} ne "signal" && $genesis->{doinfo}{gTYPE} ne "mixed" && $genesis->{doinfo}{gTYPE} ne "power_ground") {
						my $joinTest = test_layer_for_join($jobName,$panelStepName,$layerName,"medium");
						if ($joinTest eq "OK") {
							push @joinLayerList,$layerName;
						} else {
							my $currentEmulsion = ${$layerName._mirror_button}->cget(-text);
							my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
							my $currentStretchX = ${$layerName._stretchx}->get;
							my $currentStretchY = ${$layerName._stretchy}->get;
							plot_layer($layerName,$currentEmulsion,$currentPolarity,$currentStretchX,$currentStretchY);
						}
					} else {
						my $currentEmulsion = ${$layerName._mirror_button}->cget(-text);
						my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
						my $currentStretchX = ${$layerName._stretchx}->get;
						my $currentStretchY = ${$layerName._stretchy}->get;
						plot_layer($layerName,$currentEmulsion,$currentPolarity,$currentStretchX,$currentStretchY);
					}
				}
			}
			my $joinLayerCount = $#joinLayerList;
			$joinLayerCount ++;
			if ($joinLayerCount == 1) {
				foreach my $layerName (@boardList) {
					if (${$layerName.PlotCheck}) {
						my $currentEmulsion = ${$layerName._mirror_button}->cget(-text);
						my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
						my $currentStretchX = ${$layerName._stretchx}->get;
						my $currentStretchY = ${$layerName._stretchy}->get;
						plot_layer($layerName,$currentEmulsion,$currentPolarity,$currentStretchX,$currentStretchY);
					}
				}
			} elsif ($joinLayerCount > 1) {
				my $layersPlotted = 1;
				my $startLayerCount = 0;
				until ($startLayerCount == $joinLayerCount) {
					$layersPlotted = 0;
					my $layersJoined = 0;
					my $firstLayerName = $joinLayerList[$startLayerCount];
					my $firstStretchX = ${$firstLayerName._stretchx}->get;
					my $firstStretchY = ${$firstLayerName._stretchy}->get;
					my $firstPolarity = ${$firstLayerName._polarity_button}->cget(-text);
					my $firstEmulsion = ${$firstLayerName._mirror_button}->cget(-text);
					my $lastElementNumber = $#joinLayerList;
					for ($count=($startLayerCount + 1);$count<=$lastElementNumber;$count++) {
						my $secondLayerName = $joinLayerList[$count];
						my $secondStretchX = ${$secondLayerName._stretchx}->get;
						my $secondStretchY = ${$secondLayerName._stretchy}->get;
						if (($firstStretchX == $secondStretchX) && ($firstStretchY == $secondStretchY)) {
							$status_label = sprintf "Joining Layer $firstLayerName and $secondLayerName onto 1 film";
							$status->configure(-bg=>"green",-fg=>"black");
							$status->update;
							my $joinedLayerName = join_layer_pair_overlap($firstLayerName,$secondLayerName);
							plot_layer($joinedLayerName,$firstEmulsion,$firstPolarity,$firstStretchX,$firstStretchY);
							$layersJoined = 1;
							$layersPlotted = 2;
							$startLayerCount += 2;
							last;
						}
					}
					if ($layersJoined == 0) {
						plot_layer($firstLayerName,$firstEmulsion,$firstPolarity,$firstStretchX,$firstStretchY);
						$startLayerCount ++;
						$layersPlotted = 1;
					}
				}
			}
		} else {
			foreach my $layerName (@boardList) {
				if (${$layerName.PlotCheck}) {
					my $currentEmulsion = ${$layerName._mirror_button}->cget(-text);
					my $currentPolarity = ${$layerName._polarity_button}->cget(-text);
					my $currentStretchX = ${$layerName._stretchx}->get;
					my $currentStretchY = ${$layerName._stretchy}->get;
					plot_layer($layerName,$currentEmulsion,$currentPolarity,$currentStretchX,$currentStretchY);
				}
			}
		}
	}
}

sub plot_layer {
	my $layerName = shift;
	my $plotEmulsion = shift;
	my $plotPolarity = shift;
	my $plotStretchX = shift;
	my $plotStretchY = shift;
	$genesis->INFO(units=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$panelStepName/$layerName",'data_type'=>'LPM');
	@tempList = @{$genesis->{doinfo}{gLPMswap_axes}};
	my $currentSwap = $tempList[0];
	if ($currentSwap eq "no_swap") {
		if ($plotEmulsion eq "Up") {
			$plotMirror = 0;
		} else {
			$plotMirror = 1;
		}
	} else {
		if ($plotEmulsion eq "Up") {
			$plotMirror = 1;
		} else {
			$plotMirror = 0;
		}
	}
	#vymazani starych dat
	opendir (DATA,"$plotArchive");
	@data = readdir DATA;
	closedir DATA;
	foreach $one (@data) {
		$findIt = "${jobName}@"."$layerName";
		if ($one =~ /$findIt/) {
			unlink("$plotArchive/$one");
		}
	}
#	$padEnlarge = $pad_kompen->get;
#	$linEnlarge = $line_kompen->get;
#	$enlargePad = $pad_kompen_value->get;
	$enlargePad_line = $line_kompen_value->get;

if ($enlargePad_line > 0) {	
	$padEnlarge = 99999;
	$linEnlarge = 99999;
	$enlargePad = $enlargePad_line;
	$enlargeContour = $enlargePad_line;
	
}else{
	$padEnlarge = 0;
	$linEnlarge = 0;
	$enlargePad = 0;
	$enlargeContour = 0
}		

$genesis->COM('set_attribute',type=>'layer',job=>"$jobName",name1=>"$panelStepName",name2=>"$layerName",name3=>'',attribute=>"kompenzace",value=>"$enlargePad",units=>'mm');

	
	$genesis->COM('image_set_elpd2',job=>"$jobName",step=>"$panelStepName",layer=>"$layerName",device_type=>'LP7008',polarity=>"$plotPolarity",speed=>0,xstretch=>"$plotStretchX",ystretch=>"$plotStretchY",xshift=>0,yshift=>0,xmirror=>0,ymirror=>"$plotMirror",copper_area=>0,xcenter=>0,ycenter=>0,plot_kind1=>56,plot_kind2=>56,minvec=>"$linEnlarge",advec=>"$enlargePad_line",minflash=>"$padEnlarge",adflash=>"$enlargePad",conductors1=>0,conductors2=>0,conductors3=>0,conductors4=>0,conductors5=>0,media=>'first',smoothing=>'smooth',swap_axes=>"$currentSwap",define_ext_lpd=>'yes',resolution_value=>0.25,resolution_units=>'mil',quality=>'auto',enlarge_polarity=>'positive',enlarge_other=>'leave_as_is',enlarge_panel=>'no',enlarge_contours_by=>"$enlargeContour",overlap=>'no',enlarge_image_symbols=>'no',enlarge_0_vecs=>'no',enlarge_symbols=>'all',enlarge_symbols_by=>"$enlargePad",symbol_name1=>'',enlarge_by1=>0,symbol_name2=>'',enlarge_by2=>0,symbol_name3=>'',enlarge_by3=>0,symbol_name4=>'',enlarge_by4=>0,symbol_name5=>'',enlarge_by5=>0,symbol_name6=>'',enlarge_by6=>0,symbol_name7=>'',enlarge_by7=>0,symbol_name8=>'',enlarge_by8=>0,symbol_name9=>'',enlarge_by9=>0,symbol_name10=>'',enlarge_by10=>0);


	$genesis->COM('output_layer_reset');
	$genesis->COM('output_layer_set',layer=>"$layerName",angle=>0,mirror=>'no',x_scale=>1,y_scale=>1,comp=>0,polarity=>'positive',setupfile=>'',setupfiletmp=>'',line_units=>'mm',gscl_file=>'');
	$genesis->COM('output',job=>"$jobName",step=>"$panelStepName",format=>'LP7008',dir_path=>"$plotArchive",prefix=>'',suffix=>'',break_sr=>'yes',break_symbols=>'no',break_arc=>'no',scale_mode=>'all',surface_mode=>'contour',units=>'mm',x_anchor=>0,y_anchor=>0,x_offset=>0,y_offset=>0,line_units=>'mm',override_online=>'yes',film_size=>"$filmCode",local_copy=>"$sendToArchive",send_to_plotter=>"$sendToPlotter",plotter_group=>"imager6",units_factor=>0.1,auto_purge=>'no',entry_num=>4,plot_copies=>1,imgmgr_name=>'',deliver_date=>'',plot_mode=>'single');

########################################### kontrola kompenyaci v souboru
$JmenoMotivu = $layerName;
$fileCompen = shift;
@dataF = '';
$oneF = shift;
@fieldsF ='';

	opendir (DRILL,"$plotArchive");
	@dataF = readdir DRILL;
	closedir DRILL;
			foreach $oneF (@dataF) {
			$findItF = "${jobName}@"."$JmenoMotivu";
				if ($oneF =~ /$findItF/) {
						open (USERNIF,"$plotArchive/$oneF");
		 				while (<USERNIF>) {
		 	   				if ($_ =~ /ENLARGE LINE,ARC UNDER/) {
		 	   					@fieldsF = split /\s/,$_;
		 	   					$fileCompen = ($fieldsF[5]/10);
		 	   				}
		 	   			}
				}
			}
					unless ($fileCompen == $enlargePad) {	
							$mainMain = MainWindow->new();
							$topmain = $mainMain->Frame(-width=>10, -height=>20)->pack(-side=>'top');
							$botmain = $mainMain->Frame(-width=>10, -height=>20)->pack(-side=>'bottom');
							$main = $topmain->Frame(-width=>10, -height=>20)->pack(-side=>'right');
							$logomain = $topmain->Frame(-width=>10, -height=>20)->pack(-side=>'left');
							$radek1 = $main->Message(-justify=>'center', -aspect=>5000, -text=>"Pruser, kompenzace, ktere jsou zadane od tebe, se neshoduji v opfx souboru,Zastav vykresleni techto filmu a posli to tam znovu.");
							$radek1->pack();
							$radek1->configure(-font=>'times 12 bold');
							$logo_frame = $logomain->Frame(-width=>50, -height=>50)->pack(-side=>'left');
							$error_logo = $logo_frame->Photo(-file=>"$logo_way");
							$logo_frame->Label(-image=>$error_logo)->pack();
							$button = $botmain ->Button(-text=>'konec',-command=>\&konec)->pack(-padx=>5,-pady=>5);
							$mainMain->waitVisibility;
							$mainMain->waitWindow;
					}
###############################################################################
	
}

		

sub konec {
	exit;
}
sub join_layer_pair {
	#
	#	Joins 2 layers together on 1 film
	#	Needs 2 layer names
	#
	my $firstLayerName = shift;
	my $secondLayerName = shift;
	my $joinedLayerName = "${firstLayerName}+${secondLayerName}";
	my $firstEmulsion = ${$firstLayerName._mirror_button}->cget(-text);
	my $firstPolarity = ${$firstLayerName._polarity_button}->cget(-text);
	my $secondEmulsion = ${$firstLayerName._mirror_button}->cget(-text);
	my $secondPolarity = ${$firstLayerName._polarity_button}->cget(-text);
    $genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$panelStepName",iconic=>'no');
    $genesis->AUX('set_group', group => $genesis->{COMANS});
    $genesis->COM('units',type=>'mm');
    $genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
	
	if ($firstPolarity eq "positive") {
		$drawPolarity = "positive";
		$fillPolarity = "negative";
	} else {
		$drawPolarity = "negative";
		$fillPolarity = "positive";
	}
	if ($firstPolarity eq "negative") {
		$genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$panelStepName/$firstLayerName",'data_type'=>'LIMITS');
		$genesis->COM('flatten_layer',source_layer=>"$firstLayerName",target_layer=>"__first_flat__");
		$genesis->COM('create_layer',layer=>"$joinedLayerName",context=>'misc',type=>'signal',polarity=>'positive',ins_layer=>"");
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");
		$genesis->COM('fill_params',type=>'solid',origin_type=>'datum',solid_type=>'surface',min_brush=>2.0325,use_arcs=>'yes',symbol=>'',dx=>2.54,dy=>2.54,break_partial=>'yes',cut_prims=>'no',outline_draw=>'no',outline_width=>0,outline_invert=>'no');
		$genesis->COM('add_surf_strt');
		$genesis->COM('add_surf_poly_strt',x=>"$genesis->{doinfo}{gLIMITSxmin}",y=>"$genesis->{doinfo}{gLIMITSymin}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmax}",y=>"$genesis->{doinfo}{gLIMITSymin}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmax}",y=>"$genesis->{doinfo}{gLIMITSymax}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmin}",y=>"$genesis->{doinfo}{gLIMITSymax}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmin}",y=>"$genesis->{doinfo}{gLIMITSymin}");
		$genesis->COM('add_surf_poly_end');
		$genesis->COM('add_surf_end',attributes=>'no',polarity=>'positive');
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
		$genesis->COM('merge_layers',source_layer=>"__first_flat__",dest_layer=>"$joinedLayerName",invert=>'yes');
		$genesis->COM('delete_layer',layer=>"__first_flat__");
	} else {
		$genesis->COM('flatten_layer',source_layer=>"$firstLayerName",target_layer=>"$joinedLayerName");
	}
	$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");

	if ($firstEmulsion eq "Up") {
		$genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$panelStepName/$firstLayerName",'data_type'=>'LIMITS');
		my $moveDistance = (-3 - $panelXsize);
		$genesis->COM('sel_move',dx=>"$moveDistance",dy=>0);
	} else {
		$genesis->COM('sel_transform',mode=>'anchor',oper=>'mirror',duplicate=>'no',x_anchor=>0,y_anchor=>0,angle=>0,x_scale=>1,y_scale=>1,x_offset=>0,y_offset=>0);
		my $layerXshift = ( -3 + ( 2 * ($panelLeft + $panelXsize)));
		$genesis->COM('sel_move',dx=>"$layerXshift",dy=>0);
	}
	$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
	if ($secondPolarity eq "negative") {
		$genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$panelStepName/$secondLayerName",'data_type'=>'LIMITS');
		$genesis->COM('flatten_layer',source_layer=>"$secondLayerName",target_layer=>"__second_flat__");
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");
		$genesis->COM('fill_params',type=>'solid',origin_type=>'datum',solid_type=>'surface',min_brush=>2.0325,use_arcs=>'yes',symbol=>'',dx=>2.54,dy=>2.54,break_partial=>'yes',cut_prims=>'no',outline_draw=>'no',outline_width=>0,outline_invert=>'no');
		$genesis->COM('add_surf_strt');
		$genesis->COM('add_surf_poly_strt',x=>"$genesis->{doinfo}{gLIMITSxmin}",y=>"$genesis->{doinfo}{gLIMITSymin}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmax}",y=>"$genesis->{doinfo}{gLIMITSymin}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmax}",y=>"$genesis->{doinfo}{gLIMITSymax}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmin}",y=>"$genesis->{doinfo}{gLIMITSymax}");
		$genesis->COM('add_surf_poly_seg',x=>"$genesis->{doinfo}{gLIMITSxmin}",y=>"$genesis->{doinfo}{gLIMITSymin}");
		$genesis->COM('add_surf_poly_end');
		$genesis->COM('add_surf_end',attributes=>'no',polarity=>'positive');
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
	} else {
		$genesis->COM('flatten_layer',source_layer=>"$secondLayerName",target_layer=>"__second_flat__");
	}

	$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"yes");
	if ($secondPolarity eq "positive") {
		$drawPolarity = "positive";
		$fillPolarity = "negative";
		$mergePolarity = 'no';
	} else {
		$drawPolarity = "negative";
		$fillPolarity = "positive";
		$mergePolarity = 'yes';
	}
	if ($secondEmulsion eq "Up") {
		$genesis->COM('merge_layers',source_layer=>"__second_flat__",dest_layer=>"$joinedLayerName",invert=>"$mergePolarity");
	} else {
		$genesis->COM('sel_transform',mode=>'anchor',oper=>'mirror',duplicate=>'no',x_anchor=>0,y_anchor=>0,angle=>0,x_scale=>1,y_scale=>1,x_offset=>0,y_offset=>0);
		$genesis->COM('sel_move',dx=>"$panelXsize",dy=>0);
		$genesis->COM('merge_layers',source_layer=>"__second_flat__",dest_layer=>"$joinedLayerName",invert=>"$mergePolarity");
	}
	$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"no");
	$genesis->COM('delete_layer',layer=>"__second_flat__");
    $genesis->COM('editor_page_close');

	return ($joinedLayerName);
}
sub plot_selected_panel {
	if ($panelSelect eq "pattern") {
		$panelStepName = $patternPanelStepName;
	}
	if ($main) {
		$main->destroy;
	}
}

sub test_layer_for_join {
	my $jobName = shift;
	my $stepName = shift;
	my $layerName = shift;
	my $layerSize = shift;
	my $panelXsize;
	my $panelYsize;
	if ($layerSize eq "small") {
		$panelXsize = 267;
		$panelYsize = 309;
	} else {
		$panelXsize = 309;
		$panelYsize = 356;
	}

	$genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$stepName/$layerName",'data_type'=>'LIMITS');
	my $layerXsize = ($genesis->{doinfo}{gLIMITSxmax} - $genesis->{doinfo}{gLIMITSxmin});
	my $layerYsize = ($genesis->{doinfo}{gLIMITSymax} - $genesis->{doinfo}{gLIMITSymin});
	if ($layerXsize > $panelXsize || $layerYsize > $panelYsize) {
		return ("BAD");
	} else {
		return ("OK");
	}
}
sub join_layer_pair_overlap {
	#
	#	Joins 2 layers together on 1 film
	#	Needs 2 layer names
	#
	my $firstLayerName = shift;
	my $secondLayerName = shift;
	my $joinedLayerName = "${firstLayerName}+${secondLayerName}";
	my $firstEmulsion = ${$firstLayerName._mirror_button}->cget(-text);
	my $firstPolarity = ${$firstLayerName._polarity_button}->cget(-text);
	my $secondEmulsion = ${$firstLayerName._mirror_button}->cget(-text);
	my $secondPolarity = ${$firstLayerName._polarity_button}->cget(-text);
    $genesis->COM('open_entity',job=>"$jobName",type=>'step',name=>"$panelStepName",iconic=>'no');
    $genesis->AUX('set_group', group => $genesis->{COMANS});
    $genesis->COM('units',type=>'mm');
    $genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
	
	if ($firstPolarity eq "positive") {
		$drawPolarity = "positive";
		$fillPolarity = "negative";
	} else {
		$drawPolarity = "negative";
		$fillPolarity = "positive";
	}
	if ($firstPolarity eq "negative") {
		$genesis->COM('flatten_layer',source_layer=>"$firstLayerName",target_layer=>"__first_flat__");
		$genesis->COM('affected_layer',name=>"__first_flat__",mode=>"single",affected=>"yes");
		$genesis->COM('sel_move',dx=>-4,dy=>0);
		remove_panel_border("__first_flat__");
		$genesis->COM('affected_layer',name=>"__first_flat__",mode=>"single",affected=>"no");
		$genesis->COM('create_layer',layer=>"$joinedLayerName",context=>'misc',type=>'signal',polarity=>'positive',ins_layer=>"");
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");
		$genesis->COM('fill_params',type=>'solid',origin_type=>'datum',solid_type=>'surface',min_brush=>2.0325,use_arcs=>'yes',symbol=>'',dx=>2.54,dy=>2.54,break_partial=>'yes',cut_prims=>'no',outline_draw=>'no',outline_width=>0,outline_invert=>'no');
		$genesis->COM('add_surf_strt');
		$genesis->COM('add_surf_poly_strt',x=>0,y=>0);
		$genesis->COM('add_surf_poly_seg',x=>300,y=>0);
		$genesis->COM('add_surf_poly_seg',x=>300,y=>355);
		$genesis->COM('add_surf_poly_seg',x=>0,y=>355);
		$genesis->COM('add_surf_poly_seg',x=>0,y=>0);
		$genesis->COM('add_surf_poly_end');
		$genesis->COM('add_surf_end',attributes=>'no',polarity=>'positive');
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
		$genesis->COM('merge_layers',source_layer=>"__first_flat__",dest_layer=>"$joinedLayerName",invert=>'yes');
		$genesis->COM('delete_layer',layer=>"__first_flat__");
	} else {
		$genesis->COM('flatten_layer',source_layer=>"$firstLayerName",target_layer=>"$joinedLayerName");
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");
		$genesis->COM('sel_move',dx=>-4,dy=>0);
		remove_panel_border("$joinedLayerName");
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
	}
	$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");

	if ($firstEmulsion eq "Up") {
		$genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$panelStepName/$firstLayerName",'data_type'=>'LIMITS');
		$genesis->COM('sel_move',dx=>300,dy=>0);
	} else {
		$genesis->COM('sel_transform',mode=>'anchor',oper=>'mirror',duplicate=>'no',x_anchor=>0,y_anchor=>0,angle=>0,x_scale=>1,y_scale=>1,x_offset=>0,y_offset=>0);
		$genesis->COM('sel_move',dx=>300,dy=>0);
	}
	$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
	if ($secondPolarity eq "negative") {
		$genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$panelStepName/$secondLayerName",'data_type'=>'LIMITS');
		$genesis->COM('flatten_layer',source_layer=>"$secondLayerName",target_layer=>"__second_flat__");
		$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"yes");
		$genesis->COM('sel_move',dx=>-4,dy=>0);
		remove_panel_border("__second_flat__");
		$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"no");
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");
		$genesis->COM('fill_params',type=>'solid',origin_type=>'datum',solid_type=>'surface',min_brush=>2.0325,use_arcs=>'yes',symbol=>'',dx=>2.54,dy=>2.54,break_partial=>'yes',cut_prims=>'no',outline_draw=>'no',outline_width=>0,outline_invert=>'no');
		$genesis->COM('add_surf_strt');
		$genesis->COM('add_surf_poly_strt',x=>0,y=>0);
		$genesis->COM('add_surf_poly_seg',x=>300,y=>0);
		$genesis->COM('add_surf_poly_seg',x=>300,y=>355);
		$genesis->COM('add_surf_poly_seg',x=>0,y=>355);
		$genesis->COM('add_surf_poly_seg',x=>0,y=>0);
		$genesis->COM('add_surf_poly_end');
		$genesis->COM('add_surf_end',attributes=>'no',polarity=>'positive');
		$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
	} else {
		$genesis->COM('flatten_layer',source_layer=>"$secondLayerName",target_layer=>"__second_flat__");
		$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"yes");
		$genesis->COM('sel_move',dx=>-4,dy=>0);
		remove_panel_border("__second_flat__");
		$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"no");
	}
	$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"yes");
	if ($secondPolarity eq "positive") {
		$drawPolarity = "positive";
		$fillPolarity = "negative";
		$mergePolarity = 'no';
	} else {
		$drawPolarity = "negative";
		$fillPolarity = "positive";
		$mergePolarity = 'yes';
	}
	if ($secondEmulsion eq "Up") {
		$genesis->COM('merge_layers',source_layer=>"__second_flat__",dest_layer=>"$joinedLayerName",invert=>"$mergePolarity");
	} else {
		$genesis->COM('sel_transform',mode=>'anchor',oper=>'mirror',duplicate=>'no',x_anchor=>0,y_anchor=>0,angle=>0,x_scale=>1,y_scale=>1,x_offset=>0,y_offset=>0);
		$genesis->COM('sel_move',dx=>300,dy=>0);
		$genesis->COM('merge_layers',source_layer=>"__second_flat__",dest_layer=>"$joinedLayerName",invert=>"$mergePolarity");
	}
	$genesis->COM('affected_layer',name=>"__second_flat__",mode=>"single",affected=>"no");
	$genesis->COM('delete_layer',layer=>"__second_flat__");
	$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"yes");
	$genesis->COM('add_polyline_strt');
	$genesis->COM('add_polyline_xy',x=>0,y=>0);
	$genesis->COM('add_polyline_xy',x=>300,y=>0);
	$genesis->COM('add_polyline_xy',x=>300,y=>355);
	$genesis->COM('add_polyline_xy',x=>0,y=>355);
	$genesis->COM('add_polyline_xy',x=>0,y=>0);
	$genesis->COM('add_polyline_end',attributes=>'no',symbol=>"r300",polarity=>"positive");
	$genesis->COM('add_polyline_strt');
	$genesis->COM('add_polyline_xy',x=>300,y=>0);
	$genesis->COM('add_polyline_xy',x=>600,y=>0);
	$genesis->COM('add_polyline_xy',x=>600,y=>355);
	$genesis->COM('add_polyline_xy',x=>300,y=>355);
	$genesis->COM('add_polyline_xy',x=>300,y=>0);
	$genesis->COM('add_polyline_end',attributes=>'no',symbol=>"r300",polarity=>"positive");
	$genesis->COM('affected_layer',name=>"$joinedLayerName",mode=>"single",affected=>"no");
	
    $genesis->COM('editor_page_close');

	return ($joinedLayerName);
}
sub remove_panel_border {
	my $layerName = shift;
	$genesis->COM('affected_layer',name=>"$layerName",mode=>"single",affected=>"yes");
	foreach my $symbolName (qw /mask_panel_edge_top mask_panel_edge_left mask_panel_edge_right mask_panel_edge_bot screen_panel_edge_top screen_panel_edge_left screen_panel_edge_right screen_panel_edge_bot/) {
		$genesis->COM('filter_reset',filter_name=>"popup");
		$genesis->COM('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.pnl_place',text=>"$symbolName");
		$genesis->COM('filter_area_strt');
		$genesis->COM('filter_area_end',layer=>'',filter_name=>'popup',operation=>'select',area_type=>'none',inside_area=>'no',intersect_area=>'yes',lines_only=>'no',ovals_only=>'no',min_len=>0,max_len=>0,min_angle=>0,max_angle=>0);
		$genesis->COM('get_select_count');
		if ($genesis->{COMANS}) {
			$genesis->COM('sel_delete');
		}
	}
	$genesis->COM('affected_layer',name=>"$layerName",mode=>"single",affected=>"no");
}
sub _SearchItemInNif {
		my $pathNif = shift;
		my $jobId = shift;
		my $item = shift;
		my $res = 0;
	
	open (AREA,"$pathNif/$jobId.nif");
            while (<AREA>) {
            	if ($_ =~ /$item=(\d)/) {
                            $res = $1;
                }
            }
	close AREA;
	return($res);
}