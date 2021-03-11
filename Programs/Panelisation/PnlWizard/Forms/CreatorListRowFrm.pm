
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
use aliased 'Programs::Comments::Enums';
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

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);



	# DEFINE CONTROLS
	 
	my $creatorNameTxt = Wx::StaticText->new( $self, -1, $creatorModel->GetModelKey(), &Wx::wxDefaultPosition );
 
	#$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	# DEFINE LAYOUT

	$szMain->Add( $creatorNameTxt, 4, &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL, 2);
	 

	 
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
sub SetCommentLayout {
	my $self       = shift;
	my $commLayout = shift;

	$self->{"commStoredTxt"}->SetLabel( !$commLayout->GetStoredOnDisc()?"*": "" );
	$self->{"commIdValTxt"}->SetLabel( $self->GetPosition() +1 );

	$self->{"commTypeValTxt"}->SetLabel( Enums->GetTypeTitle( $commLayout->GetType() ) );

	# first 15 char without new lines
	my $note = $commLayout->GetText();
	
	if($note eq ""){
		
		$note = "-"
	}else{
		$note =~ s/\n/ /ig;
		$note =  substr($note, 0, 20)." ...";
	}
	
	$self->{"commTextValTxt"}->SetLabel($note);
	$self->{"commFilesValTxt"}->SetLabel( scalar( $commLayout->GetAllFiles() ) );
	$self->{"commSuggValTxt"}->SetLabel( scalar( $commLayout->GetAllSuggestions() ) );

}

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
