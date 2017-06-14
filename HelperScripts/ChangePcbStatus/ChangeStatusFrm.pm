#-------------------------------------------------------------------------------------------#
# Description: General simple form with input. Return value from input box
# Author:SPR
#-------------------------------------------------------------------------------------------#
package HelperScripts::ChangePcbStatus::ChangeStatusFrm;
use base 'Widgets::Forms::StandardModalFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class  = shift;
	my $parent = shift;

	#my $title   = shift;    # title on head of form
	#my $message = shift;    # message which is showed for user
	#my $result  = shift;    # reference of result variable, where result will be stored

	my @dimension = ( 700, 400 );
	my $self = $class->SUPER::new( $parent, "Change psb status",
						 \@dimension,
						 &Wx::wxSYSTEM_MENU | &Wx::wxCAPTION | &Wx::wxCLIP_CHILDREN | &Wx::wxRESIZE_BORDER | &Wx::wxMINIMIZE_BOX | &Wx::wxCLOSE_BOX );

	bless($self);

	$self->__SetLayout();

	# Properties

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	#define staticboxes

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $self, -1 );

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $layoutOrderBox  = $self->__SetLayoutOrder($pnlMain);
	my $layoutStepBox   = $self->__SetLayoutStep($pnlMain);
	my $layoutResultBox = $self->__SetLayoutResult($pnlMain);

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$pnlMain->SetSizer($szMain);

	$szMain->Add( $layoutOrderBox,  0, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $layoutStepBox,   1, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $layoutResultBox, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$self->AddContent($pnlMain);

	$self->SetButtonHeight(30);

	$self->AddButton( "Update \"Aktualni krok\"", sub { $self->__OkClick(@_) } );

	$self->__OnModeChangeHandler();

}

sub __SetLayoutOrder {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Order numbers' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $ordersTxt = Wx::StaticText->new( $statBox, -1, "Example : f12345-01; F12345-02", &Wx::wxDefaultPosition );
	my $ordersTxtXtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	Wx::Event::EVT_TEXT( $ordersTxtXtrl, -1, sub { $self->__OnOrderChanged(@_) } );

	$szStatBox->Add( $ordersTxt,     1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $ordersTxtXtrl, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"ordersTxtXtrl"} = $ordersTxtXtrl;

	return $szStatBox;
}

