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

sub AddHolesCoverlay {
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
	
	# press holes
	my %pressBot = CamNCHooks->GetScanMarkPoint( \@scanMarks, "3-15mm-IN-left-bot" );
	my %pressTop = CamNCHooks->GetScanMarkPoint( \@scanMarks, "3-15mm-IN-left-top" );
	
	my %olecLT = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-left-top" );
	my %olecRT = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-right-top" );
	my %olecRB = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-right-bot" );
	my %olecLB = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Inner-left-bot" );

	foreach my $layer (@coverlay) {

		CamLayer->WorkLayer( $inCAM, $layer->{"gROWname"} );
		if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "coverlay_press" ) ) {
			$inCAM->COM("sel_delete");
		}

		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "coverlay_press" );

		CamSymbol->AddPad( $inCAM, "r4000", \%pressTop );
		CamSymbol->AddPad( $inCAM, "r4000", \%pressBot );

		CamSymbol->ResetCurAttributes($inCAM);
		
		
		CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "coverlay_olec_vv" );

		CamSymbol->AddPad( $inCAM, "r4000", \%olecLT );
		CamSymbol->AddPad( $inCAM, "r4000", \%olecRT );
		CamSymbol->AddPad( $inCAM, "r4000", \%olecRB );
		CamSymbol->AddPad( $inCAM, "r4000", \%olecLB );

		CamSymbol->ResetCurAttributes($inCAM);
	}

}

sub AddFlexiCoreHoles {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;

	my $result = 1;

	return 0 if ( $stepName ne "panel" );

	my $flexType = JobHelper->GetPcbFlexType($jobId);

	return 0 if ( $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXI && $flexType ne EnumsGeneral->PcbFlexType_RIGIDFLEXO );

	my $l = "v1";

	my @scanMarks = CamNCHooks->GetLayerCamMarks( $inCAM, $jobId, $stepName, "c" );
	my %lt = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-left-top" );
	my %rt = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-right-top" );
	my %lb = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-left-bot" );
	my %rb = CamNCHooks->GetScanMarkPoint( \@scanMarks, "O-Outer_VV-right-bot" );

	CamLayer->WorkLayer( $inCAM, $l );
	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "flexi_olec" ) ) {
		$inCAM->COM("sel_delete");
	}

	CamSymbol->AddCurAttribute( $inCAM, $jobId, ".pnl_place", "flexi_olec" );

	CamSymbol->AddPad( $inCAM, "r3000", \%lt );
	CamSymbol->AddPad( $inCAM, "r3000", \%rt );
	CamSymbol->AddPad( $inCAM, "r3000", \%lb );
	CamSymbol->AddPad( $inCAM, "r3000", \%rb );

	CamSymbol->ResetCurAttributes($inCAM);
	CamLayer->ClearLayers( $inCAM, $l );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Scheme::PnlSchemaPost';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113609";

	my $mess = "";

	my $result = PnlSchemaPost->AddFlexiCoreHoles( $inCAM, $jobId, "panel" );

	print STDERR "Result is: $result, error message: $mess\n";

}

1;
