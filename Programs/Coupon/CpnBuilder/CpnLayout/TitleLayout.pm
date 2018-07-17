
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnBuilder::CpnLayout::TitleLayout;
use base qw(Programs::Coupon::CpnBuilder::CpnLayout::CpnLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');


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
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"type"} = undef;    # top/right
	$self->{"w"}    = undef;
	$self->{"h"}    = undef;

	# Job id
	$self->{"jobIdPosition"} = undef;
	$self->{"jobIdVal"}      = undef;

	# Logo
	$self->{"logoPosition"} = undef;

	#$self->{"logoVal"} = undef;

	# title position + rotation

	$self->{"angle"} = undef;

	$self->{"titleUnamsk"} = undef;

	$self->{"titleTextHeight"} = undef;
	$self->{"titleTextWidth"}  = undef;
	$self->{"titleTextWeight"} = undef;

	$self->{"logoSymbol"}       = undef;
	$self->{"logoHeight"}       = undef;
	$self->{"logoWidth"}        = undef;
	$self->{"logoSymbolHeight"} = undef;
	$self->{"logoSymbolWidth"}  = undef;
	
	$self->{"__CLASS__"} = "Programs::Coupon::CpnBuilder::CpnLayout::TitleLayout";

	return $self;

}

sub SetTitleUnMask {
	my $self   = shift;
	my $unmask = shift;

	$self->{"titleUnamsk"} = $unmask;
}

sub GetTitleUnMask {
	my $self = shift;

	return $self->{"titleUnamsk"};
}

sub SetType {
	my $self = shift;
	my $type = shift;

	$self->{"type"} = $type;
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub SetHeight {
	my $self = shift;

	$self->{"h"} = shift;
}

sub GetHeight {
	my $self = shift;

	return $self->{"h"};
}

sub SetWidth {
	my $self  = shift;
	my $width = shift;

	$self->{"w"} = $width;

}

sub GetWidth {
	my $self = shift;

	return $self->{"w"};
}

sub SetJobIdPosition {
	my $self = shift;
	my $pos  = shift;

	$self->{"jobIdPosition"} = $pos;
}

sub GetJobIdPosition {
	my $self = shift;

	return $self->{"jobIdPosition"};
}

sub SetLogoPosition {
	my $self = shift;
	my $pos  = shift;

	$self->{"logoPosition"} = $pos;
}

sub GetLogoPosition {
	my $self = shift;

	return $self->{"logoPosition"};
}

sub SetJobIdVal {
	my $self = shift;
	my $val  = shift;

	$self->{"jobIdVal"} = $val;
}

sub GetJobIdVal {
	my $self = shift;

	return $self->{"jobIdVal"};
}

sub SetTitleTextHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"titleTextHeight"} = $val;
}

sub GetTitleTextHeight {
	my $self = shift;

	return $self->{"titleTextHeight"};
}

sub SetTitleTextWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"titleTextWidth"} = $val;
}

sub GetTitleTextWidth {
	my $self = shift;

	return $self->{"titleTextWidth"};
}

sub SetTitleTextWeight {
	my $self = shift;
	my $val  = shift;

	$self->{"titleTextWeight"} = $val;
}

sub GetTitleTextWeight {
	my $self = shift;

	return $self->{"titleTextWeight"};
}


sub SetLogoHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"logoHeight"} = $val;
}

sub GetLogoHeight {
	my $self = shift;

	return $self->{"logoHeight"};
}

sub SetLogoWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"logoWidth"} = $val;
}

sub GetLogoWidth {
	my $self = shift;

	return $self->{"logoWidth"};
}

sub SetLogoSymbolHeight {
	my $self = shift;
	my $val  = shift;

	$self->{"logoSymbolHeight"} = $val;
}

sub GetLogoSymbolHeight {
	my $self = shift;

	return $self->{"logoSymbolHeight"};
}

sub SetLogoSymbolWidth {
	my $self = shift;
	my $val  = shift;

	$self->{"logoSymbolWidth"} = $val;
}

sub GetLogoSymbolWidth {
	my $self = shift;

	return $self->{"logoSymbolWidth"};
}


sub SetLogoSymbol{
	my $self = shift;
	my $val  = shift;

	$self->{"logoSymbol"} = $val;
}

sub GetLogoSymbol {
	my $self = shift;

	return $self->{"logoSymbol"};
}

sub TO_JSON { return { %{ shift() } }; }
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

