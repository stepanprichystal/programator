#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::INCAM_JOB;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;
use Path::Tiny qw(path);
use Log::Log4perl qw(get_logger);

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::Reorder::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if exist new version of nif, if so it means it is from InCAM
sub Run {
	my $self = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	# 1) Check if pcb is former pool
	if ( $reorderType eq Enums->ReorderType_STDFORMERPOOL ) {

		$self->_AddChange( "Pcb is former POOL, now it is standard. Prepare step \"panel\"", 1 );
	}

	# 2) Check if DTM user columns are up to date in job
	$self->__CheckDTMColumns();

}

# Check if DTM user columns are up to date in job
# If not, update if possible
sub __CheckDTMColumns {
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

					# if exist only one user clmn and no TOOL has defined obsolete column value => ignore

					if ( scalar(@obsolete) ) {

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

						my $e = "Job contains obsolete DTM user columns: \"" . join( ";", @obsolete ) . "\".\n";
						$e .=
						  " - See job file: \"$p, \" see row: USER_DES_NAMES (column names) and USER_DES (column values) in each tool definition\n";
						$e .=
						    " - If it is possible, close job, remove/edit column name \""
						  . join( ";", @obsolete )
						  . "\", remove column values and open job again";

						$self->_AddChange( $e, 1 );

					}
					elsif ( scalar(@missing) ) {

						my $e = "Job has missing DTM user columns: \"" . join( ";", @missing ) . "\".\n";
						$e .=
						  " - See job file: \"$p, \" see row: USER_DES_NAMES (column names) and USER_DES (column values) in each tool definition\n";
						$e .=
						    " - If it is possible, close job, add/edit column name \""
						  . join( ";", @missing )
						  . "\", add/edit column values and open job again";
						$e .= " - Actual DTM column names and order is: USER_DES_NAMES=$clmnStr";

						$self->_AddChange( $e, 1 );

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

	use aliased 'Packages::Reorder::CheckReorder::Checks::INCAM_JOB' => "Check";
	use aliased 'Packages::InCAM::InCAM';

	use Data::Dump qw(dump);

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $check = Check->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );

	dump( $check->GetChanges() );
}

1;

