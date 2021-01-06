#!/usr/bin/perl-w

use warnings;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use Archive::Zip;
use File::Find;
use Tk;
use Tk::LabFrame;
use utf8;
use Time::HiRes qw (sleep);
use XML::Simple;
use Data::Dumper;
use Time::localtime;
use Unicode::Normalize;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'HelperScripts::DirStructure';

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Drilling::FinishSizeHoles::SetHolesRun';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::ETesting::MoveElTests';
use aliased 'Packages::GuideSubs::Impedance::DoSetImpLines';
use aliased 'Packages::CAMJob::ViaFilling::PlugLayer';

use aliased 'Helpers::GeneralHelper';

use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Connectors::HeliosConnector::HelperWriter';

use aliased 'CamHelpers::CamCopperArea';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamDrilling';

use aliased 'Managers::MessageMngr::MessageMngr';

my $inCAM = InCAM->new();

my $importPath;

# Create dir structure needs to run InCAM
DirStructure->Create();

# Move el test to local disk
MoveElTests->Move();

##### GUI ###############################################################################
my $pathDisk     = 'r:/pcb';
my $customerPOOL = 0;
my $inputWindow  = MainWindow->new;
$inputWindow->minsize(qw(350 20));
$inputWindow->title('Input');

my $main = $inputWindow->Frame( -width => 100, -height => 80 )->pack( -side => 'top', -fill => 'both' );

my $mainSubFrameTop = $main->Frame( -width => 100, -height => 80 )->pack( -side => 'top', -fill => 'both' );

my $mainSubFrameTop_Left = $mainSubFrameTop->Frame( -width => 100, -height => 80 )->pack( -side => 'left', -fill => 'both', -expand => "True" );

my $tgzBttn =
  $mainSubFrameTop_Left->Button( -text => "Open *.tgz|*.zip ...", -font => 'normal 9 {bold }', -command => sub { MultiCustomer('open') } );
$tgzBttn->grid( -column => 0, -row => 1, -sticky => "news", -columnspan => 2, -ipady => 10, -pady => 10, -padx => 10 );

my $gerberBttn = $mainSubFrameTop_Left->Button( -text => "Open *.ger ...", -font => 'normal 9 {bold }', -command => sub { GerberCustomer('open') } );
$gerberBttn->grid( -column => 0, -row => 2, -sticky => "news", -columnspan => 2, -ipady => 10, -pady => 10, -padx => 10 );

my $odbBttn = $mainSubFrameTop_Left->Button( -text => "Open ODB folder", -font => 'normal 9 {bold }', -command => sub { ODBinputFolder('') } );
$odbBttn->grid( -column => 0, -row => 3, -sticky => "news", -columnspan => 2, -ipady => 10, -pady => 10, -padx => 10 );

my $mainSubFrameBot_Right = $mainSubFrameTop->Frame( -width => 100, -height => 80 )->pack( -side => 'right', -fill => 'both', -expand => "True" );

my $mainSubFrameBot_Right_Altium =
  $mainSubFrameBot_Right->Frame( -width => 100, -height => 80 )->pack( -side => 'bottom', -fill => 'both', -expand => "True" );

my $buttonFrameTop = $mainSubFrameBot_Right_Altium->Frame( -width => 100, -height => 80 )->pack( -side => 'top', -fill => 'both', -expand => "True" );
$buttonFrameTop->Checkbutton( -text => "Altium", -variable => \$customerPOOL, -onvalue => 'altium' )
  ->pack( -side => 'left', -fill => 'both', -pady => 10 );

my $mainSubFrameBot_Right_Pool =
  $mainSubFrameBot_Right->Frame( -width => 100, -height => 80 )->pack( -side => 'top', -fill => 'both', -expand => "True" );

my $buttonFrameBot =
  $mainSubFrameBot_Right_Altium->Frame( -width => 100, -height => 80 )->pack( -side => 'bottom', -fill => 'both', -expand => "True" );
$buttonFrameBot->Checkbutton( -text => "POOL data", -variable => \$customerPOOL, -onvalue => 'pool' )
  ->pack( -side => 'left', -fill => 'both', -pady => 10 );

my $mainSubFrameBot = $main->Frame( -width => 100, -height => 80 )->pack( -side => 'bottom', -fill => 'both' );

my $pathFrame = $mainSubFrameBot->Frame( -width => 100, -height => 80 )->pack( -side => 'top', -fill => 'both' );
$pathFrameLab = $pathFrame->LabFrame(
									  -label  => "Cesta",
									  -width  => 100,
									  -height => 150
  )->pack(
		   -side   => 'top',
		   -fill   => 'x',
		   -pady   => '10',
		   -expand => "True"
  );

$pathFrameLab->Radiobutton( -value => 'c:/pcb', -variable => \$pathDisk, -text => "c:/pcb" )
  ->grid( -column => 3, -row => 2, -sticky => "news", -columnspan => 1 );
$pathFrameLab->Radiobutton( -value => 'r:/pcb', -variable => \$pathDisk, -text => "r:/pcb" )
  ->grid( -column => 4, -row => 2, -sticky => "news", -columnspan => 1 );

my $exitBttn = $inputWindow->Button( -text => "Konec", -command => sub { exit } )->pack( -side => 'top', -fill => 'both' );

$inputWindow->waitWindow;

#############################################################################################

