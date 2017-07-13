#-------------------------------------------------------------------------------------------#
# Description: Helper methods for pcb marking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Marking::Marking;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return layer name, where dynamic datacode was found
sub GetDatacodeLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my @layers = ();

	my @markLayers = grep { $_->{"gROWname"} =~ /^[pm]?[cs]$/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	foreach my $l (@markLayers) {

		if ( $self->DatacodeExists( $inCAM, $jobId, $step, $l->{"gROWname"} ) ) {
			push( @layers, $l->{"gROWname"} );
		}
	}

	return @layers;
}

# Return if dynamic datacode exist in layer
sub DatacodeExists {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my $exist = 1;

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options        => 'break_sr+',
								 parse           => 'no'
	);
	my @feat = ();

	if ( open( my $f, "<" . $infoFile ) ) {
		@feat = <$f>;
		close($f);
		unlink($infoFile);
	}

	my @texts = map { $_ =~ /'(.*)'/ } grep { $_ =~ /^#T.*'(.*)'/ } @feat;

	my $datacodeOk = scalar(   grep { $_ =~ /(\${2}(dd|ww|mm|yy|yyyy)\s*){1,3}$/i } @texts );

	# Id text daacode doesn't exist, find datacode in sybols
	unless ($datacodeOk) {

		my %hist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $layer );
		my @datacodes = map { $_->{"sym"} } grep { $_->{"sym"} =~ /datacode|data|date|ul|logo/i } @{ $hist{"pads"} };

		@datacodes = uniq(@datacodes);

		if ( scalar(@datacodes) ) {

			my $datacodesOk = 0;
			foreach my $sym (@datacodes) {
				my $f = Features->new();
				$f->ParseSymbol( $inCAM, $jobId, $sym );

				my @test = $f->GetFeatures();

				if ( grep { $_->{"type"} eq "T" && $_->{"text"} =~ /(\${2}(dd|ww|mm|yy|yyyy)\s*){1,3}$/i } $f->GetFeatures() ) {
					$datacodesOk = 1;
					last;
				}
			}
			
			unless($datacodesOk){
				$exist = 0;
			}
			
		}
		else {

			$exist = 0;
		}
	}

	return $exist;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Marking::Marking';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f61718";

	my @layers = Marking->GetDatacodeLayers( $inCAM, $jobId, "panel" );

	print @layers;
}

1;

