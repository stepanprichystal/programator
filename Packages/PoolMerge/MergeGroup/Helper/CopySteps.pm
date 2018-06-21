
#-------------------------------------------------------------------------------------------#
# Description: Manager, copy steps
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::Helper::CopySteps;
use base("Packages::ItemResult::ItemEventMngr");

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"poolInfo"} = shift;

	return $self;
}

sub SetNewJobsState {
	my $self        = shift;
	my $masterOrder = shift;
	my $mess        = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my $newState = shift;

	HegMethods->UpdatePcbOrderState( $masterOrder, "slouceno-master", 1 );

	my @childOrders = $self->{"poolInfo"}->GetOrderNames();
	@childOrders = grep { $_ !~ /^$masterOrder$/i } @childOrders;

	foreach my $orderId (@childOrders) {

		HegMethods->UpdatePcbOrderState( $orderId, "slouceno", 1 );
	}

	return $result;
}

sub CopyChildSteps {
	my $self      = shift;
	my $masterJob = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @jobNames = $self->{"poolInfo"}->GetJobNames();
	@jobNames = grep { $_ !~ /^$masterJob$/i } @jobNames;

	foreach my $jobName (@jobNames) {

		my $copyStepRes = $self->_GetNewItem( $jobName, "Copy step \"o+1\"" );

		# 1) check on negative signal layers
		my @signalLayers = CamJob->GetBoardBaseLayers( $inCAM, $jobName );
		my @wrongPolar = grep { $_->{"gROWpolarity"} eq "negative" } @signalLayers;

		if ( scalar(@wrongPolar) ) {

			@wrongPolar = map { $_->{"gROWname"} } @wrongPolar;
			my $lStr = join( "; ", @wrongPolar );

			$copyStepRes->AddError("Pool job can't contain negative signal layers (\"$lStr\"). Child job $jobName");
		}

		# 2) delete step if exist
		if ( CamHelper->StepExists( $inCAM, $masterJob, $jobName ) ) {
			$inCAM->COM( "delete_entity", "job" => $masterJob, "name" => $jobName, "type" => "step" );
		}

		$inCAM->HandleException(1);

		# 3) copy step to master, name of step is jobname

		unless ( CamJob->IsJobOpen( $inCAM, $jobName ) ) {
			$inCAM->COM( "open_job", job => "$jobName", "open_win" => "no" );
		}
		
		

		$inCAM->COM(
					 "copy_entity",
					 "type"           => "step",
					 "source_job"     => $jobName,
					 "source_name"    => "o+1",
					 "dest_job"       => $masterJob,
					 "dest_name"      => $jobName,
					 "dest_database"  => "",
					 "remove_from_sr" => "no"
		);

		CamJob->CloseJob( $inCAM, $jobName );

		$inCAM->HandleException(0);

		my $err = $inCAM->GetExceptionError();
		if ($err) {

			$err .= "Error when copy step \"o+1\" from job $jobName to master job.\n" . $err;
			$copyStepRes->AddError($err);

		}

		$self->_OnItemResult($copyStepRes);
	}

	return $result;
}

