
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Programs::Panelisation::PnlWizard::Forms::CreactorSelectorFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use List::Util qw(first);

#local library
use Widgets::Style;
use aliased 'Packages::Events::Event';
use aliased 'Programs::Panelisation::PnlWizard::Forms::CreatorListFrm';
use aliased 'Widgets::Forms::CustomNotebook::CustomNotebook';
use aliased 'Programs::Panelisation::PnlCreator::Enums' => "PnlCreEnums";

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $parent  = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $model   = shift;    # model forfrist form inittialization
	my $pnlType = shift;

	my $self = $class->SUPER::new($parent);

	bless($self);

	# PROPERTIES

	$self->{"inCAM"}         = $inCAM;
	$self->{"jobId"}         = $jobId;
	$self->{"creatorModels"} = $model->GetCreators();
	$self->{"pnlType"}       = $pnlType;

	# DEFINE EVENTS

	$self->{"creatorSelectionChangedEvt"} = Event->new();
	$self->{"creatorSettingsChangedEvt"}  = Event->new();
	$self->{"creatorInitRequestEvt"}      = Event->new();

	return $self;
}

sub _SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# Add empty item

	# DEFINE CONTROLS
	my $creatorListLayout = $self->__SetLayoutCreatorList($self);
	my $creatorViewLayout = $self->__SetLayoutCreatorView($self);

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

	# DEFINE CONTROLS
	my $creatorList = CreatorListFrm->new($self);

	my $creators = $self->{"creatorModels"};

	$creatorList->SetCreatorsLayout($creators);

	my $listCrl = Wx::Colour->new( 230, 230, 230 );
	$self->SetBackgroundColour($listCrl);
	$creatorList->SetBackgroundColour($listCrl);

	# DEFINE EVENTS

	$creatorList->{"onSelectItemChange"}->Add( sub { $self->__OncreatorSelectionChangedEvt(@_) } );

	# BUILD STRUCTURE OF LAYOUT

	# SET REFERENCES
	$self->{"creatorList"} = $creatorList;

	return $creatorList;
}

sub __SetLayoutCreatorView {
	my $self   = shift;
	my $parent = shift;

	my $stepBackg = Wx::Colour->new( 215, 215, 215 );

	#define staticboxes

	#my $btnDefault = Wx::Button->new( $statBox, -1, "Default settings", &Wx::wxDefaultPosition, [ 110, 22 ] );
	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	my $pnlMain = Wx::Panel->new( $parent, -1 );
	$pnlMain->SetBackgroundColour($stepBackg);

	my $notebook = CustomNotebook->new( $pnlMain, -1 );

	my $creators = $self->{"creatorModels"};

	foreach my $creator ( @{$creators} ) {

		my $page = $notebook->AddPage( $creator->GetModelKey(), 0 );

		$page->GetParent()->SetBackgroundColour($stepBackg);

		# Get Frm by calling inherit class method
		my $content = undef;
		if ( $self->can("OnGetCreatorLayout") ) {
			$content = $self->OnGetCreatorLayout( $creator->GetModelKey(), $page->GetParent() );
		}

		die "Creator  control is not defined for creator:" . $creator->GetModelKey() if ( !defined $content );

		$content->{"creatorSettingsChangedEvt"}->Add( sub { $self->{"creatorSettingsChangedEvt"}->Do( $content->GetCreatorKey(), @_ ) } );
		$content->{"creatorInitRequestEvt"}->Add( sub { $self->{"creatorInitRequestEvt"}->Do( $content->GetCreatorKey(), @_ ) } );

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

	return $self->{"creatorList"}->GetSelectedItem()->GetItemId();
}

sub GetCreatorFrm {
	my $self       = shift;
	my $creatorKey = shift;

	my $creatorFrm = $self->{"notebook"}->GetPage($creatorKey)->GetPageContent();

	return $creatorFrm;
}

sub SetCreators {
	my $self           = shift;
	my $creatorsModels = shift;

	die "Must not be implemented in base class";

}

sub GetCreators {
	my $self = shift;

	die "Must not be implemented in base class";

}

sub UpdateStep {
	my $self = shift;
	my $step = shift;

	foreach my $modelKey ( $self->{"creatorList"}->GetAllCreatorKeys() ) {

		my $creatorFrm = $self->{"notebook"}->GetPage($modelKey)->GetPageContent();
		$creatorFrm->SetStep($step);

	}

}

sub __OncreatorSelectionChangedEvt {
	my $self     = shift;
	my $listItem = shift;

	my $creatorKey = $listItem->GetItemId();

	$self->{"notebook"}->ShowPage($creatorKey);
	

	$self->{"creatorSelectionChangedEvt"}->Do($creatorKey);
	
   

}

# CREATOR - user defined

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

