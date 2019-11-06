#-------------------------------------------------------------------------------------------#
# Description: Responsible for creating "table of column", where GroupWrapperForms are
# placed in. Is responsible for recaltulating "column" layout.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcViewerFrm;
use base qw(Widgets::Forms::CustomQueue::MyWxCustomQueue);

#3th party library
use strict;
use warnings;
use Wx;
use Wx qw(:sizer wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER);

#local library

use Widgets::Style;

use aliased 'Packages::Events::Event';
use aliased 'Helpers::GeneralHelper';
use aliased 'Widgets::Forms::CustomControlList::Enums';

use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcGroupStackupFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcGroupSeparatorFrm';


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
	$self->{"stacupGroups"} = [];

	$self->__SetLayout();

	#EVENTS

	$self->{"onLayerSettChanged"} = Event->new();
	$self->{"technologyChanged"}  = Event->new();
	$self->{"tentingChanged"}     = Event->new();

	return $self;

}

sub AddGroupStackup {
	my $self    = shift;
	my $groupId = shift;
	my $groupType = shift;

	my $group = ProcGroupStackupFrm->new( $self->GetParentForItem(), $groupId, $groupType);

	$group->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );
	$group->{"technologyChanged"}->Add( sub  { $self->{"technologyChanged"}->Do(@_) } );
	$group->{"tentingChanged"}->Add( sub     { $self->{"tentingChanged"}->Do(@_) } );

	$self->AddItemToQueue($group);

	push( @{ $self->{"stacupGroups"} }, $group );

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

sub AddGroupSep {
	my $self    = shift;
	my $type    = shift;
	
	my $groupId = GeneralHelper->GetGUID();

	my $sep = ProcGroupSeparatorFrm->new( $self->GetParentForItem(), $groupId, $type );

	#	$group->{"onLayerSettChanged"}->Add( sub { $self->{"onLayerSettChanged"}->Do(@_) } );
	#	$group->{"technologyChanged"}->Add( sub  { $self->{"technologyChanged"}->Do(@_) } );
	#	$group->{"tentingChanged"}->Add( sub     { $self->{"tentingChanged"}->Do(@_) } );

	$self->AddItemToQueue($sep);

	#$self->__SetJobOrder();

	return $sep;

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

	$self->SetItemGap(2);

	#$self->SetItemUnselectColor( AppConf->GetColor("clrGroupBackg") );
	#$self->SetItemSelectColor( AppConf->GetColor("clrItemSelected") );

	# SET EVENTS

	#$self->{"onSelectItemChange"}->Add( sub { $self->__OnSelectItem(@_) } );

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