sub __SetLayoutStep {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Aktualni krok' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRow1  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2  = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRadio = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $pnlRadio = Wx::Panel->new( $statBox, -1 );

	# DEFINE CONTROLS
	my $rbDefined = Wx::RadioButton->new( $statBox, -1, "Defined", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, &Wx::wxRB_GROUP );
	my $rbCustom = Wx::RadioButton->new( $statBox, -1, "Custom", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	# ROW 1

	my $rbEmptyStep = Wx::RadioButton->new( $pnlRadio, -1, "\"\" (prázdná hodnota)", &Wx::wxDefaultPosition, &Wx::wxDefaultSize,, &Wx::wxRB_GROUP );
	my $rbPanelStep = Wx::RadioButton->new( $pnlRadio, -1, "\"k panelizaci\"", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $rbHotovoStep = Wx::RadioButton->new( $pnlRadio, -1, "\"HOTOVO-zadat\"", &Wx::wxDefaultPosition, &Wx::wxDefaultSize );
	my $rbZpracovaniAutoStep = Wx::RadioButton->new( $pnlRadio, -1, "\"zpracovani - auto\" (reorder bude automaticky zpracována)",
													 &Wx::wxDefaultPosition, &Wx::wxDefaultSize );

	# ROW2

	my $customTextCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	# SET EVENTS
	Wx::Event::EVT_RADIOBUTTON( $rbDefined, -1, sub { $self->__OnModeChangeHandler(@_) } );
	Wx::Event::EVT_RADIOBUTTON( $rbCustom,  -1, sub { $self->__OnModeChangeHandler(@_) } );

	

	# BUILD STRUCTURE OF LAYOUT

	# ROW 1
	$szRadio->Add( $rbEmptyStep,          0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRadio->Add( $rbPanelStep,          0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRadio->Add( $rbHotovoStep,         0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRadio->Add( $rbZpracovaniAutoStep, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$pnlRadio->SetSizer($szRadio);

	$szRow1->Add( $rbDefined, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $pnlRadio,  1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# ROW 2

	$szRow1->Add( $rbCustom,       0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $customTextCtrl, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szStatBox->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"customTextCtrl"} = $customTextCtrl;
	$self->{"rbDefined"}      = $rbDefined;
	$self->{"custom"}         = $customTextCtrl;
	$self->{"defined"}        = $pnlRadio;

	$self->{"rbEmptyStep"}          = $rbEmptyStep;
	$self->{"rbPanelStep"}          = $rbPanelStep;
	$self->{"rbHotovoStep"}         = $rbHotovoStep;
	$self->{"rbZpracovaniAutoStep"} = $rbZpracovaniAutoStep;

	return $szStatBox;
}

sub __SetLayoutResult {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Status' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $resultTxt = Wx::StaticText->new( $statBox, -1, "-", &Wx::wxDefaultPosition );

	$szStatBox->Add( $resultTxt, 1, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"resultTxt"} = $resultTxt;

	return $szStatBox;
}

sub __OnOrderChanged {
	my $self = shift;

	my $orders = $self->{"ordersTxtXtrl"}->GetValue();

	if ( $self->__OrderNumberMatch() ) {
		$self->__SetMessage("");
	}
	else {
		$self->__SetMessage( "Error in parsing \"Order numbers\"", "red" );
	}

}

#__OnCustomStepChanged

sub __SetMessage {
	my $self  = shift;
	my $mess  = shift;
	my $color = shift;

	$self->{"resultTxt"}->SetLabel($mess);

	if ( !defined $color ) {
		$color = Wx::Colour->new( 0, 0, 0 );

	}
	elsif ( $color eq "red" ) {

		$color = Wx::Colour->new( 255, 0, 0 );

	}
	elsif ( $color eq "green" ) {

		$color = Wx::Colour->new( 42, 160, 0 );
	}

	$self->{"resultTxt"}->SetForegroundColour( $color);

	$self->{"resultTxt"}->Refresh();

}

sub __OkClick {
	my $self = shift;
	
	

	if ( $self->__OrderNumberMatch() ) {
		
		$self->__SetMessage( "-");

		my $orders = $self->{"ordersTxtXtrl"}->GetValue();

		# get new step value
		my $newStep = undef;
		my $val = $self->{"rbDefined"}->GetValue();

		if ( defined $val && $val == 1 ) {

			if ( $self->{"rbEmptyStep"}->GetValue() == 1 ) {
				$newStep = "";
			}
			elsif ( $self->{"rbPanelStep"}->GetValue() == 1 ) {

				$newStep = "k panelizaci";
			}
			elsif ( $self->{"rbHotovoStep"}->GetValue() == 1 ) {

				$newStep = "HOTOVO-zadat";
			}
			elsif ( $self->{"rbZpracovaniAutoStep"}->GetValue() == 1 ) {

				$newStep = "zpracovani-auto";
			}
		}
		else {

			if ( $self->{"customTextCtrl"}->GetValue() ne "" ) {
				$newStep = $self->{"customTextCtrl"}->GetValue();
			}
		}

		
		if(!defined $newStep){
			return 0;
		}
		
		# parse orders
		my @orderIds = split(";", $orders);
		
		foreach my $id (@orderIds){
			
			$id =~ s/\s//g;
			$id = uc($id);
			
			my $res = HegMethods->UpdatePcbOrderState( $id, $newStep);
		}
		
		$self->__SetMessage( "$orders update SUCCESS", "green" );
 
	}

}

sub __OrderNumberMatch {
	my $self   = shift;
	my $result = 0;

	my $orders = $self->{"ordersTxtXtrl"}->GetValue();

	if ( defined $orders && $orders ne "" ) {

		if (
			$orders =~ m{
		 		^(\w\d+-\d{2}\s*;*\s*)$
				|
				^(\w\d+-\d{2}\s*;\s*)+(\w\d+-\d{2}\s*;?){1}$
			}xi
		  )
		{
			$result = 1;
		}

	}

	return $result;
}

# Control handlers
sub __OnModeChangeHandler {
	my $self = shift;

	my $val = $self->{"rbDefined"}->GetValue();

	if ( defined $val && $val == 1 ) {

		$self->{"custom"}->Disable();
		$self->{"defined"}->Enable();
	}
	else {

		$self->{"custom"}->Enable();
		$self->{"defined"}->Disable();

	}

	#$self->{"onTentingChange"}->Do( $chb->GetValue() );
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

