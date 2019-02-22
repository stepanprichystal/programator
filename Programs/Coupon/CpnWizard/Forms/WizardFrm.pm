
#-------------------------------------------------------------------------------------------#
# Description: Wizard main form
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Coupon::CpnWizard::Forms::WizardFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party library
use Wx;
use strict;
use warnings;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Widgets::Forms::MyTaskBarIcon';
use aliased 'Helpers::GeneralHelper';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use Widgets::Style;
use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardCore';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::WizardStep1Frm';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::WizardStep2Frm';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep3::WizardStep3Frm';
use aliased 'Enums::EnumsGeneral';
use aliased 'Widgets::WxAsyncWorker::WxAsyncWorker';
use aliased 'Programs::Coupon::CpnWizard::CpnConfigMngr::CpnConfigMngr';
use aliased 'Programs::Coupon::CpnSource::CpnSource';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my @dimension = ( 1200, 680 );
	my $self = $class->SUPER::new( $parent, "Impedance coupon generator",
						 \@dimension,
						 &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX );

	bless($self);

	$self->{"jobId"}       = $jobId;
	$self->{"wizardSteps"} = {};

	# Properties
	$self->{"wizardCore"}  = undef;                                       # Main core of wizard
	$self->{"asyncWorker"} = WxAsyncWorker->new( $self->{"mainFrm"} );    # Helper for asznchrounous operation
	$self->{"configMngr"}  = CpnConfigMngr->new($jobId);                  # manager for storing used configuration
	$self->{"cpnSource"}   = CpnSource->new($jobId);                      # Parsed xml instack file

	return $self;
}

