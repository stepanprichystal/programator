
#-------------------------------------------------------------------------------------------#
# Description: Pin data structure:
# - reference to all pin features (solder line/ cut line/ solder pin/ pin envelop)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::FlexiLayers::CoverlayPinParser::Pin;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use List::Util qw(first);

#local library
use aliased 'Packages::CAMJob::FlexiLayers::CoverlayPinParser::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"pinGUID"} = shift;

	# - PinHolder_NONE
	# - PinHolder_OUT
	# - PinHolder_IN
	$self->{"holderType"}  = shift;
	$self->{"registerPad"} = shift;    # 0/1
	$self->{"features"}    = shift;

	return $self;
}

# Pin ID is same as value of attribut "feat_group_id" on pin features
sub GetGUID {
	my $self = shift;

	return $self->{"pinGUID"};
}

# - PinHolder_NONE
# - PinHolder_OUT
# - PinHolder_IN
sub GetHolderType {
	my $self = shift;

	return $self->{"holderType"};
}

# Return if pin contain register pad
sub GetRegisterPad {
	my $self = shift;

	return $self->{"registerPad"};
}

# Return envelop points of pin (only features with .string att: PinString_SIDELINE2)
sub GetHolderEnvelop {
	my $self = shift;

	my @sideLines = grep { $_->{"att"}->{".string"} eq Enums->PinString_SIDELINE2 } @{ $self->{"features"} };

	die " Pin \"Side lines\" count is not equal to two" if ( scalar(@sideLines) != 2 );

	my @envelop = ();
	push( @envelop, { "x" => $sideLines[0]->{"x1"}, "y" => $sideLines[0]->{"y1"} } );
	push( @envelop, { "x" => $sideLines[0]->{"x2"}, "y" => $sideLines[0]->{"y2"} } );
	push( @envelop, { "x" => $sideLines[1]->{"x1"}, "y" => $sideLines[1]->{"y1"} } );
	push( @envelop, { "x" => $sideLines[1]->{"x2"}, "y" => $sideLines[1]->{"y2"} } );
	push( @envelop, { "x" => $sideLines[0]->{"x1"}, "y" => $sideLines[0]->{"y1"} } );

	return @envelop;

}

# Return all pin features (which has attribut group_feat_guid same as pin)
sub GetFeatures {
	my $self = shift;

	return @{ $self->{"features"} };
}

# Get feat pad which is used for register coverlay with flex core
sub GetREGISTERFeat {
	my $self = shift;

	die "Pin doesn't contain register feat" unless ( $self->GetRegisterPad() );

	my $regFeat = first { $_->{"att"}->{".string"} eq Enums->PinString_REGISTER } @{ $self->{"features"} };

	return $regFeat;
}

sub GetSIDELINE1Feats {
	my $self = shift;

	die "Pin doesn't contain pin holder" if ( $self->GetHolderType() eq Enums->PinHolder_NONE );

	my @feats = first { $_->{"att"}->{".string"} eq Enums->PinString_SIDELINE1 } @{ $self->{"features"} };

	return @feats;
}

sub GetSIDELINE2Feats {
	my $self = shift;

	die "Pin doesn't contain pin holder" if ( $self->GetHolderType() eq Enums->PinHolder_NONE );

	my @feats = first { $_->{"att"}->{".string"} eq Enums->PinString_SIDELINE2 } @{ $self->{"features"} };

	return @feats;
}

sub GetENDLINEFeat {
	my $self = shift;

	die "Pin doesn't contain pin holder" if ( $self->GetHolderType() eq Enums->PinHolder_NONE );

	my $feat = first {
		$_->{"att"}->{".string"} eq Enums->PinString_ENDLINEIN
		  || $_->{"att"}->{".string"} eq Enums->PinString_ENDLINEOUT
	}
	@{ $self->{"features"} };

	return $feat;
}

sub GetCUTLINEFeat {
	my $self = shift;

	die "Pin doesn't contain pin holder" if ( $self->GetHolderType() eq Enums->PinHolder_NONE );

	my $feat = first { $_->{"att"}->{".string"} eq Enums->PinString_CUTLINE  } @{ $self->{"features"} };

	return $feat;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

