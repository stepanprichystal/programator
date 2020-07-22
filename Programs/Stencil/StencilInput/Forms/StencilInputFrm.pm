#-------------------------------------------------------------------------------------------#
# Description: Form,  which create stencil job either from customer data or from existing job
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Stencil::StencilInput::Forms::StencilInputFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use utf8;
use strict;
use warnings;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use Wx;
use aliased 'Packages::Events::Event';

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamHistogram';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;

	my @dimension = ( 400, 300 );
	my $self = $class->SUPER::new( $parent, "Stencil input", \@dimension );

	bless($self);

	# Properties
	$self->{"inCAM"} = $inCAM;

	# Events

	$self->__SetLayout();

	$self->{"mainFrm"}->Show(1);

	return $self;
}

sub OnInit {
	my $self = shift;

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Public methods
#-------------------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#
sub __InputExistingJob {
	my $self = shift;
	my $path = shift;

	my $inCAM = $self->{"inCAM"};

	my $sourceJobId = $self->{"sourceJobIdValTxt"}->GetValue();
	my $jobId       = $self->{"jobIdValTxt"}->GetValue();

	# validity of job
	if ( $sourceJobId !~ /\w\d+/i ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Jméno zdrojového jobu není validní -  $sourceJobId"] );
		return 0;
	}

	# test if exist source job
	if ( !CamJob->JobExist( $inCAM, $sourceJobId ) ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_WARNING, ["Job neexistuje v databázi, musíš ho nejprve odarchivovat."] );
		return 0;
	}

	# validity of stencil job
	if ( $jobId !~ /\w\d+/i ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Jméno stencil jobu není validní -  $jobId"] );
		return 0;
	}

	# test if  stencil job is type of stencil

	if ( HegMethods->GetTypeOfPcb($jobId) ne 'Sablona' ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Job šablony $jobId není v IS veden jako typ dps - šablona."] );
		return 0;
	}

	# Check if job already exist
	if ( CamJob->JobExist( $inCAM, $jobId ) ) {

		$self->{"messMngr"}
		  ->ShowModal( -1, EnumsGeneral->MessageType_WARNING, ["Job šablony $jobId již existuje, cheš ho přemazat?"], [ "Ano", "Ne" ] );
		if ( $self->{"messMngr"}->Result() == 1 ) {
			return 0;
		}

		unless ( $self->__DeleteJob($jobId) ) {

			$self->{"mainFrm"}->Show();
			return 0;

		}
	}

	$self->{"mainFrm"}->Hide();

	# create new job
	$self->__CreateJob($jobId);

	#  Copy suitable steps from source job
	my @steps = ();

	if ( HegMethods->GetPcbIsPool($sourceJobId) ) {
		@steps = ("o+1");

	}
	else {

		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $sourceJobId, "panel" );
	}

	# open source job
	my $closeJob = 0;
	unless ( CamJob->IsJobOpen( $inCAM, $sourceJobId ) ) {

		$closeJob = 1;
		$inCAM->COM( "open_job", job => "$sourceJobId", "open_win" => "no" );

	}

	foreach my $step (@steps) {

		# check if step is not already exist
		my $oriStepName = "ori_" . $sourceJobId . "_" . $step;

		if ( CamHelper->StepExists( $inCAM, $jobId, $oriStepName ) ) {
			next;
		}

		CamStep->CopyStep( $inCAM, $sourceJobId, $step, $jobId, $oriStepName );

		# when we copy step with S&R from other job, all steps are copied to
		# so rename nested step in order to avoid name conflicts
		if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $sourceJobId, $step ) ) {

			my @sr = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $sourceJobId, $step );

			# rename all nested steps in panel to ori_<job id>_<original nested name>
			foreach my $sr (@sr) {

				my $newName = "ori_" . $sourceJobId . "_" . $sr->{"stepName"};
				CamStep->RenameStep( $inCAM, $jobId, $sr->{"stepName"}, $newName );
			}
		}
	}

	if ($closeJob) {
		CamJob->CloseJob( $inCAM, $sourceJobId );
	}

	$inCAM->COM( "open_job", job => "$jobId", "open_win" => "yes" );

	# remove all useless layers, keep only sa-ori, sb-ori, or sa-made, sb-made
	my @del = grep { $_->{"gROWname"} !~ /^(s[ab]-(ori|made))|(o)$/ } CamJob->GetAllLayers( $inCAM, $jobId );

	foreach my $l (@del) {
		$inCAM->COM( 'delete_layer', layer => $l->{"gROWname"} );
	}

	while ( !scalar( grep { $_->{"gROWname"} =~ /s[ab]-(ori|made)/ } CamJob->GetAllLayers( $inCAM, $jobId ) ) ) {

		$self->{"messMngr"}->ShowModal( -1,
										EnumsGeneral->MessageType_INFORMATION,
										["Nebyly nalezeny vrstvy sa-ori, sb-ori nebo sa-made, sb-made"],
										[ "Pořeším to", "Ukončit script" ] );

		if ( $self->{"messMngr"}->Result() == 1 ) {
			$self->{"mainFrm"}->Destroy();
		}

		$inCAM->PAUSE("Vytvor vrstvy sa-ori, sb-ori nebo sa-made, sb-made...");
	}

	$inCAM->COM( "delete_entity", "job" => $jobId, "name" => "o", "type" => "step" );
	$inCAM->COM( "set_subsystem", "name" => "1-Up-Edit" );
	$self->__RunStencilCreator($jobId);

}

