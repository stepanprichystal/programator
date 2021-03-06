
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnPolicy::CpnVariant::CpnSingleVariant;

#3th party library
use strict;
use warnings;
use List::Util qw[max];

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"pools"} = [];

	$self->{"settings"}   = undef;

	return $self;
}

sub SetOrder{
	my $self = shift;	
	
	$self->{"order"} = shift;
}

sub GetOrder{
	my $self = shift;
	  
	return $self->{"order"};
} 

sub SetCpnSingleSettings {
	my $self = shift;
	my $sett = shift;

	$self->{"settings"} = $sett;
}

sub GetCpnSingleSettings{
	my $self = shift;
	return $self->{"settings"};	
}

sub AddPool {
	my $self = shift;
	my $pool = shift;

	push( @{ $self->{"pools"} }, $pool );
}

sub GetPools {
	my $self = shift;

	return @{ $self->{"pools"} };
}

sub GetPoolByOrder {
	my $self = shift;
	my $order = shift;

	my $pool = (grep { $_->GetOrder() eq $order } @{ $self->{"pools"} })[0];

	return $pool;
}

sub IsMultistrip {
	my $self = shift;

	my $stripCnt = 0;

	foreach my $pool ( @{ $self->{"pools"} } ) {

		$stripCnt += scalar(  $pool->GetStrips() );
	}
	
	if($stripCnt > 1){
		return 1;
	}else{
		return 0;
	}
}

sub GetColumnCnt {
	my $self = shift;

	my @cols = map { $_->GetColumnCnt() } @{ $self->{"pools"} };

	return max(@cols);
}

sub GetStripsByColumn{
	my $self = shift;
	my $column = shift;
	
	
	
	my @strips = grep { defined $_ } map { $_->GetStripByColumn($column) } @{ $self->{"pools"} };
	
	return @strips;
}

sub GetStripsByLayer{
	my $self = shift;
	my $trackLayer = shift;  
 
	my @strips =  map { $_->GetStripsByLayer($trackLayer) } @{ $self->{"pools"} };
	
	return @strips;
}

sub GetAllStrips{
	my $self = shift;
	my $column = shift;
	
	my @strips = map { $_->GetStrips() } @{ $self->{"pools"} };
	
	return @strips;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

