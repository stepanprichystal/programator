
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlWizard::Forms::CreatorListRowFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueueItem);

#3th party library
use utf8;
use Wx;

use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Panelisation::PnlWizard::EnumsStyle';
use Widgets::Style;


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class      = shift;
	my $parent     = shift;
	my $order      = shift;
	my $creatorModel = shift;

	my $self = $class->SUPER::new( $parent, $order, undef );

	bless($self);

	# PROPERTIES
	 

	$self->__SetLayout($creatorModel);

	# EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;
	my $creatorModel = shift;

	# DEFINE SIZERS
	my $layout = $self->{"commLayout"};

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);



	# DEFINE CONTROLS
	 
	my $tit =  EnumsStyle->GetCreatorTitle($creatorModel->GetModelKey());
	 
	my $creatorNameTxt = Wx::StaticText->new( $self, -1, $tit, &Wx::wxDefaultPosition, [-1, -1] );
 
	#$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	# DEFINE LAYOUT

	$szMain->Add( $creatorNameTxt, 1, &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL, 6);
	$szMain->Add(163,0,0); # keep width
	 

	 
	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES
	$self->{"creatorNameTxt"}   = $creatorNameTxt;
	 
	$self->RecursiveHandler($self);
}

# ==============================================
# ITEM QUEUE HANDLERS
# ==============================================

# ==============================================
# PUBLIC FUNCTION
# ==============================================
 

# ==============================================
# HELPER FUNCTION
# ==============================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
