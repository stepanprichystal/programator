
#-------------------------------------------------------------------------------------------#
# Description: Represent type + information about specific lamination
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::StackupLam::StackupLam;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::StackupLam::StackupLamItem';
use aliased 'Packages::CAMJob::Stackup::ProcessStackup::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"lamOrder"}     = shift;
	$self->{"lamType"}      = shift;
	$self->{"lamProductId"} = shift;    # marking of result semiproduct
	$self->{"lamData"}      = shift;    # onlz for multilayer (IProduct)

	$self->{"items"} = [];              # contain single material + presspad layers of whole lamination package

	return $self;
}

sub AddItem {
	my $self       = shift;
	my $itemId     = shift;
	my $itemType   = shift;
	my $valType    = shift;
	my $valExtraId = shift;
	my $valKind    = shift;
	my $valText    = shift;
	my $valThick   = shift;

	my $item = StackupLamItem->new( $itemId, $itemType, $valType, $valExtraId, $valKind, $valText, $valThick );

	push( @{ $self->{"items"} }, $item );

	return $item;

}

sub AddChildItem {
	my $self       = shift;
	my $parentItem = shift;
	my $position   = shift;    # top/bot
	my $itemId     = shift;
	my $itemType   = shift;
	my $valType    = shift;
	my $valExtraId = shift;
	my $valKind    = shift;
	my $valText    = shift;
	my $valThick   = shift;

	my $childItem = StackupLamItem->new( $itemId, $itemType, $valType, $valExtraId, $valKind, $valText, $valThick );

	$parentItem->AddChildItem( $childItem, $position );

}

sub GetLamOrder {
	my $self = shift;

	return $self->{"lamOrder"};
}

sub GetLamType {
	my $self = shift;

	return $self->{"lamType"};
}

sub GetLamData {
	my $self = shift;

	return $self->{"lamData"};
}

sub GetProductId {
	my $self = shift;

	return $self->{"lamProductId"};
}

sub GetItems {
	my $self = shift;

	return @{ $self->{"items"} };

}

# Return thockness [µm] of one packet, comupted from top steel to bot steel
# Steel thickness are not considered
sub GetPaketThick {
	my $self = shift;
	my $inclPads = shift // 1;

	my $start = 0;
	my @items = @{ $self->{"items"} };

	my @pItems = ();
	for ( my $i = 0 ; $i < scalar(@items) ; $i++ ) {

		my $item = $items[$i];

		if ( !$start && $item->GetItemType() eq Enums->ItemType_PADSTEEL ) {
			$start = 1;
			next;
		}

		push( @pItems, $item ) if ($start);

		if ( scalar(@pItems) > 1 && $start && $item->GetItemType() eq Enums->ItemType_PADSTEEL ) {
			last;
		}
	}

	@pItems = grep { !$_->GetIsPad() } @pItems unless ($inclPads);

	my $thick = 0;
	$thick += $_->GetValThick() foreach @pItems;

	return $thick;

}

# Return extra presspads, which are outside of inner steel plates
sub GetOuterPresspads {
	my $self = shift;

	my @outerPads = ();

	if ( $self->{"items"}->[0]->GetIsPad() && $self->{"items"}->[0]->GetItemType() ne Enums->ItemType_PADSTEEL ) {
		push( @outerPads, $self->{"items"}->[0] );
	}

	if ( $self->{"items"}->[-1]->GetIsPad() && $self->{"items"}->[-1]->GetItemType() ne Enums->ItemType_PADSTEEL ) {
		push( @outerPads, $self->{"items"}->[-1] );
	}

	return @outerPads;

}

1;

