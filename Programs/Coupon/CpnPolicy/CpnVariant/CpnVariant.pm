
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

sub GetCpnSettings {
	my $self = shift;

	return $self->{"settings"};
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
	my $str = "";

	$str .= __FillRow( "=", "center", " Coupon " );

	#$str .= "Variant: single cpn = " . $self->GetSingleCpnsCnt() . ":\n";

	for ( my $i = scalar( @{ $self->{"singleCpns"} } ) - 1 ; $i >= 0 ; $i-- ) {

		my $scpn  = $self->{"singleCpns"}->[$i];
		my @pools = $scpn->GetPools();

		$str .= __FillRow( " ", "left",   "" );
		$str .= __FillRow( "-", "center", " Coupon group: ".($i+1)." ");

		for ( my $j = scalar(@pools) - 1 ; $j >= 0 ; $j-- ) {

			my $p = $pools[$j];

			if ( $p->GetOrder() == 1 ) {
				$str .= __FillRow( " ", "left", "Top microstrips:" );
			}
			else {
				$str .= __FillRow( " ", "left", "Bottom microstrips:" );
			}

			my @strips = $p->GetStrips();

			for ( my $k = 0 ; $k < scalar(@strips) ; $k++ ) {

				my $s = $strips[$k];

				$str .= __FillRow( " ", "left",
					 " - " . $s->GetType() . "-" . $s->GetModel() . " ( track: " . $s->Data()->{"xmlConstraint"}->GetTrackLayer() . ")" );

			}
			$str .= __FillRow( " ", "left",   "" );
		}
	}

	 
	$str .= __FillRow( "=", "center", "" );

	return $str;

	sub __FillRow {
		my $fillChar = shift;
		my $textPos  = shift // "center";    # left/center
		my $text     = shift;

		my $totalfillCnt = 70;
		my $fillCnt      = int( $totalfillCnt - length($text) );    #60 is requested total title len

		my $row = "| ";

		if ( $textPos eq "left" ) {
			$row .= $text;
			$row .= $fillChar for (0..$fillCnt);

		}
		elsif ( $textPos eq "center" ) {
			$row .= $fillChar for ( 0..$fillCnt / 2 );
			$row .= $text;
			$row .= $fillChar for ( 0..$fillCnt / 2 );
		}

		$row .= " |\n";

		return $row;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

