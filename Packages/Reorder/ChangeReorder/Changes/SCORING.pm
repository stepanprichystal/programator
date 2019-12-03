#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ChangeReorder::Changes::SCORING;
use base('Packages::Reorder::ChangeReorder::Changes::ChangeBase');

use Class::Interface;
&implements('Packages::Reorder::ChangeReorder::Changes::IChange');

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Packages::Scoring::ScoreFlatten';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::TifFile::TifScore';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
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

# Delete and add new schema
sub Run {
	my $self = shift;
	my $mess = shift;

	my $inCAM       = $self->{"inCAM"};
	my $jobId       = $self->{"jobId"};
	my $reorderType = $self->{"reorderType"};

	my $result = 1;

	# Check only standard orders
	if ( $reorderType eq Enums->ReorderType_STD ) {

		my $stepName = "mpanel";

		my $sf = ScoreFlatten->new( $inCAM, $jobId, $stepName );

		my @scoreSteps = ();

		# 1) Check if flatten is needed
		if ( $sf->NeedFlatten( \@scoreSteps ) ) {

			# Check if there is jump scoring

			my @scoreStepsJump = ();
			my $jumpScoring    = $sf->JumpScoringExist( \@scoreStepsJump );

			# unless possible jumpscoring, flatten score
			unless ($jumpScoring) {

				$sf->FlattenNestedScore(1);
			}
		}

		# 2) Check if material thickness after scoring is set in TIF file
		if ( CamHelper->LayerExists( $inCAM, $jobId, "score" ) ) {

			my $tifSco = TifScore->new($jobId);

			if ( !$tifSco->TifFileExist() || !defined $tifSco->GetScoreThick() ) {

				# check if exist score file, and get core thick
				my $path = JobHelper->GetJobArchive($jobId);

				my @scoreFilesJum = FileHelper->GetFilesNameByPattern( $path, ".jum" );
				my @scoreFilesCut = FileHelper->GetFilesNameByPattern( $path, ".cut" );    #old format of score file

				my @scoreFiles = ( @scoreFilesJum, @scoreFilesCut );

				my $coreThick = undef;

				if ( scalar(@scoreFiles) > 0 ) {

					my @lines = @{ FileHelper->ReadAsLines( $scoreFiles[0] ) };

					foreach (@lines) {

						if ( $_ =~ /core\s*:\s*(\d+.\d+)/i ) {
							$coreThick = $1;
							last;
						}
					}
				}

				if ( defined $coreThick && $coreThick > 0 ) {

					$tifSco->SetScoreThick($coreThick);
				}
				else {

					$$mess .= "Material thickness after scoring was not found in score program files";
					$result = 0;
				}
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

	use aliased 'Packages::Reorder::ChangeReorder::Changes::SCHEMA' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $check = Change->new( "key", $inCAM, $jobId );

	my $mess = "";
	print "Change result: " . $check->Run( \$mess );
}

1;

