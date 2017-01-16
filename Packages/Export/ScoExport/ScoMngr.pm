
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for core files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ScoExport::ScoMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';

use aliased 'Packages::Scoring::ScoreChecker::ScoreChecker';
use aliased 'Packages::Scoring::ScoreOptimize::ScoreOptimize';
use aliased 'Packages::Export::ScoExport::ProgCreator::ProgCreator';
use aliased 'Packages::Export::ScoExport::Enums';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";
use aliased 'Packages::ItemResult::Enums'            => "ResEnums";
use aliased 'Packages::Polygon::Features::RouteFeatures::RouteFeatures';
use aliased 'Packages::Polygon::PolygonHelper';
use aliased 'Packages::Export::ScoExport::ScoreMarker';

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
	$self->{"type"}      = shift;

	$self->{"step"}         = "panel";          # step, whic programs are ceated from
	$self->{"finalLayer"}   = "score_layer";    # name of layer , which contains final score data
	$self->{"exportLayer"}  = undef;            # if optimiyation is manual, this is name of layer, which score data are taken form
	$self->{"optimizeData"} = undef;            # Final data structure, which provide data for export

	$self->{"frLim"} = $self->__GetFrLim();

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
	$self->{"marker"}  = ScoreMarker->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"scoreCheck"}, $self->{"frLim"} );
	$self->{"creator"} = ProgCreator->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"coreThick"},  $self->{"frLim"} );

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

	if ( !$self->{"scoreCheck"}->IsStraight() && !$self->{"scoreCheck"}->PcbDistanceOk() ) {

		$checkScoreRes->AddError("Small gap between pcb steps. Minimal gap is 4.5mm");
	}
	
	# Check if pcb distance is ok
	unless ( $self->{"scoreCheck"}->PcbDistanceOk() ) {

		$checkScoreRes->AddError("Gap between pcb is too small. Do bigger gap, min 4.5mm.");
	}

	$self->_OnItemResult($checkScoreRes);

	if ( $checkScoreRes->Result() eq ResEnums->ItemResult_Fail ) {

		print STDERR $errMess;
		return 0;
	}

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

	# 5) Put control lines to solder and signal layers
	$self->{"marker"}->Run();
	CamJob->SaveJob($inCAM, $jobId);

	# 6) Export program for machine
	$self->{"creator"}->Build( $self->{"type"}, $self->{"optimizeData"} );

	my $fileSave = $self->_GetNewItem("Saving file");

	if ( $self->{"optimizeData"}->ExistVScore() ) {
 
		unless ( $self->{"creator"}->SaveFile( ScoEnums->Dir_VSCORE ) ) {

			$fileSave->AddError("Failed when saving verticall score file.");
		}
	}

	if ( $self->{"optimizeData"}->ExistHScore() ) {
 
		unless ( $self->{"creator"}->SaveFile( ScoEnums->Dir_HSCORE ) ) {
			$fileSave->AddError("Failed when saving horizontall score file.");
		}
	}
	
	$self->_OnItemResult($fileSave);

	print STDERR $errMess;

}

# get information about	fr dimension
sub __GetFrLim {
	my $self = shift;

	my %lim = ();

	if ( CamHelper->LayerExists( $self->{"inCAM"}, $self->{"jobId"}, "fr" ) ) {

		my $fr = RouteFeatures->new();
		$fr->Parse( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"}, "fr" );
		my @features = $fr->GetFeatures();

		%lim = PolygonHelper->GetLimByRectangle( \@features );

		return \%lim;

	}

	return undef;
}

sub ExportItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += 1;    # score parse
	$totalCnt += 1;    # score optimization
	$totalCnt += 2;    # score export files

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Packages::Export::ScoExport::ScoreMngr';
#
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $inCAM = InCAM->new();
#
#	my $jobId = "f13610";
#
#	my $mngr = ScoreMngr->new( $inCAM, $jobId, 0.3, Enums->Optimize_YES, Enums->Type_CLASSIC );
#	$mngr->Run();
}

1;