sub Init {
	my $self  = shift;
	my $inCAM = shift;

	my $jobId = $self->{"jobId"};

	# init wizard GUI steps
	$self->{"wizardSteps"}->{1} = WizardStep1Frm->new( $inCAM, $jobId, $self->{"mainFrm"}, $self->_GetMessageMngr(), $self->{"configMngr"} );

	$self->{"wizardSteps"}->{2} = WizardStep2Frm->new( $inCAM, $jobId, $self->{"mainFrm"}, $self->_GetMessageMngr() );

	$self->{"wizardSteps"}->{3} = WizardStep3Frm->new( $inCAM, $jobId, $self->{"mainFrm"}, $self->_GetMessageMngr() );

	$self->__SetLayout();

	# Properties
	$self->{"wizardCore"} = WizardCore->new( $inCAM, $jobId, scalar( keys %{ $self->{"wizardSteps"} } ), $self->{"asyncWorker"} );

	$self->{"wizardCore"}->InitByDefault( $self->{"cpnSource"} );

	$self->{"wizardCore"}->{"stepChangedEvt"}->Add( sub { $self->__StepChanged(@_) } );

	# Show first page
	$self->__StepChanged( $self->{"wizardCore"}->{"steps"}->[0] );
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	#define staticboxes

	my $szMain   = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szStatus = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $pnlMain  = Wx::Panel->new( $self->{"mainFrm"}, -1 );
	$pnlMain->SetBackgroundColour( Wx::Colour->new( 208, 15, 38 ) );

	# DEFINE CONTROLS
	my $statusTxt = Wx::StaticText->new( $pnlMain, -1, "-", &Wx::wxDefaultPosition );
	$statusTxt->SetFont( Wx::Font->new( 10, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL ) );
	$statusTxt->SetForegroundColour( Wx::Colour->new( 250, 250, 250 ) );
	my $gauge = Wx::Gauge->new( $pnlMain, -1, 100, [ -1, -1 ], [ 80, 20 ], &Wx::wxGA_HORIZONTAL );
	$gauge->SetValue(100);
	$gauge->Pulse();

	my $layoutSteps = $self->__SetLayoutSteps($pnlMain);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szStatus->Add( $statusTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szStatus->Add( $gauge,     0, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	$pnlMain->SetSizer($szMain);

	$szMain->Add( $szStatus,    0, &Wx::wxEXPAND | &Wx::wxALL, 5 );
	$szMain->Add( $layoutSteps, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->AddContent( $pnlMain, 0 );

	$self->SetButtonHeight(30);

	$self->{"beginBtn"} = $self->AddButton( "<< Begin", sub { $self->__BeginClick(@_) } );
	$self->{"backBtn"}  = $self->AddButton( "< Back",   sub { $self->__BackClick(@_) } );
	$self->{"nextBtn"}  = $self->AddButton( "Next >",   sub { $self->__NextClick(@_) } );
	$self->{"endBtn"}   = $self->AddButton( "End >>",   sub { $self->__EndClick(@_) } );

	# SET REFERENCES
	$self->{"statusTxt"} = $statusTxt;
	$self->{"gauge"}     = $gauge;
	$self->{"pnlMain"}   = $pnlMain;

	$gauge->Hide();

}

sub __SetLayoutSteps {
	my $self   = shift;
	my $parent = shift;

	my $stepBackg = Wx::Colour->new( 215, 215, 215 );

	#define staticboxes

	#my $btnDefault = Wx::Button->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $parent, -1 );
	$pnlMain->SetBackgroundColour($stepBackg);

	my $notebook = CustomNotebook->new( $pnlMain, -1 );

	#$szStatBox->Add( $btnDefault, 0, &Wx::wxEXPAND );

	foreach my $step ( keys %{ $self->{"wizardSteps"} } ) {

		$self->{"wizardSteps"}->{$step}->{"onStepWorking"}->Add( sub { $self->__StepWorkingHndl(@_) } );

		if ( $self->{"wizardSteps"}->{$step}->{"lastConfigEvt"} ) {
			$self->{"wizardSteps"}->{$step}->{"lastConfigEvt"}->Add( sub { $self->__LoadLastConfig(@_) } );
		}

		my $page = $notebook->AddPage( $step, 0 );

		$page->GetParent()->SetBackgroundColour($stepBackg);

		my $content = $self->{"wizardSteps"}->{$step}->GetLayout( $page->GetParent() );

		$page->AddContent( $content, 0 );
	}

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	$pnlMain->SetSizer($szMain);

	# SET REFERENCES
	$self->{"notebook"} = $notebook;

	return $pnlMain;
}

sub __StepChanged {
	my $self       = shift;
	my $wizardStep = shift;
	my $dir        = shift // "next";

	my $wizardStepFrm = $self->{"wizardSteps"}->{ $wizardStep->GetStepNumber() };

	$wizardStepFrm->Update($wizardStep);

	$self->{"notebook"}->ShowPage( $wizardStep->GetStepNumber() );

	# Change step description
	my $title = "Step " . $wizardStep->GetStepNumber() . "/" . scalar( keys %{ $self->{"wizardSteps"} } ) . ": " . $wizardStep->GetTitle();
	$self->{"statusTxt"}->SetLabel($title);

	# Allow/permit naveigation buttons

	$self->{"beginBtn"}->Enable();
	$self->{"backBtn"}->Enable();
	$self->{"nextBtn"}->Enable();
	$self->{"endBtn"}->SetLabel("End >>");

	if ( $wizardStep->GetStepNumber() == 1 ) {
		$self->{"beginBtn"}->Disable();
		$self->{"backBtn"}->Disable();
	}
	elsif ( $wizardStep->GetStepNumber() == scalar( keys %{ $self->{"wizardSteps"} } ) ) {
		$self->{"nextBtn"}->Disable();
		$self->{"endBtn"}->SetLabel("Finish");

	}

	print STDERR "StepChanged $wizardStep\n";
}

sub __StepWorkingHndl {
	my $self        = shift;
	my $workingType = shift;    # start/stop

	if ( $workingType eq "start" ) {

		$self->{"gauge"}->Show();
		$self->{"pnlMain"}->Disable();
		$self->{"beginBtn"}->Disable();
		$self->{"backBtn"}->Disable();
		$self->{"nextBtn"}->Disable();
		$self->{"endBtn"}->Disable();

	}
	else {

		$self->{"gauge"}->Hide();
		$self->{"pnlMain"}->Enable();
		$self->{"beginBtn"}->Enable();
		$self->{"backBtn"}->Enable();
		$self->{"nextBtn"}->Enable();
		$self->{"endBtn"}->Enable();
	}

}

sub __NextClick {
	my $self = shift;

	my $errMess = "";

	unless ( $self->{"wizardCore"}->Next( \$errMess ) ) {

		$self->_GetMessageMngr()->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Unable to continue to Next step. Error detail:\n$errMess"] );
	}

}

sub __EndClick {
	my $self = shift;

	my $errMess = "";

	# if last step, finish wizard
	if ( $self->{"wizardCore"}->GetCurrentStepNumber() == scalar( keys %{ $self->{"wizardSteps"} } ) ) {

		# 1) Get all config data from step 1 and store them
		my $step1 = $self->{"wizardCore"}->GetStep(1);

		my @cons = $self->{"cpnSource"}->GetConstraints();
		$self->{"configMngr"}->SaveConfig( $step1->GetConstrFilter(),
										   $step1->GetConstrGroups(),
										   $step1->GetGlobalSett(),
										   $step1->GetAllGroupSettings(),
										   $step1->GetAllStripSettings(), \@cons );

		# 2) finish coupon asynchronously
		my $wizardStepFrm = $self->{"wizardSteps"}->{ $self->{"wizardCore"}->GetCurrentStepNumber() };
		$wizardStepFrm->FinishCoupon();

	}
	else {

		unless ( $self->{"wizardCore"}->End( \$errMess ) ) {

			$self->_GetMessageMngr()->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Unable to continue to Next step. Error detail:\n$errMess"] );
		}
	}

}

sub __BackClick {
	my $self = shift;

	$self->{"wizardCore"}->Back();

}

sub __BeginClick {
	my $self = shift;

	$self->{"wizardCore"}->Begin();

}

my $self = shift;

sub __LoadLastConfig {
	my $self = shift;

	$self->{"configMngr"}->LoadConfig();

	my $userFilter     = $self->{"configMngr"}->GetUserFilter();        # keys represent strip id and value if strip is used in coupon
	my $userGroups     = $self->{"configMngr"}->GetUserGroups();        # contain strips splitted into group. Key is strip id, val is group number
	my $globalSett     = $self->{"configMngr"}->GetGlobalSett();        # global settings of coupon
	my $cpnGroupSett   = $self->{"configMngr"}->GetCpnGroupSett();      # group settings for each group
	my $cpnStripSett   = $self->{"configMngr"}->GetCpnStripSett();      # strip settings for each strip by constraint id
	my $cpnConstraints = $self->{"configMngr"}->GetCpnConstraints();    # strip settings for each strip by constraint id

	# Do same check before load new config
	my $messMngr = $self->_GetMessageMngr();
	my @strips   = $self->{"cpnSource"}->GetConstraints();

	# 1) Check strip count in old config is equal
	if ( scalar( keys %{$cpnStripSett} ) != scalar(@strips) ) {

		my @mess = ();
		push( @mess, "Unable to load old coupon configuration." );
		push( @mess,
			      "Number of constraints (<b>"
				. scalar( keys %{$cpnStripSett} )
				. "</b>) is diffrent from number of constraints in old configuration (<b>"
				. scalar(@strips)
				. "</b>)" );
		push( @mess, "\nConfiguration file: " );
		push( @mess, "- path   : " . $self->{"configMngr"}->GetConfigFilePath() );
		push( @mess, "- created: " . $self->{"configMngr"}->GetConfigFileDate( 1, 1 ) );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

		return 0;
	}

	# 2) Check if wizard contain all contraint id from old config
	foreach my $strip (@strips) {

		unless ( $cpnStripSett->{ $strip->GetId() } ) {
			my @mess = ();
			push( @mess, "Unable to load old coupon configuration." );
			push( @mess, "Constraint with id: <b>" . $strip->GetId() . " </b> was not found in old configuration file" );
			push( @mess, "\nConfiguration file:" );
			push( @mess, "- path   : " . $self->{"configMngr"}->GetConfigFilePath() );
			push( @mess, "- created: " . $self->{"configMngr"}->GetConfigFileDate( 1, 1 ) );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );

			return 0;
		}
	}

	# 3) Check constraint parameter
	my $res = 1;
	foreach my $strip (@strips) {

		my @mess = ( "Current constrain (id:" . $strip->GetId() . ") parameters are not equal to old configuration constraint parameters" );

		if ( $strip->GetType() ne $cpnConstraints->{ $strip->GetId() }->{"type"} ) {

			push( @mess,
				      "- Constraint type (<b>"
					. $strip->GetType()
					. "</b>) is not equal to old configuration constraint type (<b>"
					. $cpnConstraints->{ $strip->GetId() }->{"type"}
					. "</b>)" );
			$res = 0;
		}

		if ( $strip->GetModel() ne $cpnConstraints->{ $strip->GetId() }->{"model"} ) {

			push( @mess,
				      "- Constraint model (<b>"
					. $strip->GetModel()
					. "</b>) is not equal to old configuration constraint model (<b>"
					. $cpnConstraints->{ $strip->GetId() }->{"model"}
					. "</b>)" );
			$res = 0;
		}

		if ( $strip->GetTrackLayer() ne $cpnConstraints->{ $strip->GetId() }->{"layer"} ) {

			push( @mess,
				      "- Constraint instack layer (<b>"
					. $strip->GetTrackLayer()
					. "</b>) is not equal to old configuration constraint instack layer (<b>"
					. $cpnConstraints->{ $strip->GetId() }->{"layer"}
					. "</b>)" );
			$res = 0;
		}

		unless ($res) {
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess );
			return 0;
		}
	}

	# Load old configuration

	# 1) Init wizard by config
	$self->{"wizardCore"}->InitByConfig( $self->{"cpnSource"}, $userFilter, $userGroups, $globalSett );

	$self->{"wizardCore"}->LoadConfig( $cpnGroupSett, $cpnStripSett );

	#return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'HelperScripts::ChangePcbStatus::ChangeStatusFrm';

	my $result = 0;

	my $frm = ChangeStatusFrm->new( -1, "titulek", "zprava kfdfkdofkdofkd", \$result );

	$frm->ShowModal();

}

1;

