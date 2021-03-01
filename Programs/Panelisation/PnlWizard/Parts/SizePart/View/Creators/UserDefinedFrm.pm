
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::UserDefinedFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';

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

	#$self->{"onCreatorChangedEvt"} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $szRow1 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $szRow2 = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $widthTxt = Wx::StaticText->new( $self, -1, "Width:", &Wx::wxDefaultPosition, [ 70, 22 ] );
	my $widthValTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition );

	my $heightTxt = Wx::StaticText->new( $self, -1, "Height:", &Wx::wxDefaultPosition, [ 70, 22 ] );
	my $heightValTxt = Wx::TextCtrl->new( $self, -1, "", &Wx::wxDefaultPosition );

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szRow1->Add( $widthTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow1->Add( $widthValTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szRow2->Add( $heightTxt,    1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szRow2->Add( $heightValTxt, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$szMain->Add( $szRow1, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $szRow2, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$self->SetSizer($szMain);

	# SAVE REFERENCES

}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================
#
#sub SetSelectedCreator {
#	my $self = shift;
#
#	$self->{"selected"} = shift;
#
#}
#
#sub GetSelectedCreator {
#	my $self = shift;
#
#	return $self->{"selected"};
#}
#
## CREATOR - user defined
#
#sub SetWidth_UserDefined {
#	my $self = shift;
#
#	$self->{"w_UserDefined"} = shift;
#
#}
#
#sub GetWidth_UserDefined {
#	my $self = shift;
#
#	return $self->{"w_UserDefined"};
#
#}
#
#sub SetHeight_UserDefined {
#	my $self = shift;
#
#	$self->{"h_UserDefined"} = shift;
#
#}
#
#sub GetHeight_UserDefined {
#	my $self = shift;
#
#	return $self->{"h_UserDefined"};
#
#}

# CREATOR - heg info

#sub SetComm {
#	my $self       = shift;
#	my $commId     = shift;
#	my $commLayout = shift;
#
#	$self->{"commList"}->SetCommentLayout( $commId, $commLayout );
#
#}
#
#sub SetCommList {
#	my $self           = shift;
#	my $commListLayout = shift;
#
#	$self->{"setCommList"} = 1;    #
#
#	$self->{"commList"}->SetCommentsLayout($commListLayout);
#
#	if ( scalar( @{$commListLayout} ) ) {
#
#		$self->{"btnRemove"}->Enable();
#
#	}
#	else {
#		$self->{"btnRemove"}->Disable();
#
#	}
#
#	if ( scalar( @{$commListLayout} ) > 1 ) {
#		$self->{"btnMoveUp"}->Enable();
#		$self->{"btnMoveDown"}->Enable();
#	}
#	else {
#		$self->{"btnMoveUp"}->Disable();
#		$self->{"btnMoveDown"}->Disable();
#	}
#
#	$self->{"setCommList"} = 0;    #
#
#}
#
#sub SetCommSelected {
#	my $self   = shift;
#	my $commId = shift;
#
#	$self->{"commList"}->SetSelectedItem($commId);
#
#}
#
#sub GetSelectedComm {
#	my $self = shift;
#
#	my $comm = $self->{"commList"}->GetSelectedItem();
#
#	if ( defined $comm ) {
#		return $comm->GetPosition();
#	}
#	else {
#		return undef;
#	}
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#	my $test = PureWindow->new(-1, "f13610" );
#
#	$test->MainLoop();

1;