sub MultiCustomer {
	my $operat = shift;
	my $path;
	my @types = ( [ "zip,odb++", [qw/*.zip *.tgz/] ], [ "All files", '*' ] );
	if ( $operat eq 'open' ) {
		$path = $inputWindow->getOpenFile( -filetypes => \@types, -initialdir => "$pathDisk" );
	}

	unless ( -e $path ) {

		#new
		my @mess     = ("Chybí importní soubor!");
		my $messMngr = MessageMngr->new('');
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

		return ();
	}

	my ( $prefixDiskName, $bodyPath, $fileName, $suffixName, $jobName, $localFolder ) = _GetAttrFromPath($path);

	if ( $suffixName =~ /[Zz][Ii][Pp]/ ) {
		_ExtractZip( $path, $prefixDiskName, $bodyPath );
	}
	unless ( $prefixDiskName eq 'C:' ) {
		_MoveFolderToLocal( $prefixDiskName, $bodyPath, $jobName, $localFolder );
	}

	$importPath = _SearchTgz( $jobName, $localFolder );

	#print $importPath;

	# Check if jobName already exist;
	_CheckJobExist($jobName);

	my $hostName  = $ENV{HOST};
	my $reference = HegMethods->GetNumberOrder($jobName);
	HelperWriter->OnlineWrite_order( $reference, "zpracovava $hostName", "aktualni_krok" );

	$inCAM->COM( 'import_job', db => 'incam', path => "$importPath", name => "$jobName", analyze_surfaces => 'no' );
	$inCAM->COM( 'clipb_open_job', job => "$jobName", update_clipboard => 'view_job' );

	$inCAM->INFO( entity_type => 'job', entity_path => "$jobName", data_type => 'STEPS_LIST' );
	my @stepsArr = @{ $inCAM->{doinfo}{gSTEPS_LIST} };
	my $inputStep;
	unless ( scalar @stepsArr == 1 ) {
		$inputStep = _SelectInputStep(@stepsArr);

		foreach my $item (@stepsArr) {
			if ( $item =~ /[Pp]anel/ ) {
				my $panelName = $item;

				my @steps = CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobName );

				if ( scalar @steps ) {
					my $newName = 'mpanel';
					$inCAM->COM(
								 'rename_entity',
								 job      => "$jobName",
								 name     => "$panelName",
								 new_name => "$newName",
								 is_fw    => 'no',
								 type     => 'step',
								 fw_type  => 'form'
					);
				}
				else {
					# panel neobsahuje S&R
					$inCAM->COM(
								 'rename_entity',
								 job      => "$jobName",
								 name     => "input",
								 new_name => "input_ori",
								 is_fw    => 'no',
								 type     => 'step',
								 fw_type  => 'form'
					);
					$inCAM->COM(
								 'rename_entity',
								 job      => "$jobName",
								 name     => "$panelName",
								 new_name => "input",
								 is_fw    => 'no',
								 type     => 'step',
								 fw_type  => 'form'
					);
					$inputStep = 'input';
				}

			}
		}
	}
	else {
		$inputStep = $stepsArr[0];
		if ( $inputStep =~ /[Pp]anel/ ) {
			my $panelName = $inputStep;
			my $newName   = 'input';
			$inCAM->COM(
						 'rename_entity',
						 job      => "$jobName",
						 name     => "$panelName",
						 new_name => "$newName",
						 is_fw    => 'no',
						 type     => 'step',
						 fw_type  => 'form'
			);
			$inputStep = $newName;
		}
	}

	$inCAM->COM( 'set_step', name => "$inputStep" );
	$inCAM->COM( 'open_entity', job => "$jobName", type => 'step', name => "$inputStep", iconic => 'no' );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	#Move all pcb to zero point
	_MoveToZeroPoint( $jobName, $inputStep );



	# Here run script for rename according to Gatema's names layers
	$inCAM->COM(
				 'script_run',
				 name    => "//incam/incam_server/site_data/scripts/renameLayerScript.pl",
				 dirmode => 'global',
				 params  => "$jobName $inputStep"
	);

	#Check if exist layer "c" for single layer
	if ( CamJob->GetSignalLayerCnt( $inCAM, $jobName ) == 1 ) {
		_CheckSingleLayer( $jobName, $inputStep );
	}

	#Change original steps to worksteps in mpanel
	if ( CamHelper->StepExists( $inCAM, $jobName, 'mpanel' ) ) {
		_ChangeStepsInMpanel($jobName);
	}
	_Process( $jobName, $inputStep );

}

sub GerberCustomer {
	my $operat = shift;
	my $path;
	my @types = ( [ "zip,odb++", [qw/*.zip *.*/] ], [ "All files", '*' ] );
	if ( $operat eq 'open' ) {
		$path = $inputWindow->getOpenFile( -filetypes => \@types, -initialdir => "$pathDisk" );
	}

	unless ( -e $path ) {

		#new
		my @mess     = ("Chybí importní soubor!");
		my $messMngr = MessageMngr->new('');
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );
		return ();
	}

	my ( $prefixDiskName, $bodyPath, $fileName, $suffixName, $jobName, $localFolder ) = _GetAttrFromPath($path);

	# Check if jobName already exist;
	_CheckJobExist($jobName);

	my $hostName  = $ENV{HOST};
	my $reference = HegMethods->GetNumberOrder($jobName);
	HelperWriter->OnlineWrite_order( $reference, "zpracovava $hostName", "aktualni_krok" );

	if ( $suffixName =~ /[Zz][Ii][Pp]/ ) {
		_ExtractZip( $path, $prefixDiskName, $bodyPath );
	}
	unless ( $prefixDiskName eq 'C:' ) {

		_MoveFolderToLocal( $prefixDiskName, $bodyPath, $jobName, $localFolder );
	}

	# Create new job and set customer name
	_NewJobCreate($jobName);

	my $warPathRep    = EnumsPaths->Client_INCAMTMP . $jobName . '_auto_report.txt';
	my $identPathRep  = EnumsPaths->Client_INCAMTMP . $jobName . '_auto_identify.txt';
	my $translPathRep = EnumsPaths->Client_INCAMTMP . $jobName . '_auto_translate.txt';

	$inCAM->COM(
				 'input_auto',
				 path              => "$localFolder/$jobName",
				 job               => "$jobName",
				 ident_script_path => $identPathRep,
				 trans_script_path => $translPathRep,
				 report_path       => $warPathRep,
				 step              => 'o'
	);

	_SearchResultInReport( $jobName, $warPathRep );

	if ( -e $warPathRep ) {
		unlink($warPathRep);
	}
	if ( -e $identPathRep ) {
		unlink($identPathRep);
	}
	if ( -e $translPathRep ) {
		unlink($translPathRep);
	}

	$inCAM->COM( 'open_entity', job => "$jobName", type => 'step', name => "o", iconic => 'no' );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	$inCAM->COM( 'units',         type => 'mm' );
	$inCAM->COM( 'set_subsystem', name => '1-Up-Edit' );
	$inCAM->COM('zoom_home');

	$inputWindow->destroy;

	$inCAM->PAUSE("Pozor musis nacist data znovu manualne, pak pokracuj!");

	while () {
		$inCAM->INFO( entity_type => 'layer', entity_path => "$jobName/o/o", data_type => 'exists' );
		if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {

			$inCAM->COM( 'display_layer', name => 'o', display => 'yes', number => '1' );
			$inCAM->COM( 'work_layer', name => 'o' );
			$inCAM->COM( 'filter_reset', filter_name => 'popup' );
			$inCAM->COM('filter_area_strt');
			$inCAM->COM(
						 'filter_area_end',
						 layer          => 'o',
						 filter_name    => 'popup',
						 operation      => 'select',
						 area_type      => 'none',
						 inside_area    => 'no',
						 intersect_area => 'no',
						 lines_only     => 'no',
						 ovals_only     => 'no',
						 min_len        => '0',
						 max_len        => '0',
						 min_angle      => '0',
						 max_angle      => '0'
			);

			$inCAM->COM('sel_create_profile');
			$inCAM->COM( 'filter_reset', filter_name => 'popup' );

			last;
		}
		else {
			$inCAM->PAUSE("Musis vytvorit vrstvu 'o' a v ni obrys desky, pak muzes pokracovat");
		}
	}

	#Move all pcb to zero point
	_MoveToZeroPoint( $jobName, 'o' );

	$inCAM->COM(
				 'copy_entity',
				 type          => 'step',
				 source_job    => "$jobName",
				 source_name   => 'o',
				 dest_job      => "$jobName",
				 dest_name     => 'o+1',
				 dest_database => ''
	);
	$inCAM->COM( 'open_entity', job => "$jobName", type => 'step', name => 'o+1', iconic => 'no' );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	#unless (HegMethods->GetTypeOfPcb($jobName) eq 'Neplatovany') {
	#			$inCAM->COM('netlist_ref_update',job=>"$jobName",step=>'o+1',source=>'cur');
	#}

	_Process($jobName);

	exit;

}

