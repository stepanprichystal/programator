#-------------------------------------------------------------------------------------------#
# Description: Silkscreen checks
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::SilkScreen::SilkScreenCheck;

#3th party library
use utf8;
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
# Check if features in silkscreen layer has minimal width 130µm
# Check all silkscreen layers
# Return 0/1
sub FeatsWidthOkAllLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $mess  = shift;    # string reference to error message

	my $result = 1;

	my @lSilk = grep { $_->{"gROWname"} =~ /^p[cs]$/i } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	foreach my $l (@lSilk) {

		my @wrongFeat = ();
		unless ( $self->FeatsWidthOk( $inCAM, $jobId, $step, $l->{"gROWname"}, \@wrongFeat ) ) {

			$result = 0;

			my $str = join( ", ", @wrongFeat );

			$$mess .= "Too thin features ($str) in silkscreen layer \"" . $l->{"gROWname"} . "\". Min thickness of feature is 130µm";
		}
	}
	
	return $result;
}

# Check if features in silkscreen layer has minimal width by layer
sub FeatsWidthOk {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $layer     = shift;
	my $wronFeats = shift;    # array ref, fileld with wrong width of features

	my $result = 1;

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/" . $layer,
								 data_type       => 'FEATURES',
								 options         => 'break_sr+',
								 parse           => 'no'
	);

	my @feat = ();

	if ( open( my $f, "<" . $infoFile ) ) {
		@feat = <$f>;
		close($f);
		unlink($infoFile);
	}

	@feat = grep { $_ =~ /^#[LA]\s*(\d\.?\d*\s*)+[rs](\d+)\.?\d*\sP/i && $2 < 120 } @feat;    # check positive lines+arc thinner tahn 120µm

	if ( scalar(@feat) ) {

		my @thinSyms = uniq( map { ( $_ =~ /^#[LA]\s*(\d\.?\d*\s*)+[rs](\d+)\.?\d*\sP/i )[1] . "µm" } @feat );
		my $str = join( ", ", @thinSyms );

		if ( scalar(@thinSyms) ) {

			push( @{$wronFeats}, @thinSyms );

			$result = 0;

		}
	}

	return $result;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::SilkScreen::SilkScreenCheck';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d210206";

	my $mess = "";
 

	my $result = SilkScreenCheck->FeatsWidthOkAllLayers( $inCAM, $jobId, "o+1",  \$mess );

	print STDERR "Result is: $result, error message: $mess\n";

 

}

1;
