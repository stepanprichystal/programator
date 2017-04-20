
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::PoolMerge::MergeGroup::PanelCreation;
use base("Packages::ItemResult::ItemEventMngr");

#3th party library
use utf8;
use strict;
use warnings;
use DateTime;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::NifFile::NifFile';
use aliased 'CamHelpers::CamHistogram';

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

sub CopySteps {
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

			@wrongPolar = map { $_->{"gROWpolarity"} } @wrongPolar;
			my $lStr = join( "; ", @wrongPolar );

			$copyStepRes->AddError("Pool job can't contain negative signal layers (\"$lStr\"). Child job $jobName");
		}

		# 2) delete step if exist
		if ( CamHelper->StepExists( $inCAM, $masterJob, $jobName ) ) {
			$inCAM->COM( "delete_entity", "job" => $masterJob, "name" => $jobName, "type" => "step" );
		}

		$inCAM->HandleException(1);

		# 3) copy step to master, name of step is jobname
		$inCAM->COM(
					 "copy_entity",
					 "type"           => "step",
					 "source_job"     => "f13608",
					 "source_name"    => "o+1",
					 "dest_job"       => $masterJob,
					 "dest_name"      => $jobName,
					 "dest_database"  => "",
					 "remove_from_sr" => "no"
		);

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
	
	foreach my $stepName (@jobNames){
		
		my $exist = scalar(grep { $_ eq $stepName } @steps);
		unless($exist){
			
			$result = 0;
			$$mess .= "Child step \"o+1\" from job \"$stepName\" was not copied to \"master job\".\n";
		}
	}
}

sub EmptyLayers {
	my $self      = shift;
	my $masterJob = shift;
	my $mess      = shift;

	my $result = 1;
	
	my $inCAM = $self->{"inCAM"};
	
	my @jobNames = $self->{"poolInfo"}->GetJobNames();
	
	my @baseLayers = CamJob->GetBoardBaseLayers( $inCAM, $masterJob );
	@baseLayers = map { $_->{"gROWname"}} @baseLayers;
	
	# check only mask and signal layers + layer f
	my @testLayers = grep { $_ =~ /^[m]?[cs]$/i } @baseLayers;
	@testLayers = (@testLayers, grep { $_ =~ /^v\d+$/i } @baseLayers);
	push(@testLayers, "f");
	
	
	foreach my $stepName (@jobNames){
		
		foreach my $l (@testLayers){
			my %hist = CamHistogram->GetFeatuesHistogram($inCAM, $masterJob, $stepName, $l);
			
			if($hist{"total"} == 0){
				
				$result = 0;
				$$mess .= "Layer \"$l\" in step \"$stepName\" in master job is empty. Is it ok?\n";
			}
	}
}

 
kontrola features za profilem + smaz8n9 jiy vloyenzch cisel
kontrola na vzdálenost kusù?

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::AOIExport::AOIMngr';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobName   = "f13610";
	#	my $stepName  = "panel";
	#	my $layerName = "c";
	#
	#	my $mngr = AOIMngr->new( $inCAM, $jobName, $stepName, $layerName );
	#	$mngr->Run();
}

1;