sub ODBinputFolder {

	$path = $inputWindow->chooseDirectory( -initialdir => 'c:/pcb',
										   -title      => 'Choose dir ODB++' );

	unless ( -e $path ) {

		#new
		my @mess     = ("Chybí importní soubor!");
		my $messMngr = MessageMngr->new('');
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );
		return ();
	}

	my ( $prefixDiskName, $bodyPath, $fileName, $suffixName, $jobName, $localFolder ) = _GetAttrFromPath($path);

	# Check if jobName already exist;
	_CheckJobExist($jobName);

	$inCAM->COM( 'import_open_job', db => 'incam', path => "$path", name => "$jobName", analyze_surfaces => 'no' );

	$inCAM->INFO( entity_type => 'job', entity_path => "$jobName", data_type => 'STEPS_LIST' );
	my @stepsArr = @{ $inCAM->{doinfo}{gSTEPS_LIST} };
	my $inputStep;
	unless ( scalar @stepsArr == 1 ) {
		$inputStep = _SelectInputStep(@stepsArr);
	}
	else {
		$inputStep = $stepsArr[0];
	}

	$inCAM->COM( 'set_step', name => "$inputStep" );

	#Move all pcb to zero point
	_MoveToZeroPoint( $jobName, $inputStep );

	# Delete components layers
	_RemoveComponentLayers($jobName);

	# Here is stop for check input data
	$inCAM->PAUSE('Zkontroloj a uprav nazvy vrstev');

	$inCAM->COM(
				 'copy_entity',
				 type          => 'step',
				 source_job    => "$jobName",
				 source_name   => "$inputStep",
				 dest_job      => "$jobName",
				 dest_name     => 'o+1',
				 dest_database => ''
	);
	$inCAM->COM( 'set_step', name => "$inputStep" );

	_Process( $jobName, $inputStep );

}

########
######## SUBROUTINE
##########################################################################################################
sub _Process {
	my $pcbId    = shift;
	my $stepName = 'o+1';


	# set pcb custer name to InCAM job CUSTOMER_REFERENCE
	my @pole    = HegMethods->GetAllByPcbId($pcbId);
	my $pcbName = $pole[0]->{'board_name'};
	if ( defined $pcbName && $pcbName ne "" ) {


		$pcbName =~ s/\s/_/g;
		$pcbName = substr $pcbName, 0, 20;

		# Remove diacritics

		my $pcbNameDec = NFKD($pcbName);
		$pcbNameDec =~ s/\p{NonspacingMark}//g;
		
		

		CamAttributes->SetJobAttribute( $inCAM, $pcbId, "CUSTOMER_REFERENCE", $pcbNameDec );

	}


	#set special attr datacore YY+1
	#it was add to hook create job
	#my $custDateYYYY = (sprintf "%02.d",(localtime->year() %100) + 1);
	#CamAttributes->SetJobAttribute($inCAM, $pcbId, 'custom_year', $custDateYYYY);

	_CreateMissingLayer( $pcbId, $stepName, 'm' );

	# Remove folder in r:/Archiv/$job
	# Zatim zaremovano
	#_CheckRemoveFolder($pcbId);

	# Check and make, when the layer missing
	_CheckandMakeNeedLayer( $pcbId, $stepName, 'f', 'board', 'rout' );

	# Here is set npt holes without copper and then move to layer 'f'
	_MoveNonPlateHoles($pcbId);

	#Re-Set customer name and ID
	_SetCustomerAgain($pcbId);

	# Here run script for set value of drill diameter
	SetHolesRun->CalculationDrills( $inCAM, $pcbId );

	# Change minimal line in rout layer
	_ChangeMinLineRout($pcbId);

	$inCAM->COM( 'script_run', name => "//incam/incam_server/site_data/scripts/kontrola.pl", dirmode => 'global', params => "$pcbId $stepName" );

	$inCAM->INFO( entity_type => 'layer', entity_path => "$pcbId/$stepName/f", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		$inCAM->COM( 'display_layer', name => 'f', display => 'yes', number => '1' );
		$inCAM->COM( 'work_layer', name => 'f' );

		# Check if there must be tabs or no
		my $resultTabs = _CheckMinAreaForTabs($pcbId);

		$inCAM->COM( 'set_subsystem', name => 'Rout' );

		$inCAM->PAUSE("TED UDELEJ FREZU $pcbId - tlacitko F4 ($resultTabs)");
		$inCAM->COM( 'display_layer', name => 'f', display => 'no', number => '1' );
		$inCAM->COM( 'set_subsystem', name => '1-Up-Edit' );

	}

	# Copy profile to solder mask
	_Profile_to_mask( $pcbId, $stepName );

	# Check drill-table if customer has right values in the column FINISH SIZE
	_CheckCustomerFinishHoles($pcbId);

	# Check and create PLGC and PLGS
	if ( CamDrilling->GetViaFillExists( $inCAM, $pcbId ) ) {

		# Bude se generovat pred exportem
		#my $result = PlugLayer->CreateCopperPlugLayers( $inCAM,  $pcbId, "o+1" );

	}

	$inCAM->COM( 'save_job', job => "$pcbId", override => 'no', skip_upgrade => 'no' );

	# Here run clean-up.
	$inCAM->COM( 'chklist_from_lib', chklist => 'clean_up', profile => 'none', customer => '' );
	$inCAM->COM( 'chklist_open', chklist => 'clean_up' );
	$inCAM->COM( 'chklist_show', chklist => 'clean_up', nact => '1', pinned => 'no',      pinned_enabled => 'yes' );
	$inCAM->COM( 'chklist_run',  chklist => 'clean_up', nact => 'a', area   => 'profile', async_run      => 'no' );

	$inCAM->COM( 'save_job', job => "$pcbId", override => 'no', skip_upgrade => 'no' );

	$inCAM->PAUSE('ZKONTROLUJ CLEAN-UP');

	$inCAM->COM( 'save_job', job => "$pcbId", override => 'no', skip_upgrade => 'no' );

	# Here is check if there is result of 'Surface analyzer' in the green color.
	while () {
		if ( _CheckREDresult($pcbId) ) {
			$inCAM->PAUSE("Vyres problem, proc je Surface Analyzer v cervene barve.");
		}
		else {
			last;
		}
	}

	$inCAM->COM( 'chklist_close', chklist => 'clean_up', mode => 'hide' );

	# Set CAM GUIDE called Skriptiky
	$inCAM->INFO( entity_type => 'cam_guide', entity_path => "$pcbId/Scriptiky", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "no" ) {

		$inCAM->COM( 'show_component', component => 'CAM_Guide', show => 'no', width => 0, height => 0 );
		$inCAM->COM( 'guide_from_lib', guide => 'Scriptiky', profile => 'none', customer => '' );
		$inCAM->COM( 'set_current_guide', guide => 'Scriptiky' );
	}

	# Remove all features outside profile in the layer list
	foreach my $layer ( 'pc', 'ps' ) {
		if ( CamHelper->LayerExists( $inCAM, $pcbId, $layer ) ) {
			CamLayer->ClipAreaByProf( $inCAM, $layer, '200', 0, 0 );
		}
	}

	# Here run Impedace Guide
	if ( HegMethods->GetImpedancExist($pcbId) ) {
		my $messMngr = MessageMngr->new($pcbId);
		my $res = DoSetImpLines->SetImpedanceLines( $inCAM, $pcbId );
	}

	# Here run Checks
	$inCAM->COM( 'chklist_from_lib', chklist => 'checks', profile => 'none', customer => '' );
	$inCAM->COM( 'chklist_open', chklist => 'checks' );
	$inCAM->COM( 'chklist_show', chklist => 'checks', nact => '1', pinned => 'no', pinned_enabled => 'yes' );

	#$inCAM -> COM('chklist_run',chklist=>'Checks',nact=>'a',area=>'profile',async_run=>'no');

	$inCAM->PAUSE('PROVED CHECK-list');
	$inCAM->COM( 'chklist_close', chklist => 'checks', mode => 'hide' );

	# When I have mpanel so will be flattened
	$inCAM->INFO( entity_type => 'step', entity_path => "$pcbId/mpanel", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		if ( HegMethods->GetPcbIsPool($pcbId) == 1 ) {
			my $stepNetlist = 'o+1_panel';
			$inCAM->COM(
						 'copy_entity',
						 type          => 'step',
						 source_job    => "$pcbId",
						 source_name   => 'mpanel',
						 dest_job      => "$pcbId",
						 dest_name     => "$stepNetlist",
						 dest_database => ''
			);

			$inCAM->COM( 'set_step', name => 'mpanel' );
			$inCAM->COM(
						 'script_run',
						 name    => "//incam/incam_server/site_data/scripts/flatten_pool.pl",
						 dirmode => 'global',
						 params  => "$pcbId mpanel"
			);
			$inCAM->PAUSE('Zkontroluj flatenovany MPANEL, udelej frezu.');
		}
	}

	# Check if customer requsted solder mask in pool servis, when no so add
	if ( HegMethods->GetPcbIsPool($pcbId) ) {
		my %solderMask = HegMethods->GetSolderMaskColor($pcbId);
		unless ( $solderMask{'top'} ) {
			if ( _GuiMaska('mc') == 2 ) {
				_DrawSurface( $pcbId, 'o+1', 'mc' );
			}
		}
		unless ( $solderMask{'bot'} ) {
			if ( _GuiMaska('ms') == 2 ) {
				_DrawSurface( $pcbId, 'o+1', 'ms' );
			}
		}
		_Profile_to_mask( $pcbId, 'o+1' );
	}

	# Here run F3 panelise.pl
	$inCAM->COM( 'save_job', job => "$pcbId", override => 'no', skip_upgrade => 'no' );
	$inCAM->COM( 'script_run', name => "//incam/incam_server/site_data/scripts/PaneliseScript.pl", dirmode => 'global', params => "$pcbId" );

	# 			# Run Netlist compare
	# 			unless (HegMethods->GetTypeOfPcb($pcbId) eq 'Neplatovany') {
	# 						$inCAM -> INFO(entity_type => 'job',entity_path => "$pcbId",data_type => 'STEPS_LIST');
	#						my @stepsArr = @{$inCAM->{doinfo}{gSTEPS_LIST}};
	#						$inCAM -> PAUSE ($stepsArr[0]);
	#					_NetlistCompare($pcbId, $stepsArr[0]);
	#			}

	#$inCAM -> PAUSE("Po kliknuti ulozim $pcbId");

	#$inCAM -> COM ('save_job',job=>"$pcbId",override=>'no',skip_upgrade=>'no');
	#$inCAM -> COM ('editor_page_close');

	#$inCAM -> COM('check_inout',job=>"$pcbId",mode=>'in',ent_type=>'job');

	#$inCAM ->	COM ('close_job',job=>"$pcbId");
	#$inCAM ->	COM ('close_form',job=>"$pcbId");
	#$inCAM ->	COM ('close_flow',job=>"$pcbId");

	#$inCAM ->	COM ('show_tab',tab=>'CAM Database Manager',show=>'yes');
	#$inCAM ->	COM ('top_tab',tab=>'CAM Database Manager');
	#$inCAM ->	COM ('cdbm_copy_jobs',jobs=>"$pcbId",jobs_app=>'incam',target_app=>'genesis',target_db=>'genesis',async_run=>'yes');

	exit;

}

