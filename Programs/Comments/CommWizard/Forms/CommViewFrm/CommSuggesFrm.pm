#-------------------------------------------------------------------------------------------#
# Description: Form, which allow set nif quick notes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommWizard::Forms::CommViewFrm::CommSuggesFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Widgets::Forms::MyWxBookCtrlPage';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Comments::CommWizard::Forms::CommViewFrm::SuggesListFrm';

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
	$self->{'onAddSuggesEvt'}    = Event->new();
	$self->{'onRemoveSuggesEvt'} = Event->new();
	$self->{'onChangeSuggesEvt'} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	# DEFINE SIZERS
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	my $szBtns = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS

	my $btnAddSugg = Wx::Button->new( $self, -1, "+ Add", &Wx::wxDefaultPosition, [ 60, -1 ] );
	my $suggList = SuggesListFrm->new($self);

	# SET Events

	Wx::Event::EVT_BUTTON( $btnAddSugg, -1, sub { $self->{"onAddSuggesEvt"}->Do() } );
	$suggList->{"onRemoveSuggesEvt"}->Add( sub { $self->{"onRemoveSuggesEvt"}->Do(@_) } );
	$suggList->{"onChangeSuggesEvt"}->Add( sub { $self->{"onChangeSuggesEvt"}->Do(@_) } );

	# DEFINE LAYOUT STRUCTURE

	# BUILD STRUCTURE OF LAYOUT
	$szBtns->Add( $btnAddSugg, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $suggList,   1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szBtns,     0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SET REFERENCES
	$self->{"suggList"} = $suggList;

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetSuggestionsLayout {
	my $self         = shift;
	my $sugessLayout = shift;

	$self->{"suggList"}->SetSuggestionsLayout($sugessLayout);

}

# =====================================================================
# PRIVATE METHODS
# =====================================================================

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