sub __InputCustomerData {
	my $self = shift;
	my $path = shift;

	my $inCAM = $self->{"inCAM"};

	$path = lc($path);

	# Recognise if path is r/pcb or c/pcb

	# get root dir (jobid name) of path

	my ( $oriRoot, $disc, $jobId ) = $path =~ m/(([\w]):.?pcb.?(\w\d+)).?/i;

	# if no job folder choosed
	if ( $jobId !~ /\w\d+/i ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Nebyl vybrán adresář se jménem jobu: $path"] );
		return 0;
	}

	$self->{"mainFrm"}->Hide();

	my $root = $oriRoot;
	$root =~ s/^r:/c:/i;

	# move to c/pcb
	if ( $disc =~ /r/i ) {

		my $copyCnt = dirmove( $oriRoot, $root );
	}

	# Check if job already exist
	if ( CamJob->JobExist( $inCAM, $jobId ) ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_WARNING, ["Job $jobId již existuje, cheš ho přemazat?"], [ "Ano", "Ne" ] );
		if ( $self->{"messMngr"}->Result() == 1 ) {
			$self->{"mainFrm"}->Show();
			return 0;
		}

		unless ( $self->__DeleteJob($jobId) ) {

			$self->{"mainFrm"}->Show();
			return 0;

		}
	}

	# Input new data

	my $oriStep = "ori_data";

	$self->__CreateJob($jobId);

	CamHelper->SetStep( $inCAM, "o" );
	$inCAM->COM(
				 "rename_entity",
				 "job"      => $jobId,
				 "name"     => "o",
				 "new_name" => $oriStep,
				 "is_fw"    => "no",
				 "type"     => "step",
				 "fw_type"  => "form"
	);
	$inCAM->COM( "input_create",   "path" => "$root" );
	$inCAM->COM( "input_identify", "job"  => $jobId );

	my @mess = (
				 "Načti správně data do výchozího stepu \"$oriStep\".\nTzn. vytvoř v matrixu následující vrstvy:\n",
				 " - <b>sa-ori</b> => pokud je šablona pro TOP",
				 " - <b>sb-ori</b> => pokud je šablona pro BOT",
				 " - <b>o</b> => obrys šablony (rozměry materiálu)"
	);

	$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

	$inCAM->PAUSE("Nacti spravne data (vytvor vrstvy sa-ori; sb-ori; o), a pokracuj..");

	# test if sa-ori or sb-ori exist
	#my @layers = grep {$_->{"gROWname"} =~ /s[ab]-ori/ } CamJob->GetAllLayers($inCAM, $jobId);

	while ( !scalar( grep { $_->{"gROWname"} =~ /s[ab]-ori/ } CamJob->GetAllLayers( $inCAM, $jobId ) ) ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, ["Nebyly nalezeny vrstvy \"sa-ori\" nebo \"sb-ori\""] );

		$inCAM->PAUSE("Vytvor vrstvy sa-ori nebo sb-ori...");
	}

	while ( !scalar( grep { $_->{"gROWname"} =~ /^o$/ } CamJob->GetAllLayers( $inCAM, $jobId ) ) ) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, ["Nebyla nalezena vrstva obrysu šablony \"o\""] );

		$inCAM->PAUSE("Vytvor vrstvu obrysu sablony o");
	}

	# Move data to zero
	my %lLim = CamJob->GetLayerLimits( $inCAM, $jobId, $oriStep, "o" );
	my %source = ( "x" => $lLim{"xmin"}, "y" => $lLim{"ymin"} );
	my %target = ( "x" => 0, "y" => 0 );

	# move layer
	foreach my $l ( map { $_->{"gROWname"} } CamJob->GetAllLayers( $inCAM, $jobId ) ) {
		CamLayer->WorkLayer( $inCAM, $l );
		CamLayer->MoveSelSameLayer( $inCAM, $l, \%source, \%target );
	}

	# Create profile

	my $profExist = sub {
 
		my $profL = "o";

		return 0 unless ( CamHelper->LayerExists( $inCAM, $jobId, $profL ) );

		my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $oriStep, $profL );
		return 0 if ( $fHist{"line"} != 4 );

		# try to create profile
		$inCAM->SupressToolkitException(1);
		$inCAM->HandleException(1);

		CamStep->CreateProfileByLayer( $inCAM, $oriStep, $profL );

		my $err = $inCAM->GetExceptionError();

		if ($err) {
			return 0;
		}

		$inCAM->HandleException(0);
		$inCAM->SupressToolkitException(0);

		return 1;
	};

	while ( !$profExist->() ) {

		$self->{"messMngr"}->ShowModal( -1,
									  EnumsGeneral->MessageType_INFORMATION,
									  [ "Nepodařilo se vytvořit profil.", "Vytvoř vrstvu \"o\" s obrysem šablony nebo udělej profil ručně" ] );

		$inCAM->PAUSE("Vytvor profil...");

	}

	# set sa-ori and sb-ori as type document
	foreach my $l ( grep { $_->{"gROWname"} =~ /^(s[ab]-ori)|(o)$/ } CamJob->GetAllLayers( $inCAM, $jobId ) ) {
		CamLayer->SetLayerTypeLayer( $inCAM, $jobId, $l->{"gROWname"}, "document" );
	}

	# move customer data to archive
	my $p = JobHelper->GetJobArchive($jobId) . "\\Zdroje\\data";
	unless ( -e $p ) {
		mkdir($p) or die "Can't create dir: " . $p . $_;
	}

	my $copyCnt = dirmove( $root, $p );

	$self->__RunStencilCreator($jobId);
}

