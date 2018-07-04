
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Coupon::CpnWizard::Forms::WizardFrm;
use base 'Widgets::Forms::StandardFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Widgets::Forms::MyTaskBarIcon';
use aliased 'Helpers::GeneralHelper';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';

use aliased 'Programs::Coupon::CpnWizard::WizardCore::WizardCore';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep1::WizardStep1Frm';
use aliased 'Programs::Coupon::CpnWizard::Forms::WizardStep2::WizardStep2Frm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	#my $title   = shift;    # title on head of form
	#my $message = shift;    # message which is showed for user
	#my $result  = shift;    # reference of result variable, where result will be stored

	my @dimension = ( 1200, 680 );
	my $self = $class->SUPER::new( $parent, "Impedance coupon generator",
						 \@dimension,
						 &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX );

	bless($self);

	$self->{"jobId"}       = $jobId;
	$self->{"wizardSteps"} = {};

	# Properties
	$self->{"wizardCore"} = undef;

	return $self;
}

sub Init {
	my $self  = shift;
	my $inCAM = shift;

	my $jobId = $self->{"jobId"};

	# init wizard GUI steps
	$self->{"wizardSteps"}->{1} = WizardStep1Frm->new( $inCAM, $jobId );

	#$self->{"wizardSteps"}->{2} = WizardStep2Frm->new( $inCAM, $jobId );

	#$self->{"wizardSteps"}->{2} = WizardStep2->new($inCAM, $jobId);

	$self->__SetLayout();

	# Properties
	$self->{"wizardCore"} = WizardCore->new( $inCAM, $jobId );
	my $xmlPath = 'c:\Export\CouponExport\cpn.xml';
	$self->{"wizardCore"}->Init($xmlPath);

	$self->{"wizardCore"}->{"stepChangedEvt"}->Add( sub { $self->__StepChanged(@_) } );

	# Show first page
	$self->__StepChanged( $self->{"wizardCore"}->{"steps"}->[0] );
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	#define staticboxes

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $self->{"mainFrm"}, -1 );

	# DEFINE CONTROLS
	my $statusTxt = Wx::StaticText->new( $pnlMain, -1, "Kork 1/1", &Wx::wxDefaultPosition );
	my $layoutSteps = $self->__SetLayoutSteps($pnlMain);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$pnlMain->SetSizer($szMain);

	$szMain->Add( $statusTxt,   0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $layoutSteps, 1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	
	

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(30);

	$self->AddButton( "<< Begin", sub { $self->__BeginClick(@_) } );
	$self->AddButton( "< Back",   sub { $self->__BackClick(@_) } );
	$self->AddButton( "Next >",   sub { $self->__NextClick(@_) } );
	$self->AddButton( "End >>",   sub { $self->__EndClick(@_) } );

}

sub __SetLayoutSteps {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes

	#my $btnDefault = Wx::Button->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );
	my $notebook = CustomNotebook->new( $parent, -1 );

	#$szStatBox->Add( $btnDefault, 0, &Wx::wxEXPAND );

	$self->{"notebook"} = $notebook;

	foreach my $step ( keys %{ $self->{"wizardSteps"} } ) {

		my $page = $notebook->AddPage($step);

		$page->GetParent()->SetBackgroundColour(Wx::Colour->new( 255, 255, 255 ));

		my $content = $self->{"wizardSteps"}->{$step}->GetLayout($page->GetParent());

		$page->AddContent($content);
	}

	return $notebook;
}

sub __StepChanged {
	my $self           = shift;
	my $wizardCoreStep = shift;

	my $wizardStepFrm = $self->{"wizardSteps"}->{ $wizardCoreStep->GetStepNumber() };

	$wizardStepFrm->Load($wizardCoreStep);

	$self->{"notebook"}->ShowPage( $wizardCoreStep->GetStepNumber() );

	#$self->{"mainFrm"}->Refresh();
	print STDERR "StepChanged $wizardCoreStep\n";
}

sub __NextClick {
	my $self = shift;

	$self->{"wizardCore"}->Next();

}

sub __BackClick {
	my $self = shift;

	$self->{"wizardCore"}->Back();

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

