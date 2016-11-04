
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ScoreExport::ScoreMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreOptimize';
 
use aliased 'Packages::Export::ScoreExport::Enums';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}     = shift;
	$self->{"jobId"}     = shift;
	$self->{"coreThick"} = shift;
	$self->{"optimize"}  = shift;

	$self->{"finalLayer"}   = "score_layer";    # name of layer , which contains final score data
	$self->{"exportLayer"}  = undef;            # layer which score data are taken from
	$self->{"optimizeData"} = undef;            # Final data structure, which provide data for export

	my $step = "panel";

	my $SR = undef;

	if ( $self->{"optimize"} eq Enums->Optimize_MANUAL ) {

		$self->{"exportLayer"} = $self->{"finalLayer"};
		$SR = 0;

	}
	else {

		$self->{"exportLayer"} = "score";
		$SR = 1;
	}

	my $precision = 2;    # number of decimal, used when compering score position etc ()

	$self->{"scoreCheck"} = ScoreChecker->new( $self->{"inCAM"}, $self->{"jobId"}, $step, $self->{"exportLayer"}, $SR );
	$self->{"scoreOptimize"} = ScoreOptimize->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"scoreCheck"} );

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $checkScoreRes = $self->_GetNewItem("Score check");

	# 1) Check if exist layer to export
	unless ( CamHelper->LayerExists( $inCAM, $jobId, $self->{"exportLayer"} ) ) {

		$checkScoreRes->AddError( "Score layer: " . $self->{"exportLayer"} . "doesn't exist" );
	}

	# 2) Parse layer, check if data score data are ok

	$self->{"scoreCheck"}->Init();
	$self->{"scoreOptimize"}->Init();

	my $errMess = "";
	unless ( $self->{"scoreCheck"}->ScoreIsOk( \$errMess ) ) {

		$checkScoreRes->AddError($errMess);
	}

	$self->_OnItemResult($errMess);

	# 3) Optimize  and get score data
	if ( $self->{"optimize"} eq Enums->Optimize_YES ) {
		$self->{"scoreOptimize"}->Run(1);
	}
	elsif ( $self->{"optimize"} eq Enums->Optimize_NO || $self->{"optimize"} eq Enums->Optimize_MANUAL ) {

		$self->{"scoreOptimize"}->Run(0);
	}

	$self->{"optimizeData"} = $self->{"scoreOptimize"}->GetScoreData();

	# 4) Check result of optimalization
	if ( $self->{"optimize"} ne Enums->Optimize_MANUAL ) {

		$self->{"scoreOptimize"}->CreateScoreLayer();

		 
		my $optScoreRes = $self->_GetNewItem("Optimization");

		my $errMess2 = "";
		unless ( $self->{"scoreOptimize"}->ReCheck( \$errMess2 ) ) {

			$optScoreRes->AddError($errMess2);
		}
		$self->_OnItemResult($optScoreRes);
		
		print STDERR $errMess2;
	}


	# 5) Export program for machine

	print STDERR $errMess;
	

}

sub ExportItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1;    # score parse
	$totalCnt += 1;    # score optimization
	$totalCnt += 1;    # score export files

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Export::ScoreExport::ScoreMngr';

	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f53449";

	my $mngr = ScoreMngr->new( $inCAM, $jobId, 0.3, Enums->Optimize_YES );
	$mngr->Run();
}

1;

