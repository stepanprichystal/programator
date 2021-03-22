
#-------------------------------------------------------------------------------------------#
# Description: Represent Panel class definition
# panel class name has following format:
# <material type>_<layer number type>_<dimension>_<special>
# - <material type> - mandatory (flex, rigid, al, hybrid, ..)
# - <layer number type> - mandatory (2v, vv)
#
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::PanelClass::Classes::PnlClass;
use base('Packages::CAM::PanelClass::Classes::PnlClassBase');

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::CAM::PanelClass::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $name = shift;
	my $self = $class->SUPER::new( $name, @_ );
	bless $self;

	#

	$self->{"sizes"}    = [];
	$self->{"borders"}  = [];
	$self->{"spacings"} = [];

	$self->{"goldScoringDist"} = 0;
	$self->{"transformation"}  = Enums->PnlClassTransform_ROTATION;
	$self->{"rotation"}        = Enums->PnlClassRotation_ANY;
	$self->{"pattern"}         = Enums->PnlClassPattern_NO_PATTERN;
	$self->{"interlock"}       = Enums->PnlClassInterlock_NONE;
	$self->{"spacingAlign"}    = Enums->PnlClassSpacingAlign_KEEP_IN_CENTER;
	$self->{"numMaxSteps"}     = Enums->PnlClassNumMaxSteps_NO_LIMIT;

	return $self;
}





#-------------------------------------------------------------------------------------------#
#  GET/SET methods for setting class settings
#-------------------------------------------------------------------------------------------#

sub SetSizes {
	my $self = shift;
	my $val  = shift;

	$self->{"sizes"} = $val;
}

sub GetSizes {
	my $self = shift;

	return $self->{"sizes"};
}

sub SetBorders {
	my $self = shift;
	my $val  = shift;

	$self->{"borders"} = $val;
}

sub GetBorders {
	my $self = shift;

	return $self->{"borders"};
}

sub SetSpacings {
	my $self = shift;
	my $val  = shift;

	$self->{"spacings"} = $val;
}

sub GetSpacings {
	my $self = shift;

	return $self->{"spacings"};
}


sub SetGoldScoringDist {
	my $self = shift;
	my $val  = shift;

	$self->{"goldScoringDist"} = $val;
}

sub GetGoldScoringDist {
	my $self = shift;

	return $self->{"goldScoringDist"};
}

sub SetTransformation {
	my $self = shift;
	my $val  = shift;

	$self->{"transformation"} = $val;
}

sub GetTransformation {
	my $self = shift;

	return $self->{"transformation"};
}

sub SetRotation {
	my $self = shift;
	my $val  = shift;

	$self->{"rotation"} = $val;
}

sub GetRotation {
	my $self = shift;

	return $self->{"rotation"};
}

sub SetPattern {
	my $self = shift;
	my $val  = shift;

	$self->{"pattern"} = $val;
}

sub GetPattern {
	my $self = shift;

	return $self->{"pattern"};
}

sub SetInterlock {
	my $self = shift;
	my $val  = shift;

	$self->{"interlock"} = $val;
}

sub GetInterlock {
	my $self = shift;

	return $self->{"interlock"};
}

sub SetSpacingAlign {
	my $self = shift;
	my $val  = shift;

	$self->{"spacingAlign"} = $val;
}

sub GetSpacingAlign {
	my $self = shift;

	return $self->{"spacingAlign"};
}

sub SetNumMaxSteps {
	my $self = shift;
	my $val  = shift;

	$self->{"numMaxSteps"} = $val;
}

sub GetNumMaxSteps {
	my $self = shift;

	return $self->{"numMaxSteps"};
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

