#-------------------------------------------------------------------------------------------#
# Description: 
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnWizard::Forms::WizardStep1::GeneratorFrm;
use base 'Widgets::Forms::StandardModalFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Enums::EnumsGeneral';

#tested form

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class    = shift;
	my $parent   = shift;
	my $coreStep = shift;

	my $result = shift;

	my @dimension = ( 310, 360 );

	my $flags = &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX;

	my $self = $class->SUPER::new( $parent, "Groups generator", \@dimension, $flags );

	bless($self);

	

	# Properties
	$self->{"result"}         = $result;
	$self->{"coreWizardStep"} = $coreStep;
	$self->{"globalSett"} = $coreStep->GetGlobalSett();
	
	$self->__SetLayout();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $self, -1 );
	#my $stepBackg = Wx::Colour->new( 215, 215, 215 );
	#$pnlMain->SetBackgroundColour( $stepBackg );    #green

	my $settings = $self->__SetLayoutSett($pnlMain);

	# BUILD STRUCTURE OF LAYOUT
	$pnlMain->SetSizer($szMain);                                          # DEFINE LAYOUT STRUCTURE
	$szMain->Add( $settings, 1, &Wx::wxEXPAND, 1 );

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(20);

	$self->AddButton( "Generate", sub { $self->__GenerateClick(@_) } );

}

sub __SetLayoutSett {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Settings' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $maxTrackTxt = Wx::StaticText->new( $statBox, -1, "Max track in one layer", &Wx::wxDefaultPosition, [ 150, 25 ] );

	my $maxTrackSpinCtrl = Wx::SpinCtrl->new( $statBox, -1, $self->{"globalSett"}->GetMaxTrackCnt(), &Wx::wxDefaultPosition, [ -1, 25 ], &Wx::wxSP_ARROW_KEYS, 1, 6 );

	$szRow1->Add( $maxTrackTxt, 0, &Wx::wxEXPAND );

	$szRow1->Add( $maxTrackSpinCtrl, 1, &Wx::wxEXPAND );

	$szStatBox->Add( $szRow1, 0, &Wx::wxEXPAND );

	# EVENTS

	Wx::Event::EVT_SPINCTRL( $maxTrackSpinCtrl, -1, sub { $self->__OnMaxTrackChanged(@_) } );

	# SAVE REFERENCES
	$self->{"maxTrackSpinCtrl"} = $maxTrackSpinCtrl;

	return $szStatBox;
}

sub __GenerateClick {
	my $self = shift;

	${$self->{"result"}} = 1;

	if ( $self->{"coreWizardStep"}->AutogenerateGroups() ) {

		$self->Destroy();
	}
	else {
		$self->_GetMessageMngr->ShowModal( -1,
										   EnumsGeneral->MessageType_WARNING,
										   ["Unable to automatically generate coupon groups, change settings."] );    #  Script se zastavi
	}

}

sub __OnMaxTrackChanged {
	my $self = shift;

	my $v = $self->{"maxTrackSpinCtrl"}->GetValue();
	$self->{"globalSett"}->SetMaxTrackCnt($v);

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

#sub SetNotesData {
#	my $self = shift;
#	my $data = shift;
#
#	$self->{"noteList"}->SetNotesData($data);
#
#}
#
#sub GetNotesData {
#	my $self = shift;
#
#	return $self->{"noteList"}->GetNotesData();
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased "Programs::Coupon::CpnWizard::Forms::WizardStep1::GeneratorFrm";
	#
	#	my @dimension = ( 500, 800 );
	#
	my $test = GeneratorFrm->new(-1);

	#$test->{"mainFrm"}->Show();
	$test->ShowModal();
	#
	#	my $pnl = Wx::Panel->new( $test->{"mainFrm"}, -1, [ -1, -1 ], [ 100, 100 ] );
	#	$pnl->SetBackgroundColour($Widgets::Style::clrLightRed);
	#	$test->AddContent($pnl);
	#
	#	$test->SetButtonHeight(20);
	#
	#	$test->AddButton( "Set", sub { Test(@_) } );
	#	$test->AddButton( "EE",  sub { Test(@_) } );
	#	$test->MainLoop();
}

#sub Test {
#
#	print "yde";
#
#}

1;

