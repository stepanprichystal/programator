
#-------------------------------------------------------------------------------------------#
# Description:  
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Coupon::CpnPolicy::CpnVariant::CpnVariant;

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
 
	$self->{"singleCpns"} = [];
	 
	return $self;
}

sub AddCpnSingle{
	my $self = shift;
	my $singleCpn = shift;
	
	push(@{$self->{"singleCpns"}}, $singleCpn);
} 

sub GetSingleCpnsCnt{
		my $self = shift;
	
	return scalar(@{$self->{"singleCpns"}});
}

sub GetSingleCpns{
	my $self = shift;
	
	return @{$self->{"singleCpns"}};
}

# return number of column positions
sub GetColumnCnt{
	my $self = shift;
	my @cols = map { $_->GetColumnCnt() }   @{$self->{"singleCpns"}};
	return max(@cols);

} 


#sub stringify {
#    my ($self) = @_;
#  
#	my $str = "Variant: single cpn = ".$self->GetSingleCpnsCnt().":\n";
#	
#	 for(my $i= 0; $i < scalar(@{$self->{"singleCpns"}}); $i++){
#	 	
#	 	my $scpn = $self->{"singleCpns"}->[$i];
#	 	my @pools = $scpn->GetPools();
#	 	
#	 	$str.= "-Single cpn $i.----------------------------\n";
#	 	 
#	 	
#	  for(my $j= 0;  $j < scalar(@pools); $j++){
#	  	
#	  	
#	  	my $p = $pools[$j];
#	  	
#	  	$str.= "...... Pool $j.............................\n";
#	  	
#	  }
#	  
#	  
#	 	
#	 }
#	 
#	 
# 
#
#
#}
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

