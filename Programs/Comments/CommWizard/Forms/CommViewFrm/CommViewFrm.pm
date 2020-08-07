
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Comments::CommWizard::Forms::CommViewFrm::CommViewFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::CommFilesFrm';
use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::CommSugessFrm';
use aliased 'Programs::Comments::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# DEFINE PROPERTIES

	$self->{"commentId"} = undef;
	$self->{"jobId"}     = $jobId;

	$self->__SetLayout();

	# DEFINE EVENTS
	$self->{'onChangeTypeEvt'}     = Event->new();
	$self->{'onEditFileEvt'}       = Event->new();
	$self->{'onRemoveFileEvt'}     = Event->new();
	$self->{'onAddFileEvt'}        = Event->new();
	$self->{'onChangeFileNameEvt'} = Event->new();
	$self->{'onChangeNoteEvt'}     = Event->new();
	$self->{'onAddSuggesEvt'}      = Event->new();
	$self->{'onRemoveSuggesEvt'}   = Event->new();
	$self->{'onChangeSuggesEvt'}   = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szHead = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	#$self->SetBackgroundColour( Wx::Colour->new( 191, 209, 238 ) );

	# DEFINE CONTROLS
	#my $commNameTxt    = Wx::StaticText->new( $self, -1, "Number:", &Wx::wxDefaultPosition );
	#my $commNameValTxt = Wx::StaticText->new( $self, -1, "",        &Wx::wxDefaultPosition );

	#my $commTypeTxt = Wx::StaticText->new( $self, -1, "Type:", &Wx::wxDefaultPosition );
	my @cbVals = ( Enums->GetTypeTitle( Enums->CommentType_NOTE ), Enums->GetTypeTitle( Enums->CommentType_QUESTION ) );
	my $commTypeValTxt = Wx::ComboBox->new( $self, -1, $cbVals[0], [ -1, -1 ], [ 100, 22 ], \@cbVals, &Wx::wxCB_READONLY );

	my $commFilesBox = $self->__SetLayoutFiles($self);
	my $commTextBox  = $self->__SetLayoutText($self);
	my $commSuggBox  = $self->__SetLayoutSuggestion($self);

	# DEFINE EVENTS
	Wx::Event::EVT_TEXT( $commTypeValTxt, -1,
						 sub { $self->{"onChangeTypeEvt"}->Do( $self->{"commentId"}, Enums->GetTypeKey( $self->{"commTypeValTxt"}->GetValue() ) ) } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $szHead,       0,  &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $commFilesBox, 60, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $commTextBox,  20, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $commSuggBox,  20, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	#$szHead->Add( $commNameTxt,    0, &Wx::wxEXPAND | &Wx::wxLEFT, 2 );
	#$szHead->Add( $commNameValTxt, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 4 );
	#$szHead->Add( $commTypeTxt,    0, &Wx::wxEXPAND | &Wx::wxLEFT, 8 );
	$szHead->Add( $commTypeValTxt, 0, &Wx::wxEXPAND | &Wx::wxLEFT, 4 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"commFilesBox"} = $commFilesBox;

	#	$self->{"commNameValTxt"} = $commNameValTxt;
	$self->{"commTypeValTxt"} = $commTypeValTxt;

	$self->{"t"} = $szMain;
}

sub __SetLayoutFiles {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Files' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $commFilesFrm = CommFilesFrm->new($statBox);

	$szStatBox->Add( $commFilesFrm, 1, &Wx::wxEXPAND );

	# EVENTS
	$commFilesFrm->{'onRemoveFileEvt'}->Add( sub { $self->{"onRemoveFileEvt"}->Do( $self->{"commentId"}, @_ ) } );
	$commFilesFrm->{'onEditFileEvt'}->Add( sub { $self->{"onEditFileEvt"}->Do( $self->{"commentId"}, @_ ) } );
	$commFilesFrm->{'onAddFileEvt'}->Add( sub { $self->{"onAddFileEvt"}->Do( $self->{"commentId"}, @_ ) } );

	# SAVE REFERENCES
	$self->{"commFilesFrm"} = $commFilesFrm;

	return $szStatBox;
}

sub __SetLayoutText {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Text' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $richTxt = Wx::RichTextCtrl->new( $statBox, -1, 'Text...', &Wx::wxDefaultPosition, [ -1, -1 ], &Wx::wxRE_MULTILINE | &Wx::wxWANTS_CHARS );
	$richTxt->SetEditable(1);
	$richTxt->SetBackgroundColour($Widgets::Style::clrWhite);
	$szStatBox->Add( $richTxt, 1, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"richTxt"} = $richTxt;

	return $szStatBox;
}

sub __SetLayoutSuggestion {
	my $self   = shift;
	my $parent = shift;

	#define staticboxes
	my $statBox = Wx::StaticBox->new( $parent, -1, 'Suggestions' );
	my $szStatBox = Wx::StaticBoxSizer->new( $statBox, &Wx::wxVERTICAL );

	my $commSugessFrm = CommSugessFrm->new($statBox);

	#	$szMain->Add( $commSugessFrm, 0, &Wx::wxEXPAND );
	$szStatBox->Add( $commSugessFrm, 1, &Wx::wxEXPAND );

	# SAVE REFERENCES
	$self->{"commSugessFrm"} = $commSugessFrm;

	return $szStatBox;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetCommLayout {
	my $self     = shift;
	my $comentId = shift;
	my $layout   = shift;

	if ( $comentId < 0 ) {

		$self->Hide();
		return 0;
	}

	$self->{"commentId"} = $comentId;

	#$self->{"commNameValTxt"}->SetLabel( $comentId + 1 );

	$self->{"commTypeValTxt"}->SetValue( Enums->GetTypeTitle( $layout->GetType() ) );

	# Set Text

	$self->{"richTxt"}->Clear();
	$self->{"richTxt"}->WriteText( $layout->GetText() );

	$self->{"commFilesFrm"}->SetFilesLayout( [ $layout->GetAllFiles() ] );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

