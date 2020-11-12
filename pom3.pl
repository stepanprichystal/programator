#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::InCAM::InCAM';

my $inCAM = InCAM->new();

my $jobId    = "d298638";
my $stepName = "panel";

my @inL = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1 );

my $botCnt       = 0;
my $prevLayerBot = undef;
for ( my $i = scalar( @inL / 2 ) ; $i < scalar(@inL) ; $i++ ) {

	my %srcLAtt = CamAttributes->GetLayerAttr( $inCAM, $jobId, "panel", $inL[$i] );

	if ( $srcLAtt{"layer_side"} =~ /bot/i && ( !defined $prevLayerBot || $prevLayerBot == 1 ) ) {
		$botCnt++;
		$prevLayerBot = 1;
	}
	else {
		$botCnt = 0;
	}

}

my $sLamCnt = $botCnt if ( $botCnt > 1 );

