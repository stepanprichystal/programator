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

	my $layer;

	#flex
	if ( $flexType eq EnumsGeneral->PcbFlexType_FLEX ) {
		$layer = "m";
	}

	# rigid flex
	else {
		$layer = "v1";
	}
 
	my $sym       = "r3500";
	my $holePitch = 220;
	my $framDist  = 5;
	
	
	CamLayer->WorkLayer($inCAM, $layer);
	if ( CamFilter->SelectBySingleAtt( $inCAM, $jobId, ".pnl_place", "flexi_holes" ) ) {
		$inCAM->COM("sel_delete");
	}

	CamSymbol->AddCurAttribute($inCAM, $jobId, ".pnl_place", "flexi_holes");

	CamHelper->SetStep( $inCAM, "panel" );
	CamLayer->WorkLayer($inCAM, $layer);

	my $h = $lim{"yMax"};
	my $w = $lim{"xMax"} - $lim{"xMin"};

	# LT
	CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitch/2, "y" => $lim{"yMax"} - $framDist } );
	# RT
	CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ($w / 2 - $holePitch/2), "y" => $lim{"yMax"} - $framDist } );
	
	# LB
	CamSymbol->AddPad( $inCAM, $sym, { "x" => $w / 2 - $holePitch/2, "y" =>  $framDist } );
	# RB
	CamSymbol->AddPad( $inCAM, $sym, { "x" => $w - ($w / 2 - $holePitch/2), "y" =>  $framDist } );
	
	CamSymbol->ResetCurAttributes($inCAM);
	
	
	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


		use aliased 'Packages::CAMJob::Scheme::PnlSchemaPost';
		use aliased 'Packages::InCAM::InCAM';
	
		my $inCAM = InCAM->new();
		my $jobId = "d222763";
	
		my $mess = "";
	
	
		my $result = PnlSchemaPost->AddFlexiHoles( $inCAM, $jobId );
	
		print STDERR "Result is: $result, error message: $mess\n";

}

1;
