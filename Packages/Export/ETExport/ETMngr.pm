
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for ipc file creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::ETExport::ETMngr;
use base('Packages::ItemResult::ItemEventMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::ETesting::BasicHelper::OptSet';
use aliased 'Packages::ETesting::BasicHelper::ETSet';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"stepToTest"} = shift;    #step, which will be tested

	return $self;
}

sub Run {
	my $self = shift;

	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $etStepName = $self->__CreateEtStep();
	
	#open et step
	$inCAM->COM("set_step", "name"=> $etStepName);
	$inCAM->COM( 'open_entity', job => $jobId, type => 'step', name => $etStepName, iconic => 'no' );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );
	

	#remove step named "coupon" if exist
	my $couponExist = CamStepRepeat->ExistStepAndRepeat( $inCAM, $jobId, $etStepName, "coupon" );

	if ($couponExist) {
		CamStepRepeat->DeleteStepAndRepeat( $inCAM, $jobId, $etStepName, "coupon" );
	}

	#check if SR exists in etStep, if so, flattern whole step
	my $srExist = CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $etStepName );

	if ($srExist) {
		$self->__FlatternETStep($etStepName);
	}

	#change profile according fr layer, if multilayer
	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	if ( $layerCnt > 2 ) {
		$self->__EditProfileByFr($etStepName);

	}

	$self->__CreateIpc($etStepName);
}

# create special step, which IPC will be exported from
sub __CreateEtStep {
	my $self = shift;

	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};
	my $stepToTest = $self->{"stepToTest"};

	my $stepEt = "et_" . $stepToTest;
	#CamHelper->OpenJob( $inCAM, $jobId );

	$inCAM->COM( 'open_entity', job => $jobId, type => 'step', name => $stepToTest, iconic => 'no' );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	#delete if step already exist
	if ( CamHelper->StepExists( $inCAM, $jobId, $stepEt ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $stepEt, "type" => "step" );
	}

	 
	$inCAM->COM(
				 'copy_entity',
				 type             => 'step',
				 source_job       => $jobId,
				 source_name      => $stepToTest,
				 dest_job         => $jobId,
				 dest_name        => $stepEt,
				 dest_database    => "",
				 "remove_from_sr" => "yes"
	);
	

	
 
 

	return $stepEt;
}

# Flattern all layers in et step. Thus, et step doesn't contain
# any step and repeat. Reason is, InCAM can't export more then one of type SR pcb correctly
sub __FlatternETStep {
	my $self   = shift;
	my $etStep = shift;
	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};

	$inCAM->COM( 'open_entity', job => $jobId, type => 'step', name => $etStep, iconic => 'no' );
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );
	$inCAM->COM( 'units', type => 'mm' );
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "yes" );

	my $frExist = CamHelper->LayerExists( $inCAM, $jobId, "fr" );

	if ($frExist) {
		$inCAM->COM( 'affected_layer', name => 'fr', mode => 'single', affected => 'no' );
	}
	$inCAM->COM('sel_delete');
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );

	$self->__ResulETStepCreated();

	my @allLayers = CamJob->GetBoardLayers( $inCAM, $jobId );

	@allLayers = grep {
		     $_->{"gROWlayer_type"} eq "signal"
		  || $_->{"gROWlayer_type"} eq "mixed"
		  || $_->{"gROWlayer_type"} eq "power_ground"
		  || $_->{"gROWlayer_type"} eq "solder_mask"
		  || $_->{"gROWlayer_type"} eq "rout"
		  || $_->{"gROWlayer_type"} eq "drill"
	} @allLayers;

	foreach my $l (@allLayers) {

		CamLayer->FlatternLayer( $inCAM, $jobId, $etStep, $l->{"gROWname"} );
	}

	#$inCAM->COM( 'sr_active', top => '0', bottom => '0', left => '0', right => '0' );
 
	$inCAM->COM( "set_step", "name" => $etStep );
	
	$inCAM->COM( 'sredit_sel_all');
	$inCAM->COM( 'sredit_del_steps');
	
 
	
 
	#delete SMD attributes
	
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "yes" );
	$inCAM->COM("sel_all_feat");
	$inCAM->COM("sel_delete_atr","mode" => "list","attributes" => ".smd");
	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );
	$inCAM->COM("clear_highlight");


}

