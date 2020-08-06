
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListRowFrm;
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
	my $commLayout = shift;

	my $self = $class->SUPER::new( $parent, $order, undef );

	bless($self);

	# PROPERTIES
	$self->{"commLayout"} = $commLayout;

	$self->__SetLayout();

	# EVENTS

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS
	my $layout = $self->{"commLayout"};

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szInfoBox1 = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szInfoBox2 = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szInfoBox1Top = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szInfoBox1Bot = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	my $szInfoBox2Top = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szInfoBox2Bot = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $commStoredTxt = Wx::StaticText->new( $self, -1, "", &Wx::wxDefaultPosition, [5,-1]   );
	$commStoredTxt->SetFont($Widgets::Style::fontLblBold);
	my $commIdValTxt  = Wx::StaticText->new( $self, -1, "", &Wx::wxDefaultPosition );
	$commIdValTxt->SetFont($Widgets::Style::fontLblBold);

	#my $commTypeTxt    = Wx::StaticText->new( $self, -1, "Type", &Wx::wxDefaultPosition );
	my $commTypeValTxt = Wx::StaticText->new( $self, -1, "", &Wx::wxDefaultPosition );

	#my $commTextTxt    = Wx::StaticText->new( $self, -1, "Text", &Wx::wxDefaultPosition );
	my $commTextValTxt = Wx::StaticText->new( $self, -1, "", &Wx::wxDefaultPosition );

	my $commFilesTxt    = Wx::StaticText->new( $self, -1, "Files:", &Wx::wxDefaultPosition, [45,-1] );
	my $commFilesValTxt = Wx::StaticText->new( $self, -1, "",      &Wx::wxDefaultPosition );

	my $commSuggTxt    = Wx::StaticText->new( $self, -1, "Sugges: ", &Wx::wxDefaultPosition, [45,-1] );
	my $commSuggValTxt = Wx::StaticText->new( $self, -1, "",       &Wx::wxDefaultPosition );

	#$self->SetBackgroundColour( Wx::Colour->new( 255, 255, 255 ) );

	# DEFINE LAYOUT

	$szMain->Add( $commStoredTxt, 4, &Wx::wxALL | &Wx::wxALIGN_CENTER_VERTICAL, 2);
	$szMain->Add( $commIdValTxt,  10, &Wx::wxALL| &Wx::wxALIGN_CENTER_VERTICAL, 1 );
	$szMain->Add( $szInfoBox1,    60, &Wx::wxALL, 1 );
	$szMain->Add( $szInfoBox2,    30, &Wx::wxALL, 1 );

	$szInfoBox1->Add( $szInfoBox1Top, 50, &Wx::wxALL, 1 );
	$szInfoBox1->Add( $szInfoBox1Bot, 50, &Wx::wxALL, 1 );

	$szInfoBox2->Add( $szInfoBox2Top, 50, &Wx::wxALL, 1 );
	$szInfoBox2->Add( $szInfoBox2Bot, 50, &Wx::wxALL, 1 );

	#$szInfoBox1Top->Add( $commTypeTxt,    30, &Wx::wxALL, 1 );
	$szInfoBox1Top->Add( $commTypeValTxt, 100, &Wx::wxALL, 1 );

	#$szInfoBox1Bot->Add( $commTextTxt,    30, &Wx::wxALL, 1 );
	$szInfoBox1Bot->Add( $commTextValTxt, 100, &Wx::wxALL, 1 );

	$szInfoBox2Top->Add( $commFilesTxt,    0, &Wx::wxALL, 1 );
	$szInfoBox2Top->Add( $commFilesValTxt, 0, &Wx::wxALL, 1 );

	$szInfoBox2Bot->Add( $commSuggTxt,    0, &Wx::wxALL, 1 );
	$szInfoBox2Bot->Add( $commSuggValTxt, 0, &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES
	$self->{"commStoredTxt"}   = $commStoredTxt;
	$self->{"commIdValTxt"}    = $commIdValTxt;
	$self->{"commTypeValTxt"}  = $commTypeValTxt;
	$self->{"commTextValTxt"}  = $commTextValTxt;
	$self->{"commFilesValTxt"} = $commFilesValTxt;
	$self->{"commSuggValTxt"}  = $commSuggValTxt;

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
	$self->{"commIdValTxt"}->SetLabel( $self->GetPosition() );

	$self->{"commTypeValTxt"}->SetLabel( Enums->GetTypeTitle( $commLayout->GetType() ) );

	$self->{"commTextValTxt"}->SetLabel( $commLayout->GetText() );
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
