#-------------------------------------------------------------------------------------------#
# Description: General simple form with input. Return value from input box
# Author:SPR
#-------------------------------------------------------------------------------------------#
package HelperScripts::PcbNumbering::TestFrm;
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

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
 
	my $szClmn1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szClmn2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	my $boxLeft  = $self->__SetBoxLeft($self);
	my $boxRight  = $self->__SetBoxRight($self);
	 

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT
	

	$szMain->Add( $boxLeft,  100, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	$szMain->Add( $boxRight,  100, &Wx::wxEXPAND | &Wx::wxALL, 0 );
	

	$self->AddContent($szMain);

	$self->SetButtonHeight(30);

	$self->AddButton( "test", sub { $self->__TestClick(@_) } );

	 

}

sub __SetBoxLeft {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Left group' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );
	 

	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);


	# DEFINE CONTROLS

	my $testTxt = Wx::StaticText->new( $statBox, -1, "X", &Wx::wxDefaultPosition );
	my $testTxtXtrl = Wx::TextCtrl->new( $statBox, -1, "ttt", &Wx::wxDefaultPosition );
	
	my $test2Txt = Wx::StaticText->new( $statBox, -1, "Y", &Wx::wxDefaultPosition );
	my $test2TxtXtrl = Wx::TextCtrl->new( $statBox, -1, "ttt", &Wx::wxDefaultPosition );

	$szRow1->Add( $testTxt,     20, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szRow1->Add( $testTxtXtrl,     80, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	
	$szRow2->Add( $test2Txt,     20, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szRow2->Add( $test2TxtXtrl,     80, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );


	$szStatBox->Add( $szRow1,    0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $szRow2, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"testTxtXtrl"} = $testTxtXtrl;

	return $szStatBox;
}


sub __SetBoxRight {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Right group' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	# DEFINE CONTROLS

	my $testTxt = Wx::StaticText->new( $statBox, -1, "X", &Wx::wxDefaultPosition );
	my $testTxtXtrl = Wx::TextCtrl->new( $statBox, -1, "ttt", &Wx::wxDefaultPosition );

	$szStatBox->Add( $testTxt,     20, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );
	$szStatBox->Add( $testTxtXtrl, 80, &Wx::wxEXPAND | &Wx::wxLEFT, 0 );

	# Set References
	$self->{"testTxtXtrl"} = $testTxtXtrl;

	return $szStatBox;
}



sub __TestClick {
	my $self = shift;
 
	 print STDERR "test";
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

