#-------------------------------------------------------------------------------------------#
# Description: Helper methods for UL logo marking
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Marking::MarkingULLogo;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::Polygon::Features::Features::Features';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return layer name, where dynamic datacode was found
sub GetULLogoLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;

	my @layers = ();

	# search in pc2/pc/mc/c/s/ms/ps/ps2
	my @markLayers = grep { $_->{"gROWname"} =~ /^[pm]?[cs]2?$/ } CamJob->GetBoardBaseLayers( $inCAM, $jobId );

	foreach my $l (@markLayers) {

		if ( $self->ULLogoExists( $inCAM, $jobId, $step, $l->{"gROWname"} ) ) {
			push( @layers, $l->{"gROWname"} );
		}
	}

	return @layers;
}

# Return if dynamic datacode exist in layer
# Note.: Work with S&R
sub ULLogoExists {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my $exist = 0;

	# all symbols which contain: ul_ are UL logo

	my %hist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $layer );
	my @logoSym = map { $_->{"sym"} } grep { $_->{"sym"} =~ /ul_/i } @{ $hist{"pads"} };

	@logoSym = uniq(@logoSym);

	$exist = 1 if ( scalar(@logoSym) );

	return $exist;
}

# Return ifnfo about UL logo
# Return array of hashes
# Hash: source=> feat/symbol, name => features name  , mirror => 1/0, wrongMirror => 1/0
# Note: Do not work with S&R
sub GetULLogoInfo {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my @ULLogos = ();

	my $exist = 1;

	# 1) Get  datacodes inserted as text features
	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
								 data_type       => 'FEATURES',
								 options         => 'feat_index+f0+',
								 parse           => 'no'
	);
	my @feat = ();

	if ( open( my $f, "<" . $infoFile ) ) {
		@feat = <$f>;
		close($f);
		unlink($infoFile);
	}

	# 2) Get  datacodes inserted as symbols
	my @ulSyms = grep { $_ =~ /^#(\d*)\s*#P.*(ul_)/i } @feat;
	my @symId  = map  { $_ =~ /^#(\d*)/i } @ulSyms;

	if ( scalar(@ulSyms) ) {

		my @ulDef = map { ( $_ =~ /^#(\d*)\s*#P.*\s(.*(ul_).*)\s[pn]\s\d.*/i )[1] } @ulSyms;
		my %ulDef = map { $_ => {} } @ulDef;

		# Parse only lmited amount of features - UL logo features features
		my $fSym = Features->new();
		$fSym->Parse( $inCAM, $jobId, $step, $layer, 0, 0, \@symId );

		foreach my $f ( $fSym->GetFeatures() ) {

			# add datacode only if parsed symbol is real datacode - contain text with datacode

			my $typ = undef;    # single layer or multi layer logo

			if ( $f->{"symbol"} =~ /ML1/i ) {
				$typ = "ml";
			}
			elsif ( $f->{"symbol"} =~ /SL1/i ) {
				$typ = "sl";
			}

			my %inf = ( "source" => "symbol", "name" => $f->{"symbol"}, "mirror" => $f->{"mirror"} =~ /y/i ? 1 : 0, "typ" => $typ );

			push( @ULLogos, \%inf );

		}

		# check if mirror is ok
		my $mirror = 0;
		if ( $layer =~ /^[mp]?s/ ) {
			$mirror = 1;
		}

		foreach my $d (@ULLogos) {

			if ( $d->{"mirror"} != $mirror ) {
				$d->{"wrongMirror"} = 1;
			}
			else {
				$d->{"wrongMirror"} = 0;
			}
		}

		@ULLogos = uniq(@ULLogos);

	}

	return @ULLogos;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::Marking::MarkingULLogo';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d274844";

	my @exist = MarkingULLogo->GetULLogoInfo( $inCAM, $jobId, "panel", "c" );

	#my @exist2 = MarkingULLogo->GetULLogoInfo( $inCAM, $jobId, "panel", "mc" );

	die;

}

1;

