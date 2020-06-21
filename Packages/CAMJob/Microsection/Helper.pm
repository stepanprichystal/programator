#-------------------------------------------------------------------------------------------#
# Description: Helper function for coupons
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Microsection::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub PrepareProfileRoutOnBridges {
	my $self         = shift;
	my $inCAM        = shift;
	my $jobId        = shift;
	my $step         = shift;
	my $horizontal   = shift // 1;
	my $vertical     = shift // 1;
	my $bridgeCntH   = shift;
	my $bridgeCntV   = shift;
	my $bridgesWidth = shift;        # width in µm
	my $toolSize = shift // 2000; # 200µm tool for routing

	CamMatrix->CreateLayer( $inCAM, $jobId, "f", "rout", "positive", 1 ) unless ( CamHelper->LayerExists( $inCAM, $jobId, "f" ) );
	CamLayer->WorkLayer( $inCAM, "f" );
	 

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $step );
	my $h   = $lim{"yMax"} - $lim{"yMin"};
	my $w   = $lim{"xMax"} - $lim{"xMin"};

	my $featStart;

	if ($horizontal) {

		# Draw TOP horizontal edge
		$featStart = $self->__DrawOutlineRout( $inCAM, { "x" => 0, "y" => $h }, { "x" => $w, "y" => $h }, $bridgeCntH, $bridgesWidth / 1000 );

		# Draw BOT horizontal edge
		$featStart = $self->__DrawOutlineRout( $inCAM, { "x" => $w, "y" => 0 }, { "x" => 0, "y" => 0 }, $bridgeCntH, $bridgesWidth / 1000 );

	}

	if ($vertical) {

		# Draw LEFT verticall edge
		$featStart = $self->__DrawOutlineRout( $inCAM, { "x" => 0, "y" => 0 }, { "x" => 0, "y" => $h }, $bridgeCntV, $bridgesWidth / 1000 );

		# Draw RIGHT horizontal edge
		$featStart = $self->__DrawOutlineRout( $inCAM, { "x" => $w, "y" => $h }, { "x" => $w, "y" => 0 }, $bridgeCntV, $bridgesWidth / 1000 );

	}

	# Add chain
	$inCAM->COM(
		'chain_add',
		"layer"          => "f",
		"chain"          => 1,
		"size"           => $toolSize/1000,
		"comp"           => "left",
		"first"          => defined $featStart ? $featStart - 1 : 0,    # id of edge, which should route start - 1 (-1 is necessary)
		"chng_direction" => 0
	);

	# Set step attribute "rout on bridges"rout_on_b
	CamAttributes->SetStepAttribute( $inCAM, $jobId, $step, "rout_on_bridges", "yes" );
	
	return 1;

}

# Draw rout with bridges for coupon edge
sub __DrawOutlineRout {
	my $self         = shift;
	my $inCAM        = shift;
	my $startP       = shift;
	my $endP         = shift;
	my $bridgesCnt   = shift;
	my $bridgesWidth = shift;

	my $type;

	if ( abs( $startP->{"y"} - $endP->{"y"} ) == 0 ) {

		$type = "h";
	}
	elsif ( abs( $startP->{"x"} - $endP->{"x"} ) == 0 ) {
		$type = "v";
	}
	else {

		die "Wrong start end point coupon rout slots point.";
	}

	my $edgeLen = $type eq "v" ? abs( $startP->{"y"} - $endP->{"y"} ) : abs( $startP->{"x"} - $endP->{"x"} );
	my $toolw = 2;    # tool size 2mm

	my $slotLen = $edgeLen;

	if ( $bridgesCnt > 0 ) {
		$slotLen = ( $slotLen - $bridgesCnt * ( $bridgesWidth + $toolw ) ) / ( $bridgesCnt + 1 );
	}

	my $curX = $startP->{"x"};
	my $curY = $startP->{"y"};
	for ( my $i = 0 ; $i < scalar( $bridgesCnt + 1 ) ; $i++ ) {

		if ( $type eq "h" ) {

			my $sign = $endP->{"x"} - $startP->{"x"} > 1 ? 1 : -1;

			CamSymbol->AddLine( $inCAM, { "x" => $curX, "y" => $curY }, { "x" => $curX + $sign * $slotLen, "y" => $curY }, "r200", "positive" );

			$curX += $sign * ( $slotLen + $bridgesWidth + $toolw );

		}
		elsif ( $type eq "v" ) {

			my $sign = $endP->{"y"} - $startP->{"y"} > 1 ? 1 : -1;

			CamSymbol->AddLine( $inCAM, { "x" => $curX, "y" => $curY }, { "x" => $curX, "y" => $curY + $sign * $slotLen }, "r200", "positive" );
			$curY += $sign * ( $slotLen + $bridgesWidth + $toolw );
		}
	}

	return $inCAM->GetReply();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