sub __RunStencilCreator {
	my $self  = shift;
	my $jobId = shift;

	my $inCAM = $self->{"inCAM"};

	eval {

		while (1) {

			system( 'perl ' . GeneralHelper->Root() . '\Programs\Stencil\StencilCreator\RunStencil\RunStencilApp.pl ' . $jobId );

			my $o1Exist  = CamHelper->StepExists( $inCAM, $jobId, "o+1" );
			my $pnlExist = CamHelper->StepExists( $inCAM, $jobId, "panel" );

			# If o+1 and panel exist, stencil creator was succes
			if ( $o1Exist && $pnlExist ) {

				last;
			}
			else {

				if ( $inCAM->PAUSE("Oprav chybu a pokračuj...") ne "OK" ) {

					last;
				}

			}

		}

	};
	if ($@) {
		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, [ "Error during launch stencil creator app." . $@ ] );

	}

	$self->{"mainFrm"}->Destroy();

}

sub __DeleteJob {
	my $self  = shift;
	my $jobId = shift;

	my $inCAM = $self->{"inCAM"};

	$inCAM->HandleException(1);

	CamJob->DeleteJob( $inCAM, $jobId );

	my $err = $inCAM->GetExceptionError();

	$inCAM->HandleException(0);

	if ($err) {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during delete job: $err"] );
		return 0;
	}

	return 1;
}

sub __CreateJob {
	my $self  = shift;
	my $jobId = shift;

	my $inCAM = $self->{"inCAM"};

	$inCAM->COM( "new_job", "name" => $jobId, "db" => "incam", "customer" => "", "disp_name" => "", "notes" => "", "attributes" => "" );
	$inCAM->COM( "check_inout", "mode" => "out", "type" => "job", "job" => $jobId );
	$inCAM->COM( "open_job", "job" => $jobId, "open_win" => "yes" );

	my $userName = $ENV{"LOGNAME"};
	CamAttributes->SetJobAttribute( $inCAM, $jobId, "user_name", $userName );
}

#-------------------------------------------------------------------------------------------#
#  Layout methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	#define panels
	my $pnlMain = Wx::Panel->new( $self->{"mainFrm"}, -1 );
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $general = $self->__SetLayoutGeneral($pnlMain);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szMain->Add( $general, 1, &Wx::wxALL, 1 );

	$pnlMain->SetSizer($szMain);

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(30);

	$self->AddButton( "Ok", sub { $self->__InputExistingJob(@_) } );

	$self->{"szMain"} = $szMain;

}

