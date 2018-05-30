
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CouponSettings;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::XMLParser';
use aliased 'Packages::CouponSingleSettings';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inplanJobPath"} = shift;

	$self->{"xmlParser"} = XMLParser->new( $self->{"inplanJobPath"} );

	# Settings
	$self->{"padTraceDCode"}     = "r1524";    #µm
	$self->{"padGNDDCode"}       = "s1524";    #µm
	$self->{"tracePad2GNDPad"}   = 2.54;       # mm
	$self->{"tracePad2tracePad"} = 2.54;       # mm
	$self->{"w"}                 = 20.32;      # mm
	$self->{"h"}                 = 203.2;      # mm
	$self->{"margin"}                 = 3;      # mm

	$self->{"couponsSingle"} = [];             # contain item for each co=single coupon and all constrains

	$self->__Init();

	return $self;

}

sub __Init {
	my $self = shift;

	foreach my $constrain ( $self->{"xmlParser"}->GetConstrains() ) {

		push(
			  @{ $self->{"couponSingleGroups"} }, CouponSingleSettings->new($constrain);
		}

	}
}


sub GetPad2PadDist{
	my  $self = shift;
	
	return $self->{"tracePad2GNDPad"};
	
}

sub GetCouponSingleMargin{
	my  $self = shift;
	
	return $self->{"margin"};
	
}

sub GetAreaWidth{
	my $self = shift;
	
	return $self->{"w"} -20;
	
}

sub GetCouponsSingle {
	my $self = shift;

	@{ $self->{"couponSingleGroups"} };
}

sub GetStackupJobXml {
	my $self = shift;

	return $self->{"inplanJobPath"};
}

sub GetXmlParser{
	my $self = shift;
	
	
	return $self->{"xmlParser"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

