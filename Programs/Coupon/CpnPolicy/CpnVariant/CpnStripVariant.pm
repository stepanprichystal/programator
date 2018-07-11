
#-------------------------------------------------------------------------------------------#
# Description:  
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnPolicy::CpnVariant::CpnStripVariant;

#3th party library
use strict;
use warnings;

#local library
use overload '""' => \&stringify;
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
	$self->{"routeWidth"} = undef;
	$self->{"isLast"} = undef;
	$self->{"settings"}   = undef;

	return $self;
}

sub SetCpnStripSettings {
	my $self = shift;
	my $sett = shift;

	$self->{"settings"} = $sett;
}

sub GetCpnStripSettings{
	my $self = shift;
	my $sett = shift;

	$self->{"settings"} = $sett;	
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

sub RouteWidth {
	my $self = shift;

	return $self->{"routeWidth"};
}

sub SetRoute {
	my $self = shift;

	$self->{"routeType"} = shift;
}

sub SetRouteDist {
	my $self = shift;

	$self->{"routeDist"} = shift;
}

sub SetRouteWidth {
	my $self = shift;

	$self->{"routeWidth"} = shift;
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



sub stringify {
	my ($self) = @_;

	return $self->Data()->{"title"};

	
}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

