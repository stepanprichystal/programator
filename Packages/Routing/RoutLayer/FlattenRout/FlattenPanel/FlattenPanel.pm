
#-------------------------------------------------------------------------------------------#
# Description: Create flatten special step "panel". Set rout start, foot down, sort tools
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::FlattenPanel::FlattenPanel;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;

#local library

use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
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

	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"stepName"}     = shift;    # Step to flatten
	$self->{"excludeSteps"} = shift;    # exclude specified nested steps from rout creating

	$self->{"result"} = 1;              # indicate if remove final faltten layer in case of errors

	$self->{"inCAM"}->COM("disp_off");

	return $self;
}

sub Run {
	my $self            = shift;
	my $srcLayer        = shift;        # source layer, which is flattened
	my $destLayer       = shift;        # name of result flattened layer
	my $noDrawing       = shift;        # if set, result is not drawed, when create rout is succes
	my $outlRoutStart   = shift;        # PCB outline rout start corner
	my $outlPnlSequence = shift;        # Panel routing sequence direction

	die "No PCB outline rout start corner defined"    unless ( defined $outlRoutStart );
	die "No panel routing sequence direction defined" unless ( defined $outlPnlSequence );

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $workLayer = $srcLayer; # Work layer is standard source layer, except nested steps contains SR

	# 1) Check if step contain only not SR steps. If Nested steps contain SR, flatten them and sort tool
	$self->__ProcessResult( $self->__FlattenNestedSteps( $srcLayer, \$workLayer, $outlPnlSequence ) );

	# 2) Init structure suitable for, flatten step, rout checking and rout start finding
	my $SRStep = SRStep->new( $inCAM, $jobId, $self->{"stepName"}, $workLayer, $self->{"excludeSteps"} );
	$SRStep->Init();

	# 3) Checks rout validity before flatten
	my $checks = StepCheck->new( $inCAM, $jobId, $SRStep );

	$self->__ProcessResult( $checks->OnlyBridges() );

	$self->__ProcessResult( $checks->OutsideChains() );

	$self->__ProcessResult( $checks->OutlineRoutChecks() );

	$self->__ProcessResult( $checks->OutlineToolIsLast() );

	# 4) Find start of chains

	my $routStart = RoutStart->new( $inCAM, $jobId, $SRStep );

	my $resFindStart = $routStart->FindStart($outlRoutStart);

	$self->__ProcessResult($resFindStart);

	# 5) Flatten modified and checked rout chains
	my $flatt = FlattenRout->new( $inCAM, $jobId, $destLayer, 0, 1, $outlPnlSequence );

	my $resFlattenRout = $flatt->CreateFromSRStep($SRStep);

	$self->__ProcessResult($resFlattenRout);
	
	# 6) Merge tools in work layer
	

	# 6) Draw start chain and foots to new layer (if drawing is not switched off)

	if ( !( $noDrawing && $self->{"result"} ) ) {

		my $draw = RoutDraw->new( $inCAM, $jobId, $self->{"stepName"}, $destLayer );

		$draw->CreateResultLayer( $resFindStart->{"errStartSteps"}, $resFlattenRout->{"chainOrderIds"} );
	}

	# 7) Cleaning matrix...

	# it means, that nested step was SR and flattened later for nested step was created... SO delete it
	if ( $workLayer ne $srcLayer ) {

		$inCAM->COM( 'delete_layer', "layer" => $workLayer );
	}

	$SRStep->Clean();

	unless ( $self->{"result"} ) {

		if ( CamHelper->LayerExists( $inCAM, $jobId, $destLayer ) ) {
			$inCAM->COM( 'delete_layer', "layer" => $destLayer );
		}
	}

	return $self->{"result"};
}

# Warning, worklayer can be changed, id nested steps contains SR
sub __FlattenNestedSteps {
	my $self            = shift;
	my $srcLayer        = shift;
	my $workLayer       = shift;
	my $outlPnlSequence = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $resultItem = ItemResult->new("Flatten nested steps");

	# Get unique nested steps and exclude nested steps if requested
	my @uniqueSR = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $self->{"stepName"} );

	if ( $self->{"excludeSteps"} ) {
		my %tmp;
		@tmp{ @{ $self->{"excludeSteps"} } } = ();
		@uniqueSR = grep { !exists $tmp{ $_->{"stepName"} } } @uniqueSR;
	}

	# 1) Check if exist nested step which contain S&R
	my $nestedHasSR = 0;
	foreach my $uStep (@uniqueSR) {

		if ( CamStepRepeat->ExistStepAndRepeats( $self->{"inCAM"}, $self->{"jobId"}, $uStep->{"stepName"} ) ) {
			$nestedHasSR = 1;
			last;
		}
	}

	unless ($nestedHasSR) {
		return $resultItem;
	}

	# 2) Check if depth of S&R of nested steps is not bigger then one
	foreach my $s (@uniqueSR) {
		if ( CamStepRepeat->GetStepAndRepeatDepth( $inCAM, $jobId, $s->{"stepName"} ) > 1 ) {

			die "Step: " . $self->{"stepName"} . " has S&R depth (nesting) greater than depth = 2.\n Problem nested step: " . $s->{"stepName"};
		}
	}

	# Change work layer - create new
	$$workLayer = GeneralHelper->GetGUID();

	# 3) Flatten all nested steps which have S&R

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

	foreach my $step (@SRsteps) {

		my $flat = FlattenRout->new( $inCAM, $jobId, $$workLayer, 1, 0, $outlPnlSequence );
		my $resItem = $flat->CreateFromStepName( $step->{"stepName"}, $srcLayer, $resultItem );

	}

	# 3) rest of not SR step copy to new "flatten" layer

	foreach my $step (@noSRsteps) {

		CamHelper->SetStep( $inCAM, $step->{"stepName"} );

		$inCAM->COM(
					 'copy_layer',
					 "source_job"   => $jobId,
					 "source_step"  => $step->{"stepName"},
					 "source_layer" => $srcLayer,
					 "dest"         => 'layer_name',
					 "dest_layer"   => $$workLayer,
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

	if ( $res->Result() eq ResEnums->ItemResult_Fail ) {

		if ( $res->GetWarningCount() > 0 ) {

			print STDERR "Warning:\n\n" . $res->GetWarningStr();
		}

		if ( $res->GetErrorCount() > 0 ) {

			$self->{"result"} = 0;

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

