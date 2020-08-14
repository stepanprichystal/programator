#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::INCAM_JOB;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;
use Path::Tiny qw(path);
use Log::Log4perl qw(get_logger);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Reorder::Enums';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Delete and add new schema
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	# Check only standard orders

	my $result = 1;

	# Check wrong direction for drill layers exported as Genesis
	my @NCFromBot = CamDrilling->GetNCLayersByTypes(
													 $inCAM, $jobId,
													 [
														EnumsGeneral->LAYERTYPE_plt_bDrillBot,  EnumsGeneral->LAYERTYPE_plt_bFillDrillBot,
														EnumsGeneral->LAYERTYPE_plt_bMillBot,   EnumsGeneral->LAYERTYPE_nplt_bMillBot,
														EnumsGeneral->LAYERTYPE_nplt_cbMillBot, EnumsGeneral->LAYERTYPE_nplt_lsMill
													 ]
	);

	foreach my $NC (@NCFromBot) {
 
		if ( CamMatrix->GetLayerDirection( $inCAM, $jobId, $NC->{"gROWname"} ) ne "bot2top" ) {
			CamMatrix->SetLayerDirection( $inCAM, $jobId, $NC->{"gROWname"}, "bottom_to_top" );
		}
	}

	# 1) check if layer "c" is not missing. (layer has to exist even at noncopper pcb)
	unless ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) ) {

		CamMatrix->CreateLayer( $inCAM, $jobId, "c", "signal", "positive", 1 );
		$inCAM->COM( "matrix_auto_rows", "job" => $jobId, "matrix" => "matrix" );
	}

	# 2) check if layer "f" is not missing. (layer has to exist even at noncopper pcb)
	unless ( CamHelper->LayerExists( $inCAM, $jobId, "f" ) ) {

		CamMatrix->CreateLayer( $inCAM, $jobId, "f", "rout", "positive", 1 );
		$inCAM->COM( "matrix_auto_rows", "job" => $jobId, "matrix" => "matrix" );
	}

	# 3) Check if DTM user columns are up to date in job
	$self->__UpdateDTMColumns();

	# 4) Prevent InCAM Bug prevention (show and hide DTM at drill/rout layer)
	# Sometimes happen, incam return type "hole" instead of "slot" for routs in rout layers
	# Show and Hide DTM is workaround for this wrong behaviour
	my @routs = map { $_->{"gROWname"} } grep { $_->{"gROWlayer_type"} eq "rout" } CamJob->GetNCLayers( $inCAM, $jobId );

	foreach my $l (@routs) {

		CamLayer->WorkLayer( $inCAM, $l );
		$inCAM->COM( "tools_show", "layer" => $l );                                       # show DTM
		$inCAM->COM( "show_component", "component" => "Action_Area", "show" => "no" );    # hide DTM
		CamLayer->ClearLayers($inCAM);

	}

	return $result;

}

# Check if DTM user columns are up to date in job
# If not, update if possible
sub __UpdateDTMColumns {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @curClmns = map { uc($_) } CamDTM->GetDTMUserColNames($inCAM);
	my $clmnStr = join( ";", @curClmns );

	my @NCLayers = map { $_->{"gROWname"} } CamJob->GetNCLayers( $inCAM, $jobId );
	@NCLayers = grep { $_ ne "score" } @NCLayers;

	my @steps = ("o+1");

	if ( CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

		@steps = map { $_->{"stepName"} } CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, "panel" );
	}

	foreach my $step (@steps) {

		foreach my $layer (@NCLayers) {

			my $p = EnumsPaths->InCAM_jobs . $jobId . "\\steps\\$step\\layers\\$layer\\tools";

			if ( -e $p ) {

				my $file = path($p);

				my $data = $file->slurp_utf8;

				my ($clmns) = $data =~ /USER_DES_NAMES=(.*)/i;
				my @clmns = ();
				if ( defined $clmns ) {
					@clmns = map { uc($_) } split( ";", $clmns );
				}

				if ( scalar(@clmns) ) {

					my $updateClms = 0;

					# Obsolete columns
					my @obsolete = ();
					foreach my $clmn (@clmns) {
						push( @obsolete, $clmn ) unless ( grep { $_ eq $clmn } @curClmns );
					}

					# Missing columns
					my @missing = ();
					foreach my $clmn (@curClmns) {
						push( @missing, $clmn ) unless ( grep { $_ eq $clmn } @clmns );
					}

					# if exist any obsolete user DTM column and USER_DES values are not set => update

					if ( scalar(@obsolete) ) {

						$updateClms = 1;

						# check all tool
						my $existValue = 0;
						my @lines = split( "\n", $data );
						foreach my $l (@lines) {

							if ( $l =~ /USER_DES=(.*)/i ) {
								my $vals = $1;
								if ( scalar( grep { $_ ne "" } split( ";", $vals ) ) ) {
									$existValue = 1;
								}
							}
						}

						$updateClms = 0 if ($existValue);

					}
					elsif ( scalar(@missing) && scalar(@obsolete) == 0 ) {

						$updateClms = 1;

						# check if we can add column (only if order of old column not will be changed)
						for ( my $i = 0 ; $i < scalar(@clmns) ; $i++ ) {

							if ( $clmns[$i] ne $curClmns[$i] ) {

								$updateClms = 0;
							}
						}

					}

					# update only if:
					# - no obsolete column exist
					# - if user DTM columns are defined in file
					# - if exist only some current user DTM columns
					if ($updateClms) {

						my $logger = get_logger("testService");

						$logger->debug("Set user DTM columns job:$jobId, old clmns:$clmns, new clmns:$clmnStr");

						# set actual user column
						my $curUserDes = "USER_DES_NAMES=$clmnStr";
						$data =~ s/USER_DES_NAMES=.*/$curUserDes/;
						$file->spew_utf8($data);
					}
				}
			}
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ChangeReorder::Changes::INCAM_JOB' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

