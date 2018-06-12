
#-------------------------------------------------------------------------------------------#
# Description:  
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnPolicy::CpnVariant::CpnStripVariant;

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
 
	$self->{"id"} = shift;

	$self->{"poolOrder"} = undef;
	$self->{"column"}    = undef;
	$self->{"data"}      = undef;
	$self->{"routeType"} = undef;
	$self->{"routeDist"} = undef;
	$self->{"isLast"} = undef;

	return $self;
}

sub Id {
	my $self = shift;

	return $self->{"id"};
}
 

sub Pool {
	my $self = shift;

	return $self->{"poolOrder"};
}

sub SetPool {
	my $self = shift;
	$self->{"poolOrder"} = shift;
}

sub Col {
	my $self = shift;

	return $self->{"column"};
}

sub SetColumn {
	my $self = shift;
	$self->{"column"} = shift;
}

sub Data {
	my $self = shift;

	return $self->{"data"};
}

sub SetData {
	my $self = shift;
	$self->{"data"} = shift;
}

sub Route {
	my $self = shift;

	return $self->{"routeType"};
}

sub RouteDist {
	my $self = shift;

	return $self->{"routeDist"};
}

sub SetRoute {
	my $self = shift;

	$self->{"routeType"} = shift;
}

sub SetRouteDist {
	my $self = shift;

	$self->{"routeDist"} = shift;
}

sub SetIsLast {
	my $self = shift;

	$self->{"isLast"} = shift;
}

sub GetIsLast {
	my $self = shift;

	return $self->{"isLast"};
}


sub GetType{
	my $self = shift;
	
	return $self->{"data"}->{"type"};
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

