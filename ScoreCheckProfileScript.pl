#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Script correct check if score line are inside profile or are far distant
# by particular distance e.g.4mm
# Author:SPR
#-------------------------------------------------------------------------------------------#
 

#3th party library
use strict;
use warnings;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
 
 
#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::InCAM::InCAM';
use aliased 'Packages::Scoring::Optimalization::Helper';
use aliased 'Packages::Scoring::Optimalization::Enums';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Managers::MessageMngr::MessageMngr';
#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $inCAM = InCAM->new();



my $jobName  = undef;
my $stepName = undef;

unless ( $ENV{JOB} ) {
	$jobName  = shift;
	$stepName = shift;
}
else {
	$jobName  = "$ENV{JOB}";
	$stepName = "$ENV{STEP}";
}

unless ($jobName) {
	print STDERR "Job name is not defined";
	exit;
}
unless ($stepName) {
	print STDERR "Step name is not defined";
	exit;
}

$inCAM->INFO(
	entity_type => 'layer',
	entity_path => "$jobName/$stepName/score",
	data_type   => 'exists'
);


if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {

	$inCAM->COM(
		"open_entity",
		job  => "$jobName",
		type => "step",
		name => $stepName
	);
	$inCAM->COM(
		"display_layer",
		name    => "score",
		display => "yes",
		number  => 1
	);
	$inCAM->COM( "work_layer", name => "score" );

 

	my $changesLokal  = 0;
	my %errors        = ( "errors" => undef, "warrings" => undef );
	
	#get features from score layer
	my $scoreFeatures = ScoreFeatures->new();
	$scoreFeatures->Parse($inCAM, $jobName, $stepName, "score");
	my @scoreFeatures = $scoreFeatures->GetFeatures();
	
	#my @scoreFeatures = ScoreOptimalizationHelper->GetFeatures($fFeatures);
	my @mess          = ();

	unless ( @scoreFeatures || scalar(@scoreFeatures) > 0 ) {
		print STDERR "Score Layer score is empty.";
		exit;
	}

	my %profileLimts = CamJob->GetProfileLimits( $inCAM, $jobName, $stepName );

	my $dist = 0;             #sit from profile

	my $scoreLen = Helper->CheckProfileDistance( \@scoreFeatures, \%profileLimts, $dist, \%errors );
	if ($scoreLen ne Enums->ScoreLength_OK)
	{
		
		my $messMngr = MessageMngr->new($jobName);
		push (@mess, "Delka drazky je spatna: \"$scoreLen\", oprav pokud je to potreba.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );
		
	}else
	{
		$inCAM->COM ('editor_page_close');
	}

}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#HOT TO RUN THIS SCRIPT:

#$inCAM->COM('script_run',name=>"ScoreRepairScript.pl",dirmode=>'global',params=>"$jobname $stepname");
