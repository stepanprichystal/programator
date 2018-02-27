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
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsPaths';

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

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $isPool = HegMethods->GetPcbIsPool($jobId);

	# Check only standard orders

	my $result = 1;

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

	# check if DTM user columns are up to date in job
	$self->__UpdateDTMColumns();

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

				my $curUserDes = "USER_DES_NAMES=$clmnStr";

				my ($clmns) = $data =~ /USER_DES_NAMES=(.*)/i;

				if ( defined $clmns ) {

					my @clmns = map { uc($_) } split( ";", $clmns );

					# 1) Check if there is not obsolete user column

					my @obsolete = ();
					foreach my $clmn (@clmns) {
						push( @obsolete, $clmn ) unless ( grep { $_ eq $clmn } @curClmns );
					}

					if (@obsolete) {

						die "Job contains obsolete DTM user columns (" . join( ";", @obsolete ) . "), check it";
					}

					# 2) Check if there are all current used colums

					my @missing = ();
					foreach my $clmn (@curClmns) {
						push( @missing, $clmn ) unless ( grep { $_ eq $clmn } @clmns );
					}

					# if no user columsn defined in job, InCAM do update automatically
					if ( @missing && scalar(@clmns) > 0 ) {

						# check if we can add column (only if order of old column not will be changed)
						for ( my $i = 0 ; $i < scalar(@clmns) ; $i++ ) {

							if ( $clmns[$i] ne $curClmns[$i] ) {

								die "Order of job user column (" . $clmns[$i] . ") is different from order of theses columns on server site";
							}
						}
						
						
						my $logger = get_logger("testService");
						
						$logger->debug("Set user DTM columns job:$jobId, old clmns:$clmns, new clmns:$clmnStr");

						# set actual user column
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

