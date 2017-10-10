#-------------------------------------------------------------------------------------------#
# Description: Responsible for preparing job board layers for output.
 
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Panelization::SRStep;

#3th party library
use strict;
use warnings;

#local library

use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"} = shift;

	return $self;
}

# Create image preview
sub Create {
	my $self       = shift;
	
	my $stepWidth  = shift;    # request on onlyu some layers
	my $stepHeight = shift;    # request on onlyu some layers
	my $margTop    = shift;
	my $margBot    = shift;
	my $margLeft   = shift;
	my $margRight  = shift;
	my $profPos    = shift; 	# position of left bottom profile corner
	
	# Set default position of left bottom corner of profile
	unless(defined $profPos){
		
		my %zero = ("x"=> 0, "y" => 0);
		$profPos = \%zero; # profile_rect
	}


	
	my $stepName = $self->{"step"};

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	if ( CamHelper->StepExists( $inCAM, $jobId, $stepName ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $stepName, "type" => "step" );
	}

	$inCAM->COM(  'create_entity',
				 "job"     => $jobId,
				 "name"    => $stepName,
				 "db"      => "",
				 "is_fw"   => 'no',
				 "type"    => 'step',
				 "fw_type" => 'form'
	);

	CamHelper->SetStep( $inCAM, $stepName );
	
	
	my %lb = ("x" => $profPos->{"x"}, "y" => $profPos->{"y"});
	my %rb = ("x" => $stepWidth, "y" => $stepHeight);
	
	CamStep->CreateProfileRect($inCAM, $jobId, $stepName, \%lb);
 
	$inCAM->COM(
		'sr_active',
		"top"    => $margTop,
		"bottom" => $margBot,
		"left"   => $margLeft,
		"right"  => $margRight
	);
 
}

 
	
sub AddSRStep {
	my $self     = shift;
	my $srName   = shift;
	my $posX = shift;
	my $posY = shift;
	my $angle = shift;
	my $nx = shift;
	my $ny = shift;
	my $dx = shift;
	my $dy = shift;
	
	my $inCAM = $self->{"inCAM"};
	
 	CamStepRepeat->AddStepAndRepeat($inCAM, $self->{"step"}, $srName, $posX, $posY, $angle, $nx, $ny, $dx, $dy);
}

sub AddSchema{
	my $self     = shift;
	my $schema   = shift;
	
	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $stepName = $self->{"step"};
	
	my @steps = CamStepRepeat->GetUniqueStepAndRepeat($inCAM, $jobId, $stepName);
	
	$inCAM->COM ('autopan_run_scheme',"job"=>$jobId, "panel"=> $stepName,"pcb"=>$steps[0]->{"stepName"},"scheme"=>$schema);
}
 
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Packages::CAMJob::OutputData::OutputData';
#
#	use aliased 'Packages::InCAM::InCAM';
#
#	my $inCAM = InCAM->new();
#
#	my $jobId = "f52456";
#
#	my $mess = "";
#
#	my $control = OutputData->new( $inCAM, $jobId, "o+1" );
#	$control->Create( \$mess );

}

1;

