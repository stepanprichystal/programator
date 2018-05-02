#!/usr/bin/perl
#########################################################
#   Script Name         :   profile2tou.pl		#
#   Version             :   1.00                    	#
#   Prerequisites       :   Needs profile to be set	#
#   Last Modification   :   Initial Creation        	#
#########################################################
use Genesis;
use Tk;
use Tk::BrowseEntry;
use Tk::LabEntry;
use Time::localtime;

#
#	Set basic variables
#
my $scriptVersion = 1.00;
my $jobName = "$ENV{JOB}";
my $stepName = "$ENV{STEP}";
my $defaultWidth = 300;
my $genesis = new Genesis;
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
#
#	Prompt user when they are not in a job
#
unless ($stepName) {
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
	$status_label = sprintf "YOU MUST BE IN A STEP TO RUN SCRIPT";
	$main->Button(-text=>"CLOSE AND QUIT",-command=>\&exit_script)->grid(-column=>0,-row=>3,-sticky=>"ew",-columnspan=>2);
	$main->waitWindow;
	exit (0);
}
$genesis->INFO(entity_type => 'step',entity_path => "$jobName/$stepName",data_type => 'PROF_LIMITS');
if ($genesis->{doinfo}{gPROF_LIMITSxmin} == 0 && $genesis->{doinfo}{gPROF_LIMITSymin} == 0 && $genesis->{doinfo}{gPROF_LIMITSxmax} == 0 && $genesis->{doinfo}{gPROF_LIMITSymax} == 0) {
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
	$status_label = sprintf "THERE IS NO PROFILE TO ADD TO SOLDER MASKS";
	$main->Button(-text=>"CLOSE AND QUIT",-command=>\&exit_script)->grid(-column=>0,-row=>3,-sticky=>"ew",-columnspan=>2);
	$main->waitWindow;
	exit (0);
}

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

$logo_frame = $main->Frame()->grid(-column=>0,-row=>0,-sticky=>"ew",-columnspan=>2);
$gatema_logo = $logo_frame->Label(-text=>"Gatema Logo")->grid(-column=>0,-row=>0,-columnspan=>1,-sticky=>"news");
if (-e "$logoDir/gatema_logo.gif") {
    $gatema_img = $gatema_logo->Photo( 'IMG1', -file =>"$logoDir/gatema_logo.gif" );
    $gatema_logo->configure(-image=>$gatema_img);
}
$main_title = $logo_frame->Label(-text=>"Gatema Profile to Mask Script")->grid(-column=>0,-row=>0,-sticky=>"news");
$main_title->configure(-font=>'helvetica 16 bold');
$main->Label(-text=>"Line Width : ")->grid(-column=>0,-row=>1,-sticky=>"news",-columnspan=>1);
$line_width_entry = $main->Entry(-width=>10)->grid(-column=>1,-row=>1,-sticky=>"news",-columnspan=>1);
$line_width_entry->insert('end',"$defaultWidth");
my $status = $main->Label(-textvariable=>\$statusLabel,-fg=>"black",-bg=>"yellow")->grid(-column=>0,-row=>50,-sticky=>"news",-columnspan=>2);
$statusLabel = sprintf "Please select parameters then continue";

$main->Button(-text=>"Add Profile to Mask Layers",-command=>\&add_lines_to_mask)->grid(-column=>0,-row=>99,-sticky=>"news",-columnspan=>1);
$main->Button(-text=>"Close and Quit",-command=>\&exit_script)->grid(-column=>1,-row=>99,-sticky=>"news",-columnspan=>1);

$main->waitWindow;
exit (0);

sub exit_script {
	#
	#	Close the GUI and exit script
	#
	if ($main) {
		$main->destroy;
	}
	exit (0);
}
sub add_lines_to_mask {
	$status->configure(-bg=>'green');
	$main->update;
	$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
	$genesis->COM('clear_layers');
	$genesis->COM('units',type=>'mm');
	
	my $currentLineWidth = $line_width_entry->get;
	if (($currentLineWidth <= 50 || $currentLineWidth >= 1000) || $currentLineWidth !~ /[0-9]+/) {
		$statusLabel = sprintf "ILLEGAL LINE WIDTH ENTERED";
		$status->configure(-bg=>'red');
		$main->update;
		return;
	}
	$genesis->INFO('units'=>'mm','entity_type'=>'layer','entity_path'=>"$jobName/$stepName/__profile_for_mask__",'data_type'=>'exists');
	if ($genesis->{doinfo}{gEXISTS} eq "yes") {
		$genesis->COM('delete_layer',layer=>"__profile_for_mask__");
	}
	$genesis->COM('create_layer',layer=>"__profile_for_mask__",context=>'misc',type=>'document',polarity=>'positive',ins_layer=>'');
	$genesis->COM('affected_filter',filter=>"(type=solder_mask&context=board)");
	$genesis->COM('get_affect_layer');
	
	my @layerList = split /\s+/,$genesis->{COMANS};
	my $layerCount = @{layerList};
	if ($layerCount == 0) {
		$statusLabel = sprintf "NO SOLDER MASKS IN JOB";
		$status->configure(-bg=>'red');
		$main->update;
		return;
	}
	$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
	$genesis->COM('profile_to_rout',layer=>'__profile_for_mask__',width=>"$currentLineWidth");
	$genesis->COM('display_layer',name=>'__profile_for_mask__',display=>'yes',number=>1);
	$genesis->COM('work_layer',name=>'__profile_for_mask__');
	$genesis->COM('affected_filter',filter=>"(type=solder_mask&context=board)");
	$genesis->COM('sel_copy_other',dest=>'affected_layers',target_layer=>'',invert=>'no',dx=>0,dy=>0,size=>0);

	$genesis->COM('delete_layer',layer=>"__profile_for_mask__");
	$genesis->COM('affected_layer',name=>"",mode=>"all",affected=>"no");
	
	$statusLabel = sprintf "PROFILE ADDED TO SOLDER MASKS";
	$status->configure(-bg=>'yellow');
	$main->update;

}
