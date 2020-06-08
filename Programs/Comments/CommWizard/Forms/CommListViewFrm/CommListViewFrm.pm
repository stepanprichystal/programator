
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListViewFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Comments::CommWizard::Forms::CommListViewFrm::CommListFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $jobId  = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"jobId"} = $jobId;

	$self->__SetLayout();

	# DEFINE EVENTS
	$self->{'onRemoveCommentEvt'}  = Event->new();
	$self->{'onMoveCommentEvt'}    = Event->new();
	$self->{'onAddCommentEvt'}     = Event->new();
	$self->{"onSelCommChangedEvt"} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	my $szMain     = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szBtns     = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szBtnsMove = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# Add empty item

	# DEFINE CONTROLS
	my $commList = CommListFrm->new($self);

	my $btnRemove   = Wx::Button->new( $self, -1, "- Remove",  &Wx::wxDefaultPosition, [ 70, -1 ] );
	my $btnMoveUp   = Wx::Button->new( $self, -1, "Move up",   &Wx::wxDefaultPosition, [ 80, -1 ] );
	my $btnMoveDown = Wx::Button->new( $self, -1, "Move down", &Wx::wxDefaultPosition, [ 80, -1 ] );
	my $btnAdd      = Wx::Button->new( $self, -1, "+ Add",     &Wx::wxDefaultPosition, [ 70, -1 ] );

	# DEFINE EVENTS
	Wx::Event::EVT_BUTTON( $btnRemove,   -1, sub { $self->{"onRemoveCommentEvt"}->Do(@_) } );
	Wx::Event::EVT_BUTTON( $btnMoveUp,   -1, sub { $self->{"onMoveCommentEvt"}->Do("up") } );
	Wx::Event::EVT_BUTTON( $btnMoveDown, -1, sub { $self->{"onMoveCommentEvt"}->Do("down") } );
	Wx::Event::EVT_BUTTON( $btnAdd,      -1, sub { $self->{"onAddCommentEvt"}->Do(@_) } );

	$commList->{"onSelectItemChange"}->Add( sub { $self->{"onSelCommChangedEvt"}->Do( $_[0]->GetItemId() ) } );

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $commList, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( 5, 5, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szBtns, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szBtns->Add( $btnRemove,  0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $szBtnsMove, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( 1, 1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtns->Add( $btnAdd, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szBtnsMove->Add( $btnMoveUp,   0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szBtnsMove->Add( $btnMoveDown, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES
	$self->{"commList"} = $commList;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetCommList {
	my $self   = shift;
	my $layout = shift;

	$self->{"commList"}->SetCommentsLayout($layout);

}

sub SetCommSelected {
	my $self   = shift;
	my $commId = shift;

	$self->{"commList"}->SetSelectedItem($commId);

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;
