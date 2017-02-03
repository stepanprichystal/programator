#-------------------------------------------------------------------------------------------#
# Description: General simple form with input. Return value from input box
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Widgets::Forms::SimpleInput::SimpleInputFrm;
use base 'Widgets::Forms::StandardModalFrm';

#3th party librarysss
use strict;
use warnings;
use Wx;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {

	my $class   = shift;
	my $parent  = shift;
	my $title   = shift;    # title on head of form
	my $message = shift;    # message which is showed for user
	my $result  = shift;    # reference of result variable, where result will be stored

	my @dimension = ( 700, 300 );
	my $self = $class->SUPER::new( $parent, $title, \@dimension );

	bless($self);

	$self->{"message"}    = $message;
	$self->{"result"}     = $result;
	$self->{"scriptName"} = caller();

	$self->__SetLayout();

	# Properties

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE CONTROLS

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $self, -1, 'Simple input form' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $szRowDetail1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRowDetail3 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $scriptTxt    = Wx::StaticText->new( $statBox, -1, "Script :",            &Wx::wxDefaultPosition );
	my $scriptTxtVal = Wx::StaticText->new( $statBox, -1, $self->{"scriptName"}, &Wx::wxDefaultPosition );
	my $textTxt      = Wx::StaticText->new( $statBox, -1, "Text   :",            &Wx::wxDefaultPosition );
	my $textTxtVal   = Wx::StaticText->new( $statBox, -1, $self->{"message"},    &Wx::wxDefaultPosition );
	my $inputTxt     = Wx::StaticText->new( $statBox, -1, "Input :",             &Wx::wxDefaultPosition );
	my $inputTxtCtrl = Wx::TextCtrl->new( $statBox, -1, "", &Wx::wxDefaultPosition );

	# SET EVENTS

	# BUILD STRUCTURE OF LAYOUT

	$szRowDetail1->Add( $scriptTxt,    1, &Wx::wxALL, 0 );
	$szRowDetail1->Add( $scriptTxtVal, 9, &Wx::wxALL, 0 );

	$szRowDetail2->Add( $textTxt,    1, &Wx::wxALL, 0 );
	$szRowDetail2->Add( $textTxtVal, 9, &Wx::wxALL, 0 );

	$szRowDetail3->Add( $inputTxt, 1, &Wx::wxALL, 0 );
	$szRowDetail3->Add( $inputTxtCtrl, 9, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	$szStatBox->Add( $szRowDetail1, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( 10, 10, 0 );
	$szStatBox->Add( $szRowDetail2, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szStatBox->Add( $szRowDetail3, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	# Set References
	$self->{"textTxtVal"}   = $textTxtVal;
	$self->{"inputTxtCtrl"} = $inputTxtCtrl;

	$self->AddContent($szStatBox);

	$self->SetButtonHeight(20);

	$self->AddButton( "Ok", sub { $self->__OkClick(@_) } );

}

sub __OkClick {
	my $self = shift;
	${ $self->{"result"} } = $self->{"inputTxtCtrl"}->GetValue();
	$self->Destroy();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';

	my $result = 0;

	my $frm = SimpleInputFrm->new( -1, "titulek", "zprava kfdfkdofkdofkd", \$result );

	$frm->ShowModal();

	print "vysledek je:" . $result;

	sleep(2);

}

1;

