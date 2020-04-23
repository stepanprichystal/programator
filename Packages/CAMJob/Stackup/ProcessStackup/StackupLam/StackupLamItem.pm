
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::ProcessStackup::StackupLam::StackupLamItem;

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"itemId"}     = shift;    # id of specific material/presspad
	$self->{"itemType"}   = shift;    # item type
	$self->{"valType"}    = shift;    # description if item type
	$self->{"valExtraId"} = shift;    # Extra di for (Cu layer, flex prepreg Id, core Id, product Id, ...)
	$self->{"valKind"}    = shift;    # material kin (IS400, ...)
	$self->{"valText"}    = shift;    # description of material
	$self->{"valThick"}   = shift;    # material thickness

	# Item can by merged from another two (to/bot) items
	# It means, they have no gap between themselves in the final picture
	$self->{"childTop"} = undef;    # Reference to TOP Cu layer, top/bot product layer and so on
	$self->{"childBot"} = undef;    # Reference to BOT Cu layer, top/bot product layer and so on

	return $self;
}

sub GetIsPad {
	my $self = shift;

	if ( $self->{"itemType"} =~ /ItemType_PAD/ ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub AddChildItem {
	my $self = shift;
	my $item = shift;
	my $pos  = shift;    #top/bot

	$self->{"childTop"} = $item if ( $pos eq "top" );
	$self->{"childBot"} = $item if ( $pos eq "bot" );

}

sub GetItemId {
	my $self = shift;

	return $self->{"itemId"};
}

sub GetItemType {
	my $self = shift;

	return $self->{"itemType"};
}

sub GetValType {
	my $self = shift;

	return $self->{"valType"};
}

sub GetValExtraId {
	my $self = shift;

	return $self->{"valExtraId"};
}

sub GetValKind {
	my $self = shift;

	return $self->{"valKind"};
}

sub GetValText {
	my $self = shift;

	return $self->{"valText"};
}

sub GetValThick {
	my $self = shift;

	return $self->{"valThick"};
}

sub GetChildTop {
	my $self = shift;

	return $self->{"childTop"};
}

sub GetChildBot {
	my $self = shift;

	return $self->{"childBot"};
}

1;