sub _NewJobCreate {
	my $jobId = shift;

	my $numberCustomer;
	my $customerName;

	if ( $customerPOOL eq 'pool' ) {

		$numberCustomer = 'POOL';
		$customerName   = 'POOL';

	}
	elsif ( $customerPOOL eq 'altium' ) {

		$numberCustomer = 'ALTIUM';
		$customerName   = 'ALTIUM';

	}
	else {
		$numberCustomer = HegMethods->GetIdcustomer($jobId);
		my @pole = HegMethods->GetAllByPcbId($jobId);
		$customerName = $pole[0]->{'customer'};
		$customerName =~ s/,/./g;
	}

	$inCAM->HandleException(1);
	$inCAM->SupressToolkitException(1);

	$inCAM->COM( 'new_customer', name => "$numberCustomer", disp_name => "$customerName", properties => '', skip_on_existing => 'yes' );

	if ( $inCAM->{STATUS} != 0 ) {
		$inCAM->COM( 'delete_customer', name => "$numberCustomer" );
		$inCAM->COM( 'new_customer', name => "$numberCustomer", disp_name => "$customerName", properties => '', skip_on_existing => 'no' );
	}

	$inCAM->SupressToolkitException(0);
	$inCAM->HandleException(0);

	my $custIncamName = _GetInCamCustomer($numberCustomer);
	$inCAM->COM(
				 'new_job',
				 name       => "$jobId",
				 db         => 'incam',
				 customer   => "$numberCustomer",
				 disp_name  => "$custIncamName",
				 notes      => '',
				 attributes => ''
	);

}

sub _GetInCamCustomer {
	my $custNumber = shift;

	my $path = EnumsPaths->InCAM_server . "customers\\customers.xml";

	$katalog = XMLin("$path");

	my $cust = $katalog->{'customer'}->{$custNumber}->{display_name};

	return ($cust);
}

sub convert_from_czech {
	my $lineToConvert = shift;
	my $char;
	my $ret;
	my @str = split( //, $lineToConvert );

	foreach my $char (@str) {
		$char =~
tr/\xE1\xC1\xE8\xC8\xEF\xCF\xE9\xC9\xEC\xCC\xED\xCD\xF3\xD3\xF8\xD8\xB9\xA9\xBB\xAB\xFA\xDA\xF9\xD9\xFD\xDD\xBE\xAE\xF2\xD2/\x61\x41\x63\x43\x64\x44\x65\x45\x65\x45\x69\x49\x6F\x4F\x72\x52\x73\x53\x74\x54\x75\x55\x75\x55\x79\x59\x7A\x5A\x6E\x4E/;
		$ret .= $char;
	}
	return ($ret);

}

sub _CheckandMakeNeedLayer {
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $context   = shift;
	my $type      = shift;

	$inCAM->INFO( entity_type => 'layer', entity_path => "$jobId/$stepName/$layerName", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "no" ) {
		$inCAM->COM( 'create_layer', layer => "$layerName", context => "$context", type => "$type", polarity => 'positive', ins_layer => '' );
	}
	return ();
}

sub _Profile_to_mask {
	my $jobId          = shift;
	my $stepName       = shift;
	my $defaultWidth   = 200;
	my $layerSolderTop = 0;
	my $layerSolderBot = 0;

	$inCAM->INFO( entity_type => 'layer', entity_path => "$jobId/$stepName/mc", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		$layerSolderTop = 1;
	}
	$inCAM->INFO( entity_type => 'layer', entity_path => "$jobId/$stepName/ms", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		$layerSolderBot = 1;
	}

	if ( $layerSolderTop == 1 or $layerSolderBot == 1 ) {
		$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );
		$inCAM->COM( 'profile_to_rout', layer => '__profile_for_mask__', width => "$defaultWidth" );
		$inCAM->COM( 'display_layer', name => '__profile_for_mask__', display => 'yes', number => 1 );
		$inCAM->COM( 'work_layer',      name   => '__profile_for_mask__' );
		$inCAM->COM( 'affected_filter', filter => "(type=solder_mask&context=board)" );
		$inCAM->COM( 'sel_copy_other',  dest   => 'affected_layers', target_layer => '', invert => 'no', dx => 0, dy => 0, size => 0 );

		$inCAM->COM( 'delete_layer', layer => "__profile_for_mask__" );
		$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );
	}
}

