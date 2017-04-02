
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for NIF creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::FlattenPanel::FlattenPanel;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library

#use aliased 'Packages::Export::NifExport::NifSection';
#use aliased 'Packages::Export::NifExport::NifBuilders::V0Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::V1Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::V2Builder';
#use aliased 'Packages::Export::NifExport::NifBuilders::VVBuilder';
#use aliased 'Packages::Export::NifExport::NifBuilders::PoolBuilder';
#use aliased 'Helpers::JobHelper';
#use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';

#use aliased 'Enums::EnumsGeneral';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Connectors::HeliosConnector::HegMethods';
#use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';

use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::SRStep::SRStep';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::StepCheck::StepCheck';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::RoutStart::RoutStart';
use aliased 'Packages::ItemResult::Enums' => "ResEnums";
use aliased 'Packages::Routing::RoutLayer::FlattenRout::RoutDraw::RoutDraw';
use aliased 'Packages::Routing::RoutLayer::FlattenRout::SRFlatten::FlattenRout';
use aliased 'Packages::ItemResult::ItemResult';

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
	$self->{"stepName"}  = shift;
	$self->{"layer"}     = shift;
	$self->{"flatLayer"} = shift;

	$self->{"deleteLayer"} = 0;    # indicate if remove final faltten layer in case of errors

	# Test if nested steps has to be flatened, because contain SR
	$self->{"preparedL"} = $self->{"layer"};
	
	$self->{"inCAM"}->COM("disp_off");

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#$inCAM->COM("disp_off");

	# 1) Check if step contain only not SR steps. If Nested steps contain SR, flatten them and sort tool
	$self->__ProcessResult( $self->__FlattenNestedSteps() );

	# 2) init structure suitable for, flatten step, rout checking and rout start finding
	my $SRStep = SRStep->new( $inCAM, $jobId, $self->{"stepName"}, $self->{"preparedL"} );
	$SRStep->Init();

	# 3) checks
	my $checks = StepCheck->new( $inCAM, $jobId, $SRStep );

	$self->__ProcessResult( $checks->OnlyBridges() );

	$self->__ProcessResult( $checks->OutsideChains() );

	$self->__ProcessResult( $checks->LeftRoutChecks() );

	$self->__ProcessResult( $checks->OutlineToolIsLast() );

	# 4) Find start of chains

	my $routStart = RoutStart->new( $inCAM, $jobId, $SRStep );

	my $resFindStart = $routStart->FindStart();

	$self->__ProcessResult($resFindStart);

	# 5) Flatten modified and checked rout chains

	my $flatt = FlattenRout->new( $inCAM, $jobId, $self->{"flatLayer"}, 0 );

	my $resFlattenRout = $flatt->CreateFromSRStep($SRStep);

	$self->__ProcessResult($resFlattenRout);

	# 6) Draw start chain and foots to new layer

	my $draw = RoutDraw->new( $inCAM, $jobId, $self->{"stepName"}, $self->{"flatLayer"} );

	$draw->CreateResultLayer( $resFindStart->{"errStartSteps"}, $resFlattenRout->{"chainOrderIds"} );
	
	
	# 7) Cleaning matrix...
	
	# it means, that nested step was SR and flattened later for nested step was created... SO delete it
	if($self->{"preparedL"} ne $self->{"layer"}){
		
		$inCAM->COM( 'delete_layer', "layer" => $self->{"preparedL"} );
	}
	
	$SRStep->Clean();

	
	if ( $self->{"deleteLayer"} ) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $self->{"flatLayer"} ) ) {
			$inCAM->COM( 'delete_layer', "layer" => $self->{"flatLayer"} );
		}
	}
}

sub __NestedStepsAreSR {
	my $self = shift;

	my $res = 0;

	my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"} );

	foreach my $uStep (@uniqueSR) {

		if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $uStep->{"stepName"} ) ) {
			$res = 1;
			last;
		}

	}

	return $res;
}

sub __FlattenNestedSteps {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	
	my $resultItem = ItemResult->new("Flatten nested steps");

	unless ( $self->__NestedStepsAreSR() ) {
		return $resultItem;
	}

	if ( $self->__NestedStepsAreSR() ) {
		$self->{"preparedL"} = GeneralHelper->GetGUID();
	}
 
	#my @repeatsSR = CamStepRepeat->GetRepeatStep( $inCAM, $jobId, $self->{"stepName"} );
	my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $self->{"inCAM"}, $self->{"jobId"}, $self->{"stepName"} );

	# No nested step can have SR

	my @SRsteps   = ();
	my @noSRsteps = ();

	foreach my $step (@uniqueSR) {
		if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $step->{"stepName"} ) ) {
			push( @SRsteps, $step );

		}
		else {

			push( @noSRsteps, $step );
		}
	}

	# 1) flatten all nested SR steps

	foreach my $step (@SRsteps) {

		# test if nested steps contain SR, if so die

		my @nest = CamStepRepeat->GetUniqueStepAndRepeat( $self->{"inCAM"}, $self->{"jobId"}, $step->{"stepName"} );
		foreach my $ns (@nest) {
			if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $ns->{"stepName"} ) ) {
				die "Step can't contin SandR steps";
			}
		}
		my $flat = FlattenRout->new( $inCAM, $jobId, $self->{"preparedL"}, 1 );
		my $resItem = $flat->CreateFromStepName( $step->{"stepName"}, $self->{"layer"}, $resultItem);
		 
	}

	# 2) rest of not SR step copy to new "flatten" layer
	
	

	foreach my $step (@noSRsteps) {
		
		CamHelper->SetStep($inCAM, $step->{"stepName"});

		$inCAM->COM(
					 'copy_layer',
					 "source_job"   => $jobId,
					 "source_step"  => $step->{"stepName"},
					 "source_layer" => $self->{"layer"},
					 "dest"         => 'layer_name',
					 "dest_layer"   => $self->{"preparedL"},
					 "mode"         => 'replace',
					 "invert"       => 'no'
		);
	}

	return $resultItem;
}

sub __ProcessResult {
	my $self = shift;
	my $res  = shift;

	$self->_OnItemResult($res);

	if ( $res eq ResEnums->ItemResult_Fail ) {

		if ( $res->GetWarningCount() > 0 ) {

			print STDERR "Warning:\n\n" . $res->GetWarningStr();
		}

		if ( $res->GetErrorCount() > 0 ) {

			$self->{"deleteLayer"} = 1;

			print STDERR "Errors:\n\n" . $res->GetErrorStr();
		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Routing::RoutLayer::FlattenRout::RoutingMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f52456";
	#
	#
	#
	#
	#	my $routMngr = RoutingMngr->new( $inCAM, $jobId );
	#	$routMngr->Run();

}

1;