sub CopyStepFinalCheck {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @jobNames = $self->{"poolInfo"}->GetJobNames();
	@jobNames = grep { $_ !~ /^$masterJob$/i } @jobNames;

	# 1) check if master job contain all child o+1 steps
	my @steps = CamStep->GetAllStepNames( $inCAM, $masterJob );

	# set aux group (we need run cmd for master job now)
	$inCAM->COM( "open_job", job => "$masterJob", "open_win" => "yes" );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	foreach my $stepName (@jobNames) {

		my $exist = scalar( grep { $_ eq $stepName } @steps );
		unless ($exist) {

			$result = 0;
			$$mess .= "Child step \"o+1\" from job \"$stepName\" was not copied to \"master job\".\n";
		}
	}

	# 2) Delete all after profile

	# base layers
	my @boardBase = map { $_->{"gROWname"} } CamJob->GetBoardBaseLayers( $inCAM, $masterJob );

	my @stepClip = ( @jobNames, "o+1" );

	foreach my $step (@stepClip) {

		CamHelper->SetStep( $inCAM, $step );
		CamLayer->AffectLayers( $inCAM, \@boardBase );

		$inCAM->COM(
					 "clip_area_end",
					 "layers_mode" => "affected_layers",
					 "area"        => "profile",
					 "area_type"   => "rectangle",
					 "inout"       => "outside",
					 "contour_cut" => "yes",
					 "margin"      => "3500",
					 "feat_types"  => "line\;pad;surface;arc;text",
					 "pol_types"   => "positive\;negative"
		);
	}

	# nc layers (pads only)
	my @ncLayers = map { $_->{"gROWname"} } CamJob->GetNCLayers( $inCAM, $masterJob );

	foreach my $step (@stepClip) {

		CamHelper->SetStep( $inCAM, $step );
		CamLayer->AffectLayers( $inCAM, \@ncLayers );

		$inCAM->COM(
					 "clip_area_end",
					 "layers_mode" => "affected_layers",
					 "area"        => "profile",
					 "area_type"   => "rectangle",
					 "inout"       => "outside",
					 "contour_cut" => "no",
					 "margin"      => "3500",
					 "feat_types"  => "pad",
					 "pol_types"   => "positive\;negative"
		);
	}

	CamLayer->ClearLayers($inCAM);

	# 3) Check if pcb is in zero and zero and datum point are on same position

	my @stepsZero = ( @jobNames, "o+1" );

	foreach my $step (@stepsZero) {
		

		my %lim = CamJob->GetProfileLimits2( $inCAM, $masterJob, $step, 1 );
		my %datum = CamStep->GetDatumPoint( $inCAM, $masterJob, $step );
		
		# check if zero point was not moved. If was (by InCAM Origin function), CamJob->GetProfileLimits return wrong results
		my %limOri = CamJob->GetProfileLimits2( $inCAM, $masterJob, $step, 0 );
		if (    ( int( $lim{"xMin"} ) == 0 && int( $limOri{"xMin"} ) != 0 )
			 || ( int( $lim{"yMin"} ) == 0 && int( $limOri{"yMin"} ) != 0 ) )
		{
			$result = 0;
			$$mess .= "Ve stepu: $step byla pravděpodobně přesunuta \"nula\" do pozice: [".$limOri{"xMin"}.",".$limOri{"yMin"}."] pomocí InCAM funkce \"Step/Origin\". " .
						"Vrať nulu do původní pozice (\"Step/Origin/Previous Origin\")\n";
		}
		

		if ( $datum{"x"} != 0 || $datum{"y"}  != 0 ) {

			$result = 0;
			$$mess .= "Ve stepu: $step není datum-point umístěn v nule. Posuň datum point do nuly.\n";
		}

		if ( abs( $lim{"xMin"} ) > 0.01  || abs( $lim{"yMin"} ) > 0.01 ) {

			$result = 0;
			$$mess .= "Ve stepu: $step není­ levý dolní roh profilu v \"nule\". Posuň levý dolní roh profilu do nuly.\n";
		}

		

	}

	# 4) Do rearrange rows
	$inCAM->COM( "matrix_auto_rows", "job" => $masterJob, "matrix" => "matrix" );

	return $result;
}

sub EmptyLayers {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};

	my @jobNames = $self->{"poolInfo"}->GetJobNames();
	@jobNames = grep { $_ !~ /^$masterJob$/i } @jobNames;
	@jobNames = ( @jobNames, "o+1" );

	my @baseLayers = CamJob->GetBoardBaseLayers( $inCAM, $masterJob );
	@baseLayers = map { $_->{"gROWname"} } @baseLayers;

	# check only mask and signal layers + layer f
	my @testLayers = grep { $_ =~ /^[m]?[cs]$/i } @baseLayers;
	@testLayers = ( @testLayers, grep { $_ =~ /^v\d+$/i } @baseLayers );
	push( @testLayers, "f" );

	foreach my $stepName (@jobNames) {

		foreach my $l (@testLayers) {
			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $masterJob, $stepName, $l );

			if ( $hist{"total"} == 0 ) {

				$result = 0;
				$$mess .= "Layer \"$l\" in step \"$stepName\" in master job is empty. Is it ok?\n";
			}
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::PoolMerge::MergeGroup::Helper::CopySteps';
	use aliased 'Programs::PoolMerge::Task::TaskData::GroupData';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobName   = "f52456";
	my $stepName  = "panel";
	my $layerName = "c";

	my $group = GroupData->new();

	my @orders = ();

	$group->{"ordersInfo"} = \@orders;

	my $ch = CopySteps->new( $inCAM, $group );

	my $mngr = $ch->CopyStepFinalCheck($jobName);

}

1;