sub __CheckCustomerIdExist {
	my $jobId          = shift;
	my $numberCustomer = HegMethods->GetIdcustomer($jobId);

	my $customerFile = '//incam/incam_server/customers/customers.xml';

	open( CUSTOMER, "$customerFile" );
	while (<CUSTOMER>) {
		if ( $_ =~ /$numberCustomer/ ) {
			return (1);
			last;
		}
	}
	close CUSTOMER;

	return (0);

}

sub _CheckJobExist {
	my $jobId = shift;

	# Check if jobName already exist;
	$inCAM->INFO( entity_type => 'job', entity_path => "$jobId", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {

		#new
		my $messMngr = MessageMngr->new($pcbId);
		my @mess     = ("Jméno jobu $jobId již existuje!");
		my @btn      = ( "SMAZAT JOB a pokračovat v importu", "KONEC" );    # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btn );
		my $result = $messMngr->Result();

		if ( $result == 1 ) {
			exit;
		}
		else {
			#new
			my $messMngr = MessageMngr->new($pcbId);
			my @mess     = ("Opravdu smazat job $jobId ?");
			my @btn      = ( "ANO", "NE" );                                    # "ok" = tl. cislo 1, "table tools" = tl.cislo 2
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btn );
			my $resultDelete = $messMngr->Result();

			if ( $resultDelete == 1 ) {
				exit;
			}
			else {
				$inCAM->COM( 'delete_entity', job => "$jobId", type => 'job', name => "$jobId" );
			}
		}
	}

}

sub _SearchTgz {
	my $jobId     = shift;
	my $localPath = shift;
	my @listFiles = ();

	find( { wanted => sub { push @listFiles, $File::Find::name }, no_chdir => 1 }, $localPath . '/' . $jobId );

	my @tgzArr = grep /\.tgz$/, @listFiles;

	# check how many tgz file found out
	unless ( scalar @tgzArr == 1 ) {

		#new
		my @mess     = ("Nemůžu najít spravný tgz file pro import!");
		my $messMngr = MessageMngr->new('');
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

		exit;
	}
	else {
		return ( $tgzArr[0] );
	}
}

sub _ExtractZip {
	my $tmpPath     = shift;
	my $diskNameTMP = shift;
	my $bodyTMP     = shift;
	my @subZip      = ();

	my @listFiles = ();
	my $zip       = Archive::Zip->new("$tmpPath");
	my @fileInZip = $zip->memberNames;
	foreach $fileZip (@fileInZip) {
		if ( $fileZip =~ /\.zip$/ ) {
			push @subZip, $fileZip;
		}

		$zip->extractMember( $fileZip, $diskNameTMP . '/' . $bodyTMP . '/' . $fileZip );
	}
	if ( scalar @subZip ) {
		foreach my $oneSubZip (@subZip) {
			if ($oneSubZip) {
				my $folder = substr( $oneSubZip, 0, -4 );
				_ExtractZip( $diskNameTMP . '/' . $bodyTMP . '/' . $oneSubZip, 'c:', $bodyTMP . '/' . $folder );
			}
		}
	}
}

sub _NetlistCompare {
	my $jobId  = shift;
	my $stepId = shift;

	$inCAM->COM( 'show_tab',     tab    => '1-Up Parameters Page', show     => 'yes' );
	$inCAM->COM( 'top_tab',      tab    => '1-Up Parameters Page' );
	$inCAM->COM( 'rv_tab_empty', report => 'netlist_compare',      is_empty => 'yes' );
	$inCAM->COM(
				 'netlist_compare',
				 job2                 => "$jobId",
				 step2                => "$stepId",
				 type2                => 'cur',
				 recalc_cur           => 'no',
				 use_cad_names        => 'no',
				 report_extra         => 'yes',
				 report_miss_on_cu    => 'yes',
				 report_miss          => 'yes',
				 max_highlight_shapes => '5000'
	);
	$inCAM->COM( 'rv_tab_view_results_enabled', report => 'netlist_compare', is_enabled => 'yes', serial_num => '-1', all_count => '-1' );
	$inCAM->COM('netlist_compare_results_show');

}

sub _MoveFolderToLocal {
	my $diskNameTMP = shift;
	my $bodyTMP     = shift;
	my $jobId       = shift;
	my $localPath   = shift;

	dirmove( $diskNameTMP . '/' . $bodyTMP, $localPath . '/' . $jobId );

	return ( $localPath . '/' . $jobId );
}

sub _MoveToZeroPoint {
	my $pcbId    = shift;
	my $stepName = shift;
	my $tmpLayer = '_tmp_dim_';

	$inCAM->INFO( units => 'mm', entity_type => 'step', entity_path => "$pcbId/$stepName", data_type => 'DATUM' );
	my $datumPointX = sprintf "%3.3f", ( $inCAM->{doinfo}{gDATUMx} );
	my $datumPointY = sprintf "%3.3f", ( $inCAM->{doinfo}{gDATUMy} );

	$inCAM->INFO( units => 'mm', entity_type => 'step', entity_path => "$pcbId/$stepName", data_type => 'PROF_LIMITS' );
	my $zeroPointX = sprintf "%3.3f", ( $inCAM->{doinfo}{gPROF_LIMITSxmin} * (-1) );
	my $zeroPointY = sprintf "%3.3f", ( $inCAM->{doinfo}{gPROF_LIMITSymin} * (-1) );

	if ( $zeroPointX != 0 or $zeroPointY != 0 ) {
		$inCAM->COM( 'profile_to_rout', layer => "$tmpLayer", width => '300' );

		$inCAM->COM( 'affected_layer', mode => 'all',         affected => 'yes' );
		$inCAM->COM( 'sel_move',       dx   => "$zeroPointX", dy       => "$zeroPointY" );
		$inCAM->COM( 'affected_layer', mode => 'all',         affected => 'no' );

		$inCAM->COM( 'filter_reset', filter_name => 'popup' );
		$inCAM->COM('clear_layers');

		$inCAM->COM( 'display_layer', name => "$tmpLayer", display => 'yes', number => '1' );
		$inCAM->COM( 'work_layer', name => "$tmpLayer" );
		$inCAM->COM('filter_area_strt');
		$inCAM->COM(
					 'filter_area_end',
					 layer          => "$tmpLayer",
					 filter_name    => 'popup',
					 operation      => 'select',
					 area_type      => 'none',
					 inside_area    => 'no',
					 intersect_area => 'no',
					 lines_only     => 'no',
					 ovals_only     => 'no',
					 min_len        => '0',
					 max_len        => '0',
					 min_angle      => '0',
					 max_angle      => '0'
		);
		$inCAM->COM('sel_create_profile');
		$inCAM->COM( 'filter_reset',  filter_name => 'popup' );
		$inCAM->COM( 'datum',         x           => '0', y => '0' );
		$inCAM->COM( 'display_layer', name        => "$tmpLayer", display => 'no', number => '1' );
		$inCAM->COM( 'delete_layer',  layer       => "$tmpLayer" );
		$inCAM->COM('zoom_home');
	}
	else {
		if ( $datumPointX != 0 or $datumPointY != 0 ) {
			$inCAM->COM( 'datum', x => '0', y => '0' );
			$inCAM->COM('zoom_home');
		}
	}
}

