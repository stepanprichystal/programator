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

	my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 500, 500 ] );

	bless($self);

	# Items references
	# PROPERTIES
	$self->{"groupFrmInput"} = [];
	$self->{"groupFrmPress"} = [];

	$self->__SetLayout();

	#EVENTS

	$self->{"layerSettChangedEvt"}  = Event->new();
	$self->{"technologyChangedEvt"} = Event->new();
	$self->{"tentingChangedEvt"}    = Event->new();

	return $self;

}

sub AddGroup {
	my $self      = shift;
	my $groupId   = shift;
	my $groupType = shift;

	# Add separator if any group exist
	if ( $groupType eq Enums->Group_PRODUCTINPUT && scalar( @{ $self->{"groupFrmInput"} } ) ) {
		$self->__AddSeparator();
	}
	elsif ( $groupType eq Enums->Group_PRODUCTPRESS && scalar( @{ $self->{"groupFrmPress"} } ) ) {
		$self->__AddSeparator();
	}

	my $group = GroupFrm->new( $self, $groupId, $groupType );
	
	$group->{"layerSettChangedEvt"}->Add( sub  { $self->{"layerSettChangedEvt"}->Do(@_) } );
	$group->{"technologyChangedEvt"}->Add( sub { $self->{"technologyChangedEvt"}->Do(@_) } );
	$group->{"tentingChangedEvt"}->Add( sub    { $self->{"tentingChangedEvt"}->Do(@_) } );

	$self->{"szGroups"}->Add( $group, 0, &Wx::wxALL, 0 );
 

	if ( $groupType eq Enums->Group_PRODUCTINPUT ) {
		push( @{ $self->{"groupFrmInput"} }, $group );
	}
	elsif ( $groupType eq Enums->Group_PRODUCTPRESS ) {
		push( @{ $self->{"groupFrmPress"} }, $group );
	}

	#$self->__SetJobOrder();

	return $group;

}

sub GetGroups {
	my $self = shift;
	my $type = shift;

	my @groupsFrm = ();

	@groupsFrm = @{ $self->{"groupFrmInput"} } if ( defined $type && $type eq Enums->Group_PRODUCTINPUT );
	@groupsFrm = @{ $self->{"groupFrmPress"} } if ( defined $type && $type eq Enums->Group_PRODUCTPRESS );
	@groupsFrm = ( @{ $self->{"groupFrmInput"} }, @{ $self->{"groupFrmPress"} } ) if ( !defined $type );

	return @groupsFrm;

}

sub AddCategoryTitle {
	my $self = shift;
	my $type = shift;

	# DEFINE SIZERS
	#my $szMain       = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
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

	$self->{"szGroups"}->Add( $groupTitlePnl, 0, &Wx::wxEXPAND | &Wx::wxALL, 0 );

	#$self->{"szGroups"}->Add( 5, 5 );

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

#-------------------------------------------------------------------------------------------#
#  Layout settings
#-------------------------------------------------------------------------------------------#
sub HideSubGroup {
	my $self = shift;

	# 1) Input product Sub group head can be hidden, if there no groups has more than one sobgroup
	my $hide = 1;

	foreach my $groupFrm ( $self->GetGroups( Enums->Group_PRODUCTINPUT ) ) {

		if ( scalar( $groupFrm->GetSubGroups() ) > 1 ) {

			$hide = 0;
			last;
		}
	}

	if ($hide) {
		$_->HideSubGroupTitle() foreach ( map { $_->GetSubGroups() } $self->GetGroups() );
	}

	$_->HideSubGroupTitle() foreach ( map { $_->GetSubGroups() } $self->GetGroups( Enums->Group_PRODUCTPRESS ) );
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __SetLayout {
	my $self = shift;

	my $szMain = Wx::BoxSizer->new(&Wx::wxVERTICAL);

	# DEFINE CONTROLS

	$self->SetBackgroundColour( Wx::Colour->new( 200, 200, 200 ) );

	# Group head

	$self->SetSizer($szMain);

	# SET EVENTS

	# SET REFERENCES

	$self->{"szGroups"} = $szMain;

}

sub __AddSeparator {
	my $self = shift;

	# DEFINE SIZERS
	#my $szMain = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);

	# DEFINE CONTROLS
	my $sepPnl = Wx::Panel->new( $self, -1, [ -1, -1 ], [ -1, 2 ] );
	$sepPnl->SetBackgroundColour( Wx::Colour->new( 40, 40, 40 ) );

	# BUILD LAYOUT STRUCTURE

	$self->{"szGroups"}->Add( $sepPnl, 0, &Wx::wxEXPAND | &Wx::wxALL, 1 );

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
