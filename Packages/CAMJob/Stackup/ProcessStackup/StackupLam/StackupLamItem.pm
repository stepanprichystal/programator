
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

	$self->{"itemId"}     = shift;
	$self->{"itemType"}   = shift;
	$self->{"valType"}    = shift;
	$self->{"valExtraId"} = shift;
	$self->{"valKind"}    = shift;
	$self->{"valText"}    = shift;
	$self->{"valThick"}   = shift;

	$self->{"childTop"} = undef;
	$self->{"childBot"} = undef;

	return $self;
}

sub GetIsPad{
	my $self = shift;
	
	if($self->{"itemType"} =~ /ItemType_PAD/){
		return 1;
	}else{
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