sub _GetAttrFromPath {
	my $tmpPath   = shift;
	my $localPath = 'c:/pcb';

	my @fieldsPath = split /\//, $tmpPath;

	# Get JobName
	my @jobNameArrTMP = grep /[FfDd]\d{5}/, @fieldsPath;
	my $jobIdNameTMP = lc $jobNameArrTMP[0];

	# Get Name of disk
	my $diskNameTMP = $fieldsPath[0];

	# Get Name of file
	my $fileNameTMP = $fieldsPath[ scalar @fieldsPath - 1 ];

	# Get Name of suffix
	my @arrTMP = split /\./, $fieldsPath[ scalar @fieldsPath - 1 ];
	my $suffixTMP = $arrTMP[ scalar @arrTMP - 1 ];

	# Get path of body original path
	my @bodyArrTMP = @fieldsPath;
	pop @bodyArrTMP;
	shift @bodyArrTMP;
	my $bodyTMP = join( '/', @bodyArrTMP );

	return ( $diskNameTMP, $bodyTMP, $fileNameTMP, $suffixTMP, $jobIdNameTMP, $localPath );
}

sub _MoveNonPlateHoles {
	my $pcbId     = shift;
	my $npthLayer = 'f';

	$inCAM->COM( 'set_step', name => 'o+1' );

	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );

	$inCAM->COM( 'display_layer', name => 'c', display => 'yes', number => '1' );
	$inCAM->COM( 'work_layer', name => 'c' );

	$inCAM->COM( 'affected_filter', filter      => "( type=signal & context=board & side=top)" );
	$inCAM->COM( 'filter_reset',    filter_name => 'popup' );
	$inCAM->COM( 'filter_set',      filter_name => 'popup', update_popup => 'yes', feat_types => 'line\;pad\;surface\;arc\;text' );
	$inCAM->COM('filter_area_strt');
	$inCAM->COM(
				 'filter_area_end',
				 layer          => '',
				 filter_name    => 'popup',
				 operation      => 'select',
				 area_type      => 'none',
				 inside_area    => 'no',
				 intersect_area => 'no',
				 lines_only     => 'no',
				 ovals_only     => 'no',
				 min_len        => '0',
				 max_len        => '0',
				 min_angle      => '0',
				 max_angle      => '0'
	);
	$inCAM->COM('get_select_count');

	$inCAM->COM( 'affected_filter', filter => "( type=drill & context=board & pol=positive & name=m)" );
	$inCAM->COM( 'filter_set', filter_name => 'popup', update_popup => 'yes', feat_types => 'pad' );

	#$inCAM->COM ('filter_atr_set',filter_name=>'popup',condition=>'yes',attribute=>'.drill',option=>'plated');
	$inCAM->COM(
				 'sel_ref_feat',
				 layers       => '',
				 use          => 'select',
				 mode         => 'disjoint',
				 f_types      => 'line\;pad\;surface\;arc\;text',
				 polarity     => 'positive\;negative',
				 include_syms => '',
				 exclude_syms => ''
	);
	$inCAM->COM('get_select_count');
	if ( $inCAM->{COMANS} == 0 ) {
		$inCAM->COM( 'filter_reset',   filter_name => 'popup' );
		$inCAM->COM( 'affected_layer', name        => "", mode => "all", affected => "no" );
		$inCAM->COM( 'display_layer',  name        => 'c', display => 'no', number => '1' );
	}
	else {
		$inCAM->COM('get_select_count');
		$inCAM->INFO( entity_type => 'layer', entity_path => "$pcbId/o+1/f", data_type => 'exists' );
		if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
			$inCAM->COM(
						 'sel_move_other',
						 target_layer => 'f',
						 invert       => 'no',
						 dx           => '0',
						 dy           => '0',
						 size         => '0',
						 x_anchor     => '0',
						 y_anchor     => '0',
						 rotation     => '0',
						 mirror       => 'none'
			);
			$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );

			#__npth_correct_set($pcbId, $npthLayer);
		}
		else {
			$inCAM->COM( 'create_layer', layer => 'f', context => 'board', type => 'rout', polarity => 'positive', ins_layer => 'm' );
			$inCAM->COM(
						 'sel_move_other',
						 target_layer => 'f',
						 invert       => 'no',
						 dx           => '0',
						 dy           => '0',
						 size         => '0',
						 x_anchor     => '0',
						 y_anchor     => '0',
						 rotation     => '0',
						 mirror       => 'none'
			);

			#__npth_correct_set($pcbId, $npthLayer);
		}
	}

	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	$inCAM->COM('clear_layers');

	# Check exist layer d and move to f and remove them.
	$inCAM->INFO( entity_type => 'layer', entity_path => "$pcbId/o+1/d", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		$inCAM->COM( 'display_layer', name => 'd', display => 'yes', number => '1' );
		$inCAM->COM( 'work_layer', name => 'd' );
		$inCAM->COM(
					 'sel_move_other',
					 target_layer => 'f',
					 invert       => 'no',
					 dx           => '0',
					 dy           => '0',
					 size         => '0',
					 "x_anchor"   => '0',
					 "y_anchor"   => '0',
					 rotation     => '0',
					 mirror       => 'none'
		);
		$inCAM->COM( 'display_layer', name => 'd', display => 'no', number => '1' );
		$inCAM->COM( 'delete_layer', layer => 'd' );
		__npth_correct_set( $pcbId, $npthLayer );
	}

}

sub __npth_correct_set {
	my $pcbId     = shift;
	my $npthLayer = shift;

	$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$pcbId/o+1/$npthLayer", data_type => 'NUM_TOOL' );
	$pocetTool = $inCAM->{doinfo}{gNUM_TOOL};

	$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$pcbId/o+1/$npthLayer", data_type => 'TOOL' );
	@numVrtaku  = @{ $inCAM->{doinfo}{gTOOLnum} };
	@finishSize = @{ $inCAM->{doinfo}{gTOOLfinish_size} };
	@type       = @{ $inCAM->{doinfo}{gTOOLtype} };
	@min_tools  = @{ $inCAM->{doinfo}{gTOOLmin_tol} };
	@max_tools  = @{ $inCAM->{doinfo}{gTOOLmax_tol} };

	$inCAM->COM('tools_tab_reset');
	$pocetTool -= 1;
	for ( $countDrill = 0 ; $countDrill <= $pocetTool ; $countDrill++ ) {
		if ( $type[$countDrill] eq "plated" ) {
			$type[$countDrill] = "nplate";
		}
		elsif ( $type[$countDrill] eq "non_plated" ) {
			$type[$countDrill] = "nplate";
		}

		$inCAM->COM(
					 'drill_size_hook',
					 layer       => "$npthLayer",
					 thickness   => '0',
					 user_params => 'vrtane',
					 finish_size => "$finishSize[$countDrill]",
					 bit         => 'Drill Des',
					 type        => "$type[$countDrill]",
					 min_tol     => "$min_tools[$countDrill]",
					 max_tol     => "$max_tools[$countDrill]"
		);

		my $drill_size = $inCAM->GetReply();
		@drill_size_bit = split /\s+/, $drill_size;
		$inCAM->COM(
					 'tools_tab_add',
					 num         => "$numVrtaku[$countDrill]",
					 type        => "$type[$countDrill]",
					 min_tol     => "$min_tools[$countDrill]",
					 max_tol     => "$max_tools[$countDrill]",
					 bit         => "$drill_size_bit[1]",
					 finish_size => "$finishSize[$countDrill]",
					 drill_size  => "$drill_size_bit[0]"
		);

		#,shape=>'hole'
	}
	$inCAM->COM( 'tools_set', layer => "$npthLayer", thickness => '0', user_params => 'vrtane' );

	#,slots=>'yes
}

