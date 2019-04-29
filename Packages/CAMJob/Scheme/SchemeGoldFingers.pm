#-------------------------------------------------------------------------------------------#
# Description: Adjustment of customer schema
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Scheme::SchemeGoldFingers;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamNCHooks';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'Packages::CAMJob::Scheme::SchemeFrame::SchemeFrame';
use aliased 'Packages::CAMJob::Scheme::SchemeFrame::Enums' => 'SchemeFrEnums';


#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Thera are equivalnet featrue att in InCAM
my $FRAME_GOLDFINGER = "goldfinger_frame";

sub AddGoldConFrame {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	
	my $schemeFrame = SchemeFrame->new($inCAM, $jobId );
	

	my @layers = ();
	push( @layers, "c" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) );
	push( @layers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	my $schema = "gold-2v";

	if ( CamJob->GetSignalLayerCnt($inCAM, $jobId) > 2 ) {
		$schema = 'gold-vv';
	}

	foreach my $l (@layers) {

		my $frameExist = $schemeFrame->ExistFrame( $l, $FRAME_GOLDFINGER );

		if ( CamGoldArea->GoldFingersExist( $inCAM, $jobId, "panel", $l ) ) {

			# 1) Add frame
			if ($frameExist) {
				$schemeFrame->DeleteFrame( $l, $FRAME_GOLDFINGER );
			}

			$schemeFrame->AddFrame( $l, $FRAME_GOLDFINGER, $schema );
		}
		else {

			if ($frameExist) {
				$schemeFrame->DeleteFrame( $l, $FRAME_GOLDFINGER );
			}
		}
	}

}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Packages::CAMJob::Scheme::PnlSchemaPost';
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $inCAM = InCAM->new();
#	my $jobId = "d113609";
#
#	my $mess = "";
#
#	my $result = PnlSchemaPost->AddFlexiCoreHoles( $inCAM, $jobId, "panel" );
#
#	print STDERR "Result is: $result, error message: $mess\n";

}

1;
