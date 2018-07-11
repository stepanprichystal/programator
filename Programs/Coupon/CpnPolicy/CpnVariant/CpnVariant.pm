
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Coupon::CpnPolicy::CpnVariant::CpnVariant;

#3th party library
use strict;
use warnings;
use List::Util qw[max];
use overload '""' => \&stringify;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"singleCpns"} = [];
	$self->{"settings"}   = undef;

	return $self;
}

sub SetCpnSettings {
	my $self = shift;
	my $sett = shift;

	$self->{"settings"} = $sett;
}

sub GetCpnSettings{
	my $self = shift;
	my $sett = shift;

	$self->{"settings"} = $sett;	
}

sub AddCpnSingle {
	my $self      = shift;
	my $singleCpn = shift;

	push( @{ $self->{"singleCpns"} }, $singleCpn );
}

sub GetSingleCpnsCnt {
	my $self = shift;

	return scalar( @{ $self->{"singleCpns"} } );
}

sub GetSingleCpns {
	my $self = shift;

	return @{ $self->{"singleCpns"} };
}

# return number of column positions
sub GetColumnCnt {
	my $self = shift;
	my @cols = map { $_->GetColumnCnt() } @{ $self->{"singleCpns"} };
	return max(@cols);

}

# |=============================Coupon=============================|
# | ________________________ Coupon single 2 ______________________|
# | Pool 2 - track pad + tracks                                    |
# | ...... - gnd pads .............................................|
# | Pool 1 - track pad + tracks                                    |
# | ________________________ Coupon single 1 ______________________|
# | Pool 2 - track pad + tracks                                    |
# | ...... - gnd pads .............................................|
# | Pool 1 - track pad + tracks                                    |
# |================================================================|
#=============================================
#Variant: single cpn = 1:
#-Single cpn 0.----------------------------
#--- Pool 0.............................
#-------- Strip 0 - se.
#--- Pool 1.............................
#-------- Strip 0 - se.

sub stringify {
	my ($self) = @_;

	my $str = "|============================= Coupon =============================|\n";

	#$str .= "Variant: single cpn = " . $self->GetSingleCpnsCnt() . ":\n";

	for ( my $i = scalar( @{ $self->{"singleCpns"} } ) - 1 ; $i >= 0 ; $i-- ) {

		my $scpn  = $self->{"singleCpns"}->[$i];
		my @pools = $scpn->GetPools();

		$str .= "|________________________ Coupon single " . $i . " ________________________\n";

		for ( my $j = scalar(@pools) - 1 ; $j >= 0 ; $j-- ) {

			my $p = $pools[$j];

			$str .= "| Pool " . $p->GetOrder() . "  \n";

			my @strips = $p->GetStrips();

			for ( my $k = 0 ; $k < scalar(@strips) ; $k++ ) {

				my $s = $strips[$k];

				$str .= "|-- Strip type - " . $s->GetType() . " ( track: " . $s->Data()->{"xmlConstraint"}->GetTrackLayer() . ")\n";

			}
		}

	}

	$str .= "|==================================================================|\n";

	return $str;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

