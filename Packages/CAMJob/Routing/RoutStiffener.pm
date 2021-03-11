#-------------------------------------------------------------------------------------------#
# Description: Helper fucnction for stiffener routs
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutStiffener;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Helpers::GeneralHelper';
  
#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return rout depth of stiffener adhesive
# So for it is constant value, it can be change to dznamic which depands on real adhesive thickness
sub GetStiffAdhRotuDepth {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stiffSide = shift;    #top/bot
 
	
	
	
	
	my $depth = 250;    # depth value [mm], which is enough for mill through adhesive

	return $depth;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Routing::RoutDepthCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152456";
	my $step  = "o+1";

	my $mess = "";
	my $res = RoutDepthCheck->CheckDepthChainMerge( $inCAM, $jobId, \$mess );

	print "$res - $mess";

}

1;