sub _SelectInputStep {
	my @stepsList = @_;
	my $returnStep;
	my $mainStep = MainWindow->new();
	$mainStep->Label( -text => "Prilis mnoho stepu, vyber input step", -font => "Arial 10 bold" )->pack( -padx => 0, -pady => 0, -side => 'top' );

	my $mainWindow = $mainStep->Frame( -width => 80, -height => 40 )->pack( -side => 'top', -fill => 'both' );

	my $stepWin = $mainWindow->Listbox( -font => 'ARIAL 12' )->pack();
	$stepWin->insert( 'end', @stepsList );

	my $exitBttn = $mainStep->Button( -text => "Pokracovat", -command => \sub { $returnStep = $stepWin->get('active'); $mainStep->destroy; } )
	  ->pack( -side => 'top', -fill => 'both' );

	$mainStep->waitWindow;
	return ($returnStep);
}

sub _GetSizeOfPcb {
	my $pcbId    = shift;
	my $StepName = shift;

	$inCAM->INFO( units => 'mm', entity_type => 'step', entity_path => "$pcbId/$StepName", data_type => 'PROF_LIMITS' );
	my $pcbXsize = sprintf "%3.2f", ( $inCAM->{doinfo}{gPROF_LIMITSxmax} - $inCAM->{doinfo}{gPROF_LIMITSxmin} );
	my $pcbYsize = sprintf "%3.2f", ( $inCAM->{doinfo}{gPROF_LIMITSymax} - $inCAM->{doinfo}{gPROF_LIMITSymin} );
	return ( $pcbXsize, $pcbYsize );
}

sub _CheckRemoveFolder {
	my $pcbId = shift;
	my $path  = 'r:/Archiv';

	if ( -e "$path/$pcbId" ) {
		rmdir "$path/$pcbId";
	}

	return ();
}

sub _ChangeMinLineRout {
	my $pcbId     = shift;
	my $minLine   = 200;
	my $stepName  = 'o+1';
	my $layerRout = 'f';

	my $infoFile = $inCAM->INFO(
								 'units'       => 'mm',
								 'entity_type' => 'layer',
								 'entity_path' => "$pcbId/$stepName/$layerRout",
								 'data_type'   => 'FEATURES',
								 parse         => 'no'
	);
	open( INFOFILE, $infoFile );
	while (<INFOFILE>) {
		if ( $_ =~ /^#L/ ) {
			my @fields = split /\s+/;
			my @valueOfDcode = split /[a-z]/, $fields[5];

			#print STDERR "aaaaaa" , $valueOfDcode[1], "\n";
			if ( $valueOfDcode[1] <= $minLine ) {

				$dcodeHash{ $fields[5] } = 1;
			}
		}
		elsif ( $_ =~ /^#A/ ) {
			my @fields = split /\s+/;
			my @valueOfDcode = split /[a-z]/, $fields[7];

			if ( $valueOfDcode[1] <= $minLine ) {
				$dcodeHash{ $fields[7] } = 1;
			}
		}
	}
	close INFOFILE;

	my @dcodeArr = keys %dcodeHash;

	my $sortDcode = join( ';', @dcodeArr );

	if ($sortDcode) {
		$inCAM->COM( 'filter_reset',   filter_name => 'popup' );
		$inCAM->COM( 'affected_layer', affected    => 'no', mode => 'all' );
		$inCAM->COM( 'display_layer',  name        => "$layerRout", display => 'yes', number => '1' );
		$inCAM->COM( 'work_layer',     name        => "$layerRout" );

		$inCAM->COM( 'set_filter_polarity', filter_name => '', positive => 'yes', negative => 'no' );
		$inCAM->COM( 'set_filter_type', filter_name => '', lines => 'yes', pads => 'no', surfaces => 'no', arcs => 'yes', text => 'no' );
		$inCAM->COM( 'set_filter_symbols', filter_name => '', exclude_symbols => 'no', symbols => "$sortDcode" );
		$inCAM->COM('filter_area_strt');
		$inCAM->COM( 'filter_area_end', filter_name => 'popup', operation => 'select' );
		$inCAM->COM('get_select_count');
		if ( $inCAM->{COMANS} > 0 ) {
			$inCAM->COM( 'sel_change_sym', symbol => 'r250', reset_angle => 'no' );
		}
	}

	$inCAM->COM( 'filter_reset', filter_name => 'popup' );
	$inCAM->COM( 'display_layer', name => "$layerRout", display => 'no', number => '1' );

}

sub _CheckMinAreaForTabs {
	my $jobId    = shift;
	my $stepId   = 'o+1';
	my $minArea  = 400;               #minimal value without tabs
	my $minDim   = 20;                #minimal dimension
	my $infoLine = 'PRIDEJ MUSTKY';

	# Get dimension of pcb
	my ( $XsizePcb, $YsizePcb ) = _GetSizeOfPcb( $jobId, $stepId );

	if ( $XsizePcb < $minDim and $YsizePcb < $minDim ) {
		return ($infoLine);
	}
	elsif ( CamCopperArea->GetProfileArea( $inCAM, $jobId, $stepId ) < $minArea ) {
		return ($infoLine);
	}
	else {
		return ('na patku');
	}
}

sub _CheckCustomerFinishHoles {
	my $jobId = shift;

	while (1) {
		if ( __CheckFinishHoles($jobId) ) {
			$inCAM->PAUSE('Spatne hodnoty v tabulce vrtaku pro finish size');
			next;
		}
		else {
			last;
		}
	}
}

sub __CheckFinishHoles {
	my $jobId   = shift;
	my $stepId  = 'o+1';
	my $layerId = 'm';

	$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$jobId/$stepId/$layerId", data_type => 'TOOL' );
	if ( scalar( grep /^0$/, @{ $inCAM->{doinfo}{gTOOLfinish_size} } ) > 0 ) {
		return (1);
	}
	return (0);
}

sub _RemoveComponentLayers {
	my $jobId = shift;

	$inCAM->INFO( 'entity_type' => 'matrix', 'entity_path' => "$jobId/matrix", 'data_type' => 'ROW' );
	my $totalRows = ${ $inCAM->{doinfo}{gROWrow} }[-1];
	for ( my $count = 0 ; $count <= $totalRows ; $count++ ) {
		my $rowName = ${ $inCAM->{doinfo}{gROWname} }[$count];
		my $rowType = ${ $inCAM->{doinfo}{gROWlayer_type} }[$count];

		if ( $rowType eq 'components' ) {
			$inCAM->COM( 'delete_layer', layer => "$rowName" );
		}
	}
}

sub _CustomerNetlistExist {
	my $jobId  = shift;
	my $stepId = shift;
	my $res    = 0;

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'netlist',
				  entity_path     => "$jobId/$stepId/cadnet",
				  data_type       => 'EXISTS'
	);

	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
		$res = 1;
	}

	return ($res);
}

