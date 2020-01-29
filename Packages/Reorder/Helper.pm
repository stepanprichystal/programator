#-------------------------------------------------------------------------------------------#
# Description: Helper function for reorders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Reorder::Enums';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return reorder type based on order id
sub GetReorderType {
	my $self    = shift;
	my $inCAM   = shift;
	my $orderId = shift;
	my ($jobId) = $orderId =~ /^(\w\d+)-(\d+)/i;
	$jobId = lc($jobId);

	my $isPool      = HegMethods->GetPcbIsPool($jobId);
	my $pnlExist    = CamHelper->StepExists( $inCAM, $jobId, "panel" );
	my $reorderType = undef;

	$reorderType = Enums->ReorderType_POOL             if ( $isPool  && !$pnlExist );
	$reorderType = Enums->ReorderType_POOLFORMERSTD    if ( $isPool  && $pnlExist && $orderId !~ /-01/ );
	$reorderType = Enums->ReorderType_POOLFORMERMOTHER if ( $isPool  && $pnlExist && $orderId =~ /-01/ );
	$reorderType = Enums->ReorderType_STD              if ( !$isPool && $pnlExist );
	$reorderType = Enums->ReorderType_STDFORMERPOOL    if ( !$isPool && !$pnlExist );

	return $reorderType;

}

1;
