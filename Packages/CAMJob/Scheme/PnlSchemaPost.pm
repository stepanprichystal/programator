#-------------------------------------------------------------------------------------------#
# Description: Adjustment of customer schema
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Scheme::PnlSchemaPost;

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
#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub AddFlexiHoles {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my $result = 1;

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return unless ($flexType);

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, "panel" );

	my @layers = ();

	#flex
	if ( $flexType eq EnumsGeneral->PcbFlexType_FLEX ) {
		push( @layers, "m" );
	}

	# rigid flex
	else {

		push( @layers, "v1" );
	}

	my @lOther =
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ] );

	push( @layers, map { $_->{"gROWname"} } @lOther ) if (@lOther);

	foreach my $layer (@layers) {

		my $sym       = ( $layer =~ /^m|v1$/ ) ? "r3500" : "r4000";
		my $holePitch = 220;
		my $framDist  = 5;

		CamLayer->WorkLayer( $inCAM, $layer );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "flexi_holes" ) ) {
			$inCAM->COM("sel_delete");
		}

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "flexi_holes" );

		CamHelper->SetStep( $inCAM, "panel" );
		CamLayer->WorkLayer( $inCAM, $layer );

		my $h = $lim{"yMax"};
		my $w = $lim{"xMax"} - $lim{"xMin"};

		# LT
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitch / 2, "y" => $lim{"yMax"} - $framDist } );

		# RT
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ( $w / 2 - $holePitch / 2 ), "y" => $lim{"yMax"} - $framDist } );

		# LB
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitch / 2, "y" => $framDist } );

		# RB
		CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ( $w / 2 - $holePitch / 2 ), "y" => $framDist } );

		CamSymbol->ResetCurAttributes($inCAM);

	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Check if mpanel contain requsted schema by customer
sub AddPressHolesCoverlay {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $result = 1;

	return 0 if ( $stepName ne "panel" );

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return 0 if ( $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXI );

	my @coverlay =
	  CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill, EnumsGeneral->LAYERTYPE_nplt_cvrlysMill ] );

	my @scanMarks = CamNCHooks->GetLayerCamMarks( $inCAM, $jobId, $stepName, "v1" );
	my %bot = CamNCHooks->GetScanMarkPoint(\@scanMarks, "3-15mm-IN-left-bot");
	my %top = CamNCHooks->GetScanMarkPoint(\@scanMarks, "3-15mm-IN-left-top");

	foreach my $layer (@coverlay) {

		CamLayer->WorkLayer( $inCAM, $layer->{"gROWname"} );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "coverlay_press" ) ) {
			$inCAM->COM("sel_delete");
		}
		
		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "coverlay_press" );
		
		CamSymbol->AddPad( $inCAM, "r4000", \%top );
		CamSymbol->AddPad( $inCAM, "r4000", \%bot );

		CamSymbol->ResetCurAttributes($inCAM);
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Scheme::PnlSchemaPost';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d222775";

	my $mess = "";

	my $result = PnlSchemaPost->AddPressHolesCoverlay( $inCAM, $jobId, "panel" );

	print STDERR "Result is: $result, error message: $mess\n";

}

1;
