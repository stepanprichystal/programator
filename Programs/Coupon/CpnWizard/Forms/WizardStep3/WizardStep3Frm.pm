
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep3::WizardStep3Frm;
use base('Programs::Coupon::CpnWizard::Forms::WizardStepFrmBase');

#3th party library
use threads;
use threads::shared;
use Wx;
use strict;
use warnings;

#local library

use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Programs::Coupon::CpnWizard::WizardCore::Helper';
use aliased 'Programs::Coupon::CpnBuilder::CpnBuilder';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
my $PROCESS_END_EVT : shared;    # evt raise when processing reorder is done

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub GetLayout {
	my $self   = shift;
	my $parent = shift;

	# DEFINE SIZERS + PANELS
	my $pnlMain     = Wx::Panel->new( $parent, -1 );
	my $szMain      = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szSettPanel = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szPreview   = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $pnlPreview = Wx::Panel->new( $pnlMain, -1 );
	$pnlPreview->SetBackgroundColour( Wx::Colour->new( 127, 127, 127 ) );
	$pnlPreview->SetForegroundColour( Wx::Colour->new( 250, 250, 250 ) );

	# DEFINE CONTROLS

	my $showInCAMBtn = Wx::Button->new( $pnlMain, -1, "Show in CAM", &Wx::wxDefaultPosition, [ 100, 30 ] );

	my $finalPrevTxt = Wx::StaticText->new( $pnlPreview, -1, "Coupon preview", &Wx::wxDefaultPosition, [ 100, 25 ] );
	my $previewTxt = Wx::TextCtrl->new( $pnlPreview, -1, "", &Wx::wxDefaultPosition, [ -1, -1 ], &Wx::wxTE_MULTILINE | &Wx::wxTE_READONLY );

	my $fontLbl = Wx::Font->new( 10, &Wx::wxFONTFAMILY_MODERN, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_NORMAL );
	$previewTxt->SetFont($fontLbl);

	# BUILD STRUCTURE OF LAYOUT
	$szSettPanel->Add( $showInCAMBtn, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	#$szSettPanel->Add( $gauge,        0, &Wx::wxEXPAND | &Wx::wxALL, 4 );

	$szPreview->Add( $finalPrevTxt, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szPreview->Add( $previewTxt,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szAutogenerate->Add( $szSettPanel, 0, &Wx::wxEXPAND | &Wx::wxALL, 4 );
	$szMain->Add( 1, 10, 0 );
	$szMain->Add( $szSettPanel, 0, &Wx::wxALL, 0 );
	$szMain->Add( 1, 10, 0 );
	$szMain->Add( $pnlPreview, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( 1, 5, 0 );

	$pnlPreview->SetSizer($szPreview);
	$pnlMain->SetSizer($szMain);

	# SET EVENTS

	Wx::Event::EVT_BUTTON( $showInCAMBtn, -1, sub { $self->__ShowInCAMAsync() } );
	
	$PROCESS_END_EVT = Wx::NewEventType;
	Wx::Event::EVT_COMMAND( $self->{"parentFrm"}, -1, $PROCESS_END_EVT, sub { $self->__GenerateCpnCallback(@_) } );

	# SET REFERENCES

	$self->{"previewTxt"} = $previewTxt;

	$self->{"szMain"}     = $szMain;
 

	return $pnlMain;

}

sub Update {
	my $self       = shift;
	my $wizardStep = shift;

	$self->{"coreWizardStep"} = $wizardStep;    # Update current step wizard

	my $cpnVariant = $self->{"coreWizardStep"}->GetCpnVariant();

	$self->{"previewTxt"}->SetValue( "\n" . $cpnVariant );
}

sub FinishCoupon {
	my $self = shift;

	$self->{"onStepWorking"}->Do("start");

	$self->RunAsyncWorker(\&$self->__GenerateCouponAsync, \&$self->__GenerateCpnCallback, [$self->{"jobId"}, 1], $self->{"inCAM"}); 

#	$self->{"inCAM"}->ClientFinish();
#
# 
#
#	#start new process, where check job before export
#	my $worker = threads->create( sub { $self->__GenerateCouponAsync( $self->{"jobId"}, 1, $self->{"inCAM"}->GetPort() ) } );
#	$worker->set_thread_exit_only(1);
#	$self->{"threadId"} = $worker->tid();

}

#sub __ShowInCAM {
#	my $self = shift;
#
#	my $inCAM = $self->{"inCAM"};
#
#	my $errMess = shift;
#	if ( $self->{"coreWizardStep"}->GenerateCoupon( 0, \$errMess ) ) {
#
#		$self->{"parentFrm"}->Hide();
#		$inCAM->PAUSE("Check Coupon...");
#		$self->{"parentFrm"}->Show();
#
#	}
#	else {
#
#		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, ["Error during generating coupon.\n\nError detail:\n$errMess"] );
#	}
#
#}
sub __ShowInCAMAsync {
	my $self = shift;
	
	$self->{"onStepWorking"}->Do("start");
	
	$self->RunAsyncWorker(\&$self->__GenerateCouponAsync, \&$self->__GenerateCpnCallback, [$self->{"jobId"}, 0], $self->{"inCAM"}); 
	

#	$self->{"inCAM"}->ClientFinish();
#
# 
#	#start new process, where check job before export
#	my $worker = threads->create( sub { $self->__GenerateCouponAsync( $self->{"jobId"}, 0, $self->{"inCAM"}->GetPort() ) } );
#	$worker->set_thread_exit_only(1);
#	$self->{"threadId"} = $worker->tid();
}

# ================================================================================
# PRIVATE WORKER (child thread) METHODS
# ================================================================================

sub __GenerateCouponAsync {
	my $self         = shift;
	my $inCAM = shift;
	my $jobId        = shift;
	my $wizardFinish = shift;
	 

#	my $inCAM = InCAM->new( "remote" => 'localhost', "port" => $serverPort );
#
#	$inCAM->ServerReady();

	my $result  = 1;
	my $errMess = "";

	eval {

		$result = $self->{"coreWizardStep"}->GenerateCouponAsync( $inCAM, $jobId,
																  $self->{"coreWizardStep"}->GetCpnLayout(),
																  $self->{"coreWizardStep"}->GetCpnGenerated(),
																  $wizardFinish, \$errMess );

	};
	if ($@) {

		$result = 0;
		$errMess .= "Unexpected error: " . $@;
	}

	$inCAM->ClientFinish();

	my %res : shared = ();

	$res{"result"}       = $result;
	$res{"errMess"}      = $errMess;
	$res{"finishWizard"} = $wizardFinish;
 
	return \%res;
}

# ================================================================================
# Private methods
# ================================================================================
 
sub __GenerateCpnCallback {
	my $self         = shift;
	my $resultData = shift;

	$self->{"onStepWorking"}->Do("stop");

#	# Reconnect again InCAM, after  was used by child thread
#	$self->{"inCAM"}->Reconnect();

	# Set progress bar
 
	#my %d = %{ $event->GetData };

	if ( $resultData->{"result"} ) {

		if ( $resultData->{"finishWizard"} ) {

			$self->{"inCAM"}->ClientFinish();
			$self->{"parentFrm"}->Close();
		}
		else {
			$self->{"parentFrm"}->Hide();
			$self->{"inCAM"}->PAUSE("Check Coupon...");
			$self->{"parentFrm"}->Show();

			$self->{"coreWizardStep"}->UpdateCpnGenerated(1);
		}
	}
	else {

		$self->{"messMngr"}->ShowModal( -1, EnumsGeneral->MessageType_ERROR, [ "Error during generating coupon.\nError detail:\n" . $resultData->{"errMess"} ] );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardCore';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13609";

}

1;

