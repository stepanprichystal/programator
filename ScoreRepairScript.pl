#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Script correct theses score lines, which are not strictly horizontal or vertical
# Author:SPR
#-------------------------------------------------------------------------------------------#


use strict;
use warnings;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;
 

#local library
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Scoring::Optimalization::Helper';
use aliased 'Packages::Scoring::Optimalization::Enums';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';
use aliased 'Managers::MessageMngr::MessageMngr';
#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

my $inCAM = InCAM->new();

#my $jobName  = "$ENV{JOB}";

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

#test
if (0) {
	my $layer = "score";
	$jobName  = "d152457";
	$stepName = "mpanel";

	$inCAM->COM(
				   "clipb_open_job",
				   job              => "$jobName",
				   update_clipboard => "view_job"
	);
	$inCAM->COM( "open_job", job => "$jobName" );
	$inCAM->COM(
				   "open_entity",
				   job  => "$jobName",
				   type => "step",
				   name => $stepName
	);
	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	$inCAM->COM(
				   "display_layer",
				   name    => $layer,
				   display => "yes",
				   number  => 1
	);
	$inCAM->COM( "work_layer", name => $layer );

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

	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );

	$inCAM->COM(
				   "display_layer",
				   name    => "score",
				   display => "yes",
				   number  => 1
	);
	$inCAM->COM( "work_layer", name => "score" );

	my $pooling       = HegMethods->GetPcbIsPool($jobName);
	my $changesLokal  = 0;
	my $changesGlobal = 0;
	my %errors        = ( "errors" => undef, "warrings" => undef );

	#get features from score layer
	my $scoreFeatures = ScoreFeatures->new();
	$scoreFeatures->Parse( $inCAM, $jobName, $stepName, "score" );
	my @scoreFeatures = $scoreFeatures->GetFeatures();

	my @mess = ();

	unless ( @scoreFeatures || scalar(@scoreFeatures) > 0 ) {
		print STDERR "ScoreOptimalization.pl: Layer score is empty.";
		exit;
	}

	my $dist         = 0;                                                                                  #sit from profile
	my %profileLimts = CamJob->GetProfileLimits( $inCAM, $jobName, $stepName );
	
	my $checkProf    = Helper->CheckProfileDistance( \@scoreFeatures, \%profileLimts, $dist, \%errors );

	my @lines = Helper->GetStraightScore( \@scoreFeatures, \$changesLokal, \%errors );

	if ($changesLokal) {
		$changesGlobal = 1;
		push( @mess, "Nektere lajny ve score byly opraveny (nebyly uplne horizontalni nebo vertikalni). Zkontroluj to!" );
		$changesLokal = 0;
	}

	@scoreFeatures = Helper->RemoveDuplication( \@scoreFeatures, \$changesLokal, \%errors );

	if ($changesLokal) {
		$changesGlobal = 1;
		push( @mess, "Nektere lajny ve score byly opraveny  (duplicitni lajny byly smazany). Zkontroluj to!" );
		$changesLokal = 0;
	}

	#if test on chcek profile distance fail AND ( pcb is POOL OR score line has been alreadz corrected)
	# adapt score line to profile
	if ( $checkProf ne Enums->ScoreLength_OK && ( $pooling || $changesGlobal ) ) {
		$changesGlobal = 1;
		@scoreFeatures = Helper->AdaptScoreToProfile( \@scoreFeatures, \%profileLimts, $dist, \%errors );
	}

	if ($changesGlobal) {

		$inCAM->COM('sel_delete');
		DrawScoreLines( \@scoreFeatures );

		if ( scalar(@mess) > 0 ) {

			my $messMngr =  MessageMngr->new($jobName);
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_INFORMATION, \@mess );

		}
		else {

			#$inCAM->COM ('editor_page_close');
		}
	}
	
	if(defined $errors{"errors"}{"mess"}){
		my $messMngr =  MessageMngr->new($jobName);
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, [$errors{"errors"}{"mess"}] );
		
	}

}

sub DrawScoreLines {

	#my $self     = shift;
	my @features = @{ shift(@_) };
	my $lastIdx;

	for ( my $i = 0 ; $i < scalar(@features) ; $i++ ) {

		if ( $features[$i]{"type"} eq "L" ) {

			$lastIdx = $inCAM->COM(
									  'add_line',
									  attributes => 'no',
									  xs         => $features[$i]{"x1"},
									  ys         => $features[$i]{"y1"},
									  xe         => $features[$i]{"x2"},
									  ye         => $features[$i]{"y2"},
									  "symbol"   => "r400"
			);
		}

		$features[$i]{"id"} = $lastIdx;
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#HOT TO RUN THIS SCRIPT:

#$inCAM->COM('script_run',name=>"ScoreRepairScript.pl",dirmode=>'global',params=>"$jobname $stepname");
