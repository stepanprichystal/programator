#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcViewerFrm;
use base qw(Wx::Panel);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;

use aliased 'Packages::Events::Event';
use aliased 'Helpers::GeneralHelper';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupFrm';

#use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::GroupSeparatorFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ -1, -1 ] );

	bless($self);

	# Items references
	# PROPERTIES
	$self->{"groupsInput"} = [];
	$self->{"groupsPress"} = [];

	$self->{"subGroupGap"} = 4;

	$self->__SetLayout();

	#EVENTS

	$self->{"onLayerSettChanged"} = Event->new();
	$self->{"technologyChanged"}  = Event->new();
	$self->{"tentingChanged"}     = Event->new();

	return $self;

}

sub AddGroup {
	my $self      = shift;
	my $groupId   = shift;
	my $groupType = shift;

	my $group = GroupFrm->new( $self, $groupId, $groupType );

	$group->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );
	$group->{"technologyChanged"}->Add( sub  { $self->{"technologyChanged"}->Do(@_) } );
	$group->{"tentingChanged"}->Add( sub     { $self->{"tentingChanged"}->Do(@_) } );

	$self->{"szGroups"}->Add( $group, 0, &Wx::wxALL, 0 );
	$self->{"szGroups"}->Add( 4,      4, &Wx::wxALL, 0 );
	
	push( @{ $self->{"stacupGroups"} }, $group );
	
	$self->{"groupsInput"}

	#$self->__SetJobOrder();

	return $group;

}

sub GetGroupStackup {
	my $self    = shift;
	my $groupId = shift;

	return ( grep { $_->GetItemId() eq $groupId } @{ $self->{"stacupGroups"} } )[0];
}

sub GetAllGroupStackup {
	my $self    = shift;
	my $groupId = shift;

	return @{ $self->{"stacupGroups"} };
}

sub AddCategoryTitle {
	my $self = shift;
	my $type = shift;

	# DEFINE SIZERS
	my $szMain       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
	my $groupTitleSz = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $groupTitlePnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );
	my $groupTitleTxt = Wx::StaticText->new( $groupTitlePnl, -1, "", [ -1, -1 ] );

	if ( $type eq Enums->Group_PRODUCTINPUT ) {

		$groupTitlePnl->SetBackgroundColour( Enums->Color_PRODUCTINPUT );
		$groupTitleTxt->SetLabel("Input semi-product");
	}
	elsif ( $type eq Enums->Group_PRODUCTPRESS ) {
		$groupTitlePnl->SetBackgroundColour( Enums->Color_PRODUCTPRESS );
		$groupTitleTxt->SetLabel("Pressing");
	}

	my $fontLblBold = Wx::Font->new( 11, &Wx::wxFONTFAMILY_DEFAULT, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxFONTWEIGHT_BOLD );

	$groupTitleTxt->SetForegroundColour( Wx::Colour->new( 40, 40, 40 ) );    # set text color
	$groupTitleTxt->SetFont($fontLblBold);

	# BUILD LAYOUT STRUCTURE
	$groupTitleSz->Add( $groupTitleTxt, 0, &Wx::wxLEFT | &Wx::wxALIGN_CENTER_VERTICAL | &Wx::wxALIGN_CENTER, 5 );
	$groupTitlePnl->SetSizer($groupTitleSz);

	$self->{"szGroups"}->Add( $groupTitlePnl, 0, &Wx::wxALL, 0 );
	$self->{"szGroups"}->Add( 5, 5 );

	#$self->__SetJobOrder();

}

sub SetLayerValues {
	my $self = shift;
	my $l    = shift;

	my $layerRow = ( grep { $_->GetLayerName() eq $l->{"name"} } map { $_->GetAllCopperRows() } $self->GetAllGroupStackup() )[0];

	$layerRow->SetLayerValues($l);
}

sub GetLayerValues {
	my $self      = shift;
	my $layerName = shift;

	my $layerRow = ( grep { $_->GetLayerName() eq $layerName } map { $_->GetAllCopperRows() } $self->GetAllGroupStackup() )[0];

	return $layerRow->GetLayerValues();
}

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	# Group head

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES

	$self->{"szGroups"} = $szMain;

}

sub __AddSeparator {
	my $self = shift;

	# DEFINE SIZERS
	my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $sepPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, -1 ] );

	# BUILD LAYOUT STRUCTURE

	$self->{"szGroups"}->Add( $sepPnl, 0, &Wx::wxALL, 1 );

}

sub __GetCopperRow {
	my $self      = shift;
	my $layerName = shift;

}

#
#sub __OnStop {
#	my $self = shift;
#
#	$self->{"onStop"}->Do( $self->{"taskId"} );
#}
#
#sub __OnContinue {
#	my $self = shift;
#
#	$self->{"onContinue"}->Do( $self->{"taskId"} );
#}
#
#sub __OnAbort {
#	my $self = shift;
#
#	$self->{"onAbort"}->Do( $self->{"taskId"} );
#}
#
#sub __OnRestart {
#	my $self = shift;
#
#	$self->{"onRestart"}->Do( $self->{"taskId"} );
#}
#
#sub __OnRemove {
#	my $self = shift;
#
#	$self->{"onRemove"}->Do( $self->{"taskId"} );
#}
#
#sub __OnSelectItem {
#	my $self = shift;
#	my $item = shift;
#
#}

#sub __SetJobOrder {
#	my $self = shift;
#
#	my @queue = @{ $self->{"jobItems"} };
#
#	#find index of item
#	for ( my $i = 0 ; $i < scalar(@queue) ; $i++ ) {
#
#		$queue[$i]->SetItemOrder();
#	}
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
