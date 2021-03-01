
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Parts::SizePart::View::SizePartFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::CreatorListFrm';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";
use aliased 'Programs::Panelisation::PnlWizard::Parts::SizePart::View::Creators::UserDefinedFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $model  = shift;    # model forfrist form inittialization

	my $self = $class->SUPER::new($parent);

	bless($self);

	$self->{"inCAM"} = $inCAM;
	$self->{"jobId"} = $jobId;

	$self->__SetLayout($model);

	# DEFINE EVENTS

	$self->{"onCreatorChangedEvt"} = Event->new();

	return $self;
}

sub __SetLayout {
	my $self  = shift;
	my $model = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $creatorListLayout = $self->__SetLayoutCreatorList( $self, $model );
	my $creatorViewLayout = $self->__SetLayoutCreatorView( $self, $model );

	# DEFINE EVENTS

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $creatorListLayout, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( 5, 5, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );
	$szMain->Add( $creatorViewLayout, 1, &Wx::wxEXPAND | &Wx::wxALL, 1 );

	$self->SetSizer($szMain);

	# SAVE REFERENCES

}

sub __SetLayoutCreatorList {
	my $self   = shift;
	my $parent = shift;
	my $model  = shift;

	# DEFINE CONTROLS
	my $creatorList = CreatorListFrm->new($self);

	my $creators = $model->GetCreators();

	$creatorList->SetCreatorsLayout($creators);

	my $listCrl = Wx::Colour->new( 230, 230, 230 );
	$self->SetBackgroundColour($listCrl);
	$creatorList->SetBackgroundColour($listCrl);

	# DEFINE EVENTS

	$creatorList->{"onSelectItemChange"}->Add( sub { $self->{"onCreatorChangedEvt"}->Do( $_[0]->GetPosition() ) if ( !$self->{"setCommList"} ) } );

	# BUILD STRUCTURE OF LAYOUT

	# SET REFERENCES
	$self->{"creatorList"} = $creatorList;

	return $creatorList;
}

sub __SetLayoutCreatorView {
	my $self   = shift;
	my $parent = shift;
	my $model  = shift;

	my $stepBackg = Wx::Colour->new( 215, 215, 215 );

	#define staticboxes

	#my $btnDefault = Wx::Button->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $parent, -1 );
	$pnlMain->SetBackgroundColour($stepBackg);

	my $notebook = CustomNotebook->new( $pnlMain, -1 );

	my $creators = $model->GetCreators();

	foreach my $creator ( @{$creators} ) {

		my $page = $notebook->AddPage( $creator->GetModelKey(), 0 );

		$page->GetParent()->SetBackgroundColour($stepBackg);

		my $content = undef;

		if ( $creator->GetModelKey() eq PnlCreEnums->SizePnlCreator_USERDEFINED ) {

			$content = UserDefinedFrm->new( $page->GetParent() );

		}
		elsif ( $creator->GetModelKey() eq PnlCreEnums->SizePnlCreator_HEGORDER ) {

			$content = UserDefinedFrm->new( $page->GetParent() );
		}
		$page->AddContent( $content, 0 );

	}

	# BUILD STRUCTURE OF LAYOUT
	$szMain->Add( $notebook, 1, &Wx::wxEXPAND | &Wx::wxALL, 5 );

	$pnlMain->SetSizer($szMain);

	# SET REFERENCES
	$self->{"notebook"} = $notebook;

	return $pnlMain;
}

# =====================================================================
# SET/GET CONTROLS VALUES
# =====================================================================

sub SetSelectedCreator {
	my $self          = shift;
	my $selCreatorKey = shift;


	$self->{"creatorList"}->SetSelectedItem($selCreatorKey);

	$self->{"notebook"}->ShowPage($selCreatorKey);

}

sub GetSelectedCreator {
	my $self = shift;

	return $self->{"selected"};
}

sub SetCreators {
	my $self = shift;

}

sub GetCreators {
	my $self = shift;

	return $self->{"creators"};

}

# CREATOR - user defined

sub SetWidth_UserDefined {
	my $self = shift;

	$self->{"w_UserDefined"} = shift;

}

sub GetWidth_UserDefined {
	my $self = shift;

	return $self->{"w_UserDefined"};

}

sub SetHeight_UserDefined {
	my $self = shift;

	$self->{"h_UserDefined"} = shift;

}

sub GetHeight_UserDefined {
	my $self = shift;

	return $self->{"h_UserDefined"};

}

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