# If pcb is multilayer, create profile by fr
sub __EditProfileByFr {
	my $self   = shift;
	my $etStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $frFeatures = Features->new();
	$frFeatures->Parse($inCAM, $jobId, $etStep, "fr");
	
	my @frLines = $frFeatures->GetFeatures();



	#draw profile by points form fr layer
	$inCAM->COM( "profile_poly_strt", "x" => $frLines[0]->{"x1"}, "y" => $frLines[0]->{"y1"} );
	$inCAM->COM( "profile_poly_seg",  "x" => $frLines[1]->{"x1"}, "y" => $frLines[1]->{"y1"} );
	$inCAM->COM( "profile_poly_seg",  "x" => $frLines[2]->{"x1"}, "y" => $frLines[2]->{"y1"} );
	$inCAM->COM( "profile_poly_seg",  "x" => $frLines[3]->{"x1"}, "y" => $frLines[3]->{"y1"} );
	$inCAM->COM( "profile_poly_seg",  "x" => $frLines[0]->{"x1"}, "y" => $frLines[0]->{"y1"} );
	$inCAM->COM("profile_poly_end");
	
	#set datum point and origin to minimal coordinate
	
	my $xMin;
	my $yMin;	
	
	foreach my $points (@frLines){
		
		if(!defined $xMin || $points->{"x1"} < $xMin){
			$xMin = $points->{"x1"};
		}
		
		if(!defined $yMin || $points->{"y1"} < $yMin){
			$yMin = $points->{"y1"};
		}
		
	}
	
	$inCAM->COM( "datum", "x" => $xMin, "y" => $yMin );
	$inCAM->COM( "origin", "push_in_stack" => 0, "x" => $xMin, "y" => $yMin );
	
	

}

# Do optimization fot IPC
# Create electrical test
# Export it
# Function watch all InCAM error what happen in this function
sub __CreateIpc {
	my $self   = shift;
	my $etStep = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $stepName     = "panel";
	my $setupOptName = "atg_flying";    #default setting saved in incam library
	my @steps        = ($etStep);

	# stat of handle inCAm exceptionS
	$inCAM->HandleException(1);

	# Raise result item for optimization set
	my $resultItemOpSet = $self->_GetNewItem("Optimization");

	my $optName;
	my $resultOpSet = OptSet->OptSetCreate( $inCAM, $jobId, $etStep, $setupOptName, \@steps, \$optName );

	unless ($resultOpSet) {
		$resultItemOpSet->AddError( $inCAM->GetExceptionError() );
	}

	$self->__ResulETOptimize($resultItemOpSet);

	# Raise result item for et set creation
	my $resultItemEtSet = $self->_GetNewItem("Set creation");

	my $etsetName;
	my $resultEtSet = ETSet->ETSetCreate( $inCAM, $jobId, $etStep, $optName, \$etsetName );

	unless ($resultEtSet) {
		$resultItemEtSet->AddError( $inCAM->GetExceptionError() );
	}

	$resultEtSet = ETSet->ETSetOutput( $inCAM, $jobId, $etStep, $optName, $etsetName );

	unless ($resultEtSet) {
		$resultItemEtSet->AddError( $inCAM->GetExceptionError() );
	}

	$self->__ResulETSet($resultItemEtSet);

	# end of handle inCAm exception
	$inCAM->HandleException(0);

	if ( ETSet->ETSetExist( $inCAM, $jobId, $etStep, $optName, $etsetName ) ) {
		ETSet->ETSetDelete( $inCAM, $jobId, $etStep, $optName, $etsetName );
	}

	if ( OptSet->OptSetExist( $inCAM, $jobId, $etStep, $optName ) ) {
		OptSet->OptSetDelete( $inCAM, $jobId, $etStep, $optName );
	}

}

sub __ResulETStepCreated {
	my $self = shift;

	my $resultItem = $self->_GetNewItem("Create ET step");
	$self->_OnItemResult($resultItem);
}

sub __ResulETSet {
	my $self       = shift;
	my $resultItem = shift;

	$self->_OnItemResult($resultItem);
}

sub __ResulETOptimize {
	my $self       = shift;
	my $resultItem = shift;

	$self->_OnItemResult($resultItem);
}


sub ExportItemsCount{
	my $self = shift;
	
	my $totalCnt = 0;
	
	
	$totalCnt += 1; # EtStep Created
	$totalCnt += 1; # Et set createed
	$totalCnt += 1; # Et optimize
	 
	
	return $totalCnt;
	
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