sub _DrawSurface {
	my $pcbId   = shift;
	my $stepId  = shift;
	my $layer   = shift;
	my $addAttr = '.pattern_fill';

	CamLayer->ClearLayers($inCAM);

	$inCAM->INFO( entity_type => 'step', entity_path => "$pcbId/$stepId", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {

		$inCAM->COM( 'set_subsystem', name => '1-Up-Edit' );
		$inCAM->COM( 'set_step',      name => "$stepId" );

		$inCAM->INFO( entity_type => 'layer', entity_path => "$pcbId/$stepId/$layer", data_type => 'exists' );
		if ( $inCAM->{doinfo}{gEXISTS} eq "no" ) {
			$inCAM->COM( 'create_layer', layer => "$layer", context => 'board', type => 'solder_mask', polarity => 'positive', ins_layer => '' );
			$inCAM->COM( 'matrix_auto_rows', job => "$pcbId", matrix => 'matrix' );
		}

		$inCAM->COM( 'display_layer', name => "$layer", display => 'yes', number => '1' );
		$inCAM->COM( 'work_layer', name => "$layer" );

		$inCAM->COM('add_surf_fill');
		$inCAM->COM('cur_atr_reset');
		$inCAM->COM( 'cur_atr_set',   attribute => "$addAttr" );
		$inCAM->COM( 'add_surf_strt', surf_type => 'feature' );

		$inCAM->INFO( units => 'mm', entity_type => 'step', entity_path => "$pcbId/$stepId", data_type => 'PROF_LIMITS' );
		$inCAM->COM( 'add_surf_poly_strt', x => "$inCAM->{doinfo}{gPROF_LIMITSxmin}", y => "$inCAM->{doinfo}{gPROF_LIMITSymin}" );
		$inCAM->COM( 'add_surf_poly_seg',  x => "$inCAM->{doinfo}{gPROF_LIMITSxmin}", y => "$inCAM->{doinfo}{gPROF_LIMITSymax}" );
		$inCAM->COM( 'add_surf_poly_seg',  x => "$inCAM->{doinfo}{gPROF_LIMITSxmax}", y => "$inCAM->{doinfo}{gPROF_LIMITSymax}" );
		$inCAM->COM( 'add_surf_poly_seg',  x => "$inCAM->{doinfo}{gPROF_LIMITSxmax}", y => "$inCAM->{doinfo}{gPROF_LIMITSymin}" );
		$inCAM->COM( 'add_surf_poly_seg',  x => "$inCAM->{doinfo}{gPROF_LIMITSxmin}", y => "$inCAM->{doinfo}{gPROF_LIMITSymin}" );
		$inCAM->COM('add_surf_poly_end');
		$inCAM->COM( 'add_surf_end', polarity => 'positive', attributes => 'yes' );

		$inCAM->COM( 'display_layer', name => "$layer", display => 'no', number => '1' );

		CamLayer->ClipAreaByProf( $inCAM, $layer, '200', 0, 0 );
	}
}

sub _GuiMaska {
	my $layer = shift;

	my $result = -1;

	#new
	my $messMngr = MessageMngr->new($pcbId);

	my @mess = ("Zakaznik nepozaduje masku na strane $layer, ale v poolu je potreba. Mam vytvorit vrstvu masky celou odmaskovanou?");
	my @btn = ( "PAUSA", "NE", "VYTVORIT" );    # "PAUSA" = tl. cislo 0, "NE" = tl.cislo 1 , Vytvorit = 2

	$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@mess, \@btn );
	$result = $messMngr->Result();

	if ( $result == 0 ) {
		$inCAM->PAUSE("PAUSA - > Zkontroluj");
		$result = _GuiMaska($layer);
	}

	return ($result);

}

sub _CreateMissingLayer {
	my $pcbId = shift;
	my $step  = shift;
	my $layer = shift;

	$inCAM->INFO( entity_type => 'layer', entity_path => "$pcbId/$step/$layer", data_type => 'exists' );
	if ( $inCAM->{doinfo}{gEXISTS} eq "no" ) {
		$inCAM->COM( 'create_layer', layer => "$layer", context => 'board', type => 'drill', polarity => 'positive', ins_layer => '' );
		$inCAM->COM( 'matrix_auto_rows', job => "$pcbId", matrix => 'matrix' );
	}
}

sub _CheckSingleLayer {
	my $pcbId   = shift;
	my $inpStep = shift;
	my $layer   = 'c';

	while () {
		$inCAM->INFO( entity_type => 'layer', entity_path => "$pcbId/$inpStep/$layer", data_type => 'exists' );
		if ( $inCAM->{doinfo}{gEXISTS} eq "no" ) {
			$inCAM->PAUSE("Pro jednostranou desku chybí strana 'C' - uprav, pak pokracuj.");
		}
		else {
			last;
		}
	}
	return ();

}

sub _CheckREDresult {
	my $jobId    = shift;
	my $StepName = 'o+1';
	my $res      = 0;

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'check',
								 entity_path     => "$jobId/$StepName/clean_up",
								 data_type       => 'MEAS',
								 options         => "action=10+severity=R",
								 parse           => 'no'
	);

	my $size = -s $infoFile;
	if ($size) {
		$res = 1;
	}
	return ($res);
}

sub _SearchResultInReport {
	my $pcbId        = shift;
	my $reportPath   = shift;
	my $searchedItem = 'Arc not on single quadrant';
	my $res          = 0;

	open( REPORTFILE, $reportPath );
	while (<REPORTFILE>) {
		if ( $_ =~ /$searchedItem/ ) {
			$res = 1;
		}
	}
	close REPORTFILE;

	if ($res) {
		my @errorList = (
"POZOR - pri importu vrstev byla nalezena zavazna chyba (#Warning! Arc not on single quadrant. See parameter Enable arc when start/end on same axis in single quadrant mode). <b>Pro vice informaci vyhledej chybu ve OneNotu.</b>"
		);

		my $messMngr = MessageMngr->new($pcbId);
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@errorList );
	}
}

sub _ChangeStepsInMpanel {
	my $jobId = shift;

	my @repeats = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, 'mpanel' );

	my $line = 1;
	foreach my $j (@repeats) {

		my $origStep = __GetOrigStep( $j->{'gSRstep'} );
		if ($origStep) {
			CamStepRepeat->ChangeStepAndRepeat(
												$inCAM,        $jobId,            'mpanel',      $line,
												$origStep,     $j->{'gSRxa'},     $j->{'gSRya'}, $j->{'gSRdx'},
												$j->{'gSRdy'}, $j->{'gSRnx'},     $j->{'gSRny'}, $j->{'gSRangle'},
												'ccw',         $j->{'gSRmirror'}, $j->{'gSRflip'}
			);

			$line++;
		}
		else {
			my @errorList = 'Nemohu zmenit vsechny stepy v mpanelu na pracovni stepy, udelej to rucne!';
			my $messMngr  = MessageMngr->new($jobId);
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@errorList );    #  Script se zastavi
			last;
		}

	}
}

sub __GetOrigStep {
	my $origStep = shift;
	my $editStep = undef;

	if ( $origStep eq "o" || $origStep eq "input" || $origStep eq "pcb" || $origStep eq "pcbdata" ) {
		$editStep = 'o+1';
	}
	return ($editStep);
}

sub _SetCustomerAgain {
	my $jobId = shift;

	my $numberCustomer = HegMethods->GetIdcustomer($jobId);
	my @pole           = HegMethods->GetAllByPcbId($jobId);
	$customerName = $pole[0]->{'customer'};
	$customerName =~ s/,/./g;

	my $custIncamName = _GetInCamCustomer($numberCustomer);

	if ($custIncamName) {
		$inCAM->COM( 'set_job_customer', job => $jobId, customer => $numberCustomer, customer_name => $custIncamName );
	}

}