# Set layout general group
sub __SetLayoutGeneral {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'General' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow4 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $typeTxt = Wx::StaticText->new( $statBox, -1, "Source", &Wx::wxDefaultPosition, [ 170, 22 ] );

	my @types = ();
	push( @types, "Existing job" );
	push( @types, "Customer data" );

	my $typeCb = Wx::ComboBox->new( $statBox, -1, $types[0], &Wx::wxDefaultPosition, [ 120, 25 ], \@types, &Wx::wxCB_READONLY );

	my $sourceJobIdTxt = Wx::StaticText->new( $statBox, -1, "Source job id", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $sourceJobIdValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 60, 22 ] );

	my $jobIdTxt = Wx::StaticText->new( $statBox, -1, "Stencil job id", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $jobIdValTxt = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition, [ 60, 22 ] );

	my $openFileTxt = Wx::StaticText->new( $statBox, -1, "Choose file", &Wx::wxDefaultPosition, [ 170, 22 ] );
	my $btnR = Wx::Button->new( $statBox, -1, "R:pcb", &Wx::wxDefaultPosition, [ 60, 25 ] );
	my $btnC = Wx::Button->new( $statBox, -1, "C:pcb", &Wx::wxDefaultPosition, [ 60, 25 ] );

	#    if( $dialog->ShowModal == wxID_CANCEL ) {
	#        Wx::LogMessage( "User cancelled the dialog" );
	#    } else {
	#        Wx::LogMessage( "Wildcard: %s", $dialog->GetWildcard);
	#        my @paths = $dialog->GetPaths;
	#
	#        if( @paths > 0 ) {
	#            Wx::LogMessage( "File: $_" ) foreach @paths;
	#        } else {
	#            Wx::LogMessage( "No files" );
	#        }
	#
	#        $self->previous_directory( $dialog->GetDirectory );

	# SET EVENTS
	Wx::Event::EVT_TEXT( $typeCb, -1, sub { $self->__OnSourceChanged(@_) } );
	Wx::Event::EVT_BUTTON( $btnR, -1, sub { $self->__OnChooseDir("r") } );
	Wx::Event::EVT_BUTTON( $btnC, -1, sub { $self->__OnChooseDir("c") } );

	# BUILD STRUCTURE OF LAYOUT

	$szRow1->Add( $typeTxt, 50, &Wx::wxALL, 1 );
	$szRow1->Add( $typeCb,  50, &Wx::wxALL, 1 );

	$szRow2->Add( $sourceJobIdTxt,    50, &Wx::wxALL, 1 );
	$szRow2->Add( $sourceJobIdValTxt, 50, &Wx::wxALL, 1 );

	$szRow3->Add( $jobIdTxt,    50, &Wx::wxALL, 1 );
	$szRow3->Add( $jobIdValTxt, 50, &Wx::wxALL, 1 );

	$szRow4->Add( $openFileTxt, 50, &Wx::wxALL, 1 );
	$szRow4->Add( $btnR,        25, &Wx::wxALL, 1 );
	$szRow4->Add( $btnC,        25, &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( 10,      10, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow2, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow3, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRow4, 0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"stencilTypeCb"} = $typeCb;

	$self->{"jobIdTxt"}    = $jobIdTxt;
	$self->{"jobIdValTxt"} = $jobIdValTxt;

	$self->{"sourceJobIdTxt"}    = $sourceJobIdTxt;
	$self->{"sourceJobIdValTxt"} = $sourceJobIdValTxt;

	$self->{"openFileTxt"} = $openFileTxt;

	$self->{"btnR"}   = $btnR;
	$self->{"btnC"}   = $btnC;
	$self->{"szRow2"} = $szRow2;

	$self->__DisableControls();

	return $szStatBox;
}

sub __OnSourceChanged {
	my $self = shift;

	$self->__DisableControls();
}

sub __OnChooseDir {
	my $self  = shift;
	my $place = shift;    #c/r

	my $dirDialog = undef;

	if ( $place eq "r" ) {

		$dirDialog = Wx::FileDialog->new( $self->{"mainFrm"}, "Select directory with data", "r:/pcb" );

	}
	elsif ( $place eq "c" ) {

		$dirDialog = Wx::FileDialog->new( $self->{"mainFrm"}, "Select directory with data", "c:/pcb" );

	}

	if ( $dirDialog->ShowModal() != &Wx::wxID_CANCEL ) {

		my @paths = $dirDialog->GetPaths;

		$self->__InputCustomerData( $paths[0] );
	}

}

sub __DisableControls {
	my $self = shift;

	if ( $self->{"stencilTypeCb"}->GetSelection() == 0 ) {

		$self->{"jobIdValTxt"}->Show();
		$self->{"jobIdTxt"}->Show();
		$self->{"sourceJobIdTxt"}->Show();
		$self->{"sourceJobIdValTxt"}->Show();

		$self->{"openFileTxt"}->Hide();
		$self->{"btnR"}->Hide();
		$self->{"btnC"}->Hide();

	}
	else {

		$self->{"jobIdValTxt"}->Hide();
		$self->{"jobIdTxt"}->Hide();
		$self->{"sourceJobIdTxt"}->Hide();
		$self->{"sourceJobIdValTxt"}->Hide();
		$self->{"openFileTxt"}->Show();
		$self->{"btnR"}->Show();
		$self->{"btnC"}->Show();

	}

	$self->{"mainFrm"}->Layout();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Stencil::StencilInput::Forms::StencilInputFrm';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $test = StencilInputFrm->new( -1, $inCAM, );

	# $test->Test();
	$test->MainLoop();

}

1;

