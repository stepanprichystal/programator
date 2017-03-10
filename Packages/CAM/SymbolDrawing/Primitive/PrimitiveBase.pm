#-------------------------------------------------------------------------------------------#
# Description: Class can parse incam layer fetures. Parsed features, contain only
# basic info like coordinate, attrubutes etc..
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::Primitive::PrimitiveBase;

#3th party library
use strict;
use warnings;
use Storable qw(dclone);

#local library
use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'Helpers::GeneralHelper'; 

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"type"}     = shift;
	$self->{"polarity"} = shift;

	unless ( defined $self->{"polarity"} ) {
		$self->{"polarity"} = Enums->Polar_POSITIVE;
	}
	
	# Unique number which are signed drawed feature. Attribute "feat_group_id"
	$self->{"groupGUID"} = GeneralHelper->GetGUID();

	return $self;
}

#parse features layer

sub GetType {
	my $self = shift;

	return $self->{"type"};

}

sub GetPolarity {
	my $self = shift;

	return $self->{"polarity"};

}

sub Copy {
	my $self = shift;

	return dclone($self);
}

sub GetGroupGUID{
	my $self = shift;
	
	return $self->{"groupGUID"};
}

sub SetGroupGUID{
	my $self = shift;
	my $guid = shift;
	
	$self->{"groupGUID"} = $guid;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

