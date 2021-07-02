#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains calculation about surface area
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamGoldArea;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamCopperArea';
use aliased 'Packages::ProductionPanel::ActiveArea::ActiveArea';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return if all gold fingers exist
# If no layer specified, test both c + s layer if exist
sub GoldFingersExist {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	# specify attribut, which is used for signal area, where is gold platin
	# default attribute: is .gold_plating
	my $goldAtt = shift // ".gold_plating";

	my $result = 0;

	my @layers = ();

	if ( defined $layer ) {
		push( @layers, $layer );
	}
	else {
		push( @layers, "c" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) );
		push( @layers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );
	}


	foreach my $l (@layers) {

		my $infoFile = $inCAM->INFO(
									 units           => 'mm',
									 angle_direction => 'ccw',
									 entity_type     => 'layer',
									 entity_path     => "$jobId/$step/$l",
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

		my @platedFeats = grep { $_ =~ /$goldAtt/ } @feat;
		if ( scalar(@platedFeats) ) {

			$result = 1;
			last;
		}
	}

	return $result;
}

# return area of gold fingers, if exist
# Return hash of two values
# "area" [cm^2]
# "percentage"
sub GetGoldFingerArea {
	my $self        = shift;
	my $cuThickness = shift;    # µm
	my $pcbThick    = shift;    # µm
	my $inCAM       = shift;
	my $jobId       = shift;
	my $stepName    = shift;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my %area = ( "area" => 0, "percentage" => 0, "exist" => 0 );
	my @layers = ();

	push( @layers, "c" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) );
	push( @layers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	@layers = grep { $self->GoldFingersExist( $inCAM, $jobId, $stepName, $_ ) } @layers;

	my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName );

	#Set limits which are exposed (panel is put to bath until 20mm distance of top edge)
 
	my %limBathExposed = CamJob->GetProfileLimits( $inCAM, $jobId, $stepName );
	$limBathExposed{"ymax"} -= ActiveArea->new( $inCAM, $jobId )->BorderT();

	CamHelper->SetStep( $inCAM, $stepName );

	foreach my $l (@layers) {

		#CamHelper->ClearEditor( $inCAM, $jobId );

		my @refLayers = ();

		if ( CamHelper->LayerExists( $inCAM, $jobId, "gold$l" ) ) {

			push( @refLayers, "gold$l" );
		}
		else {
			die "Layer: gold$l, doesn't exist";
		}

		if ( CamHelper->LayerExists( $inCAM, $jobId, "m$l" ) ) {
			push( @refLayers, "m$l" );
		}

		my %areaTmp;

		if ( $l eq "c" ) {
			%areaTmp = CamCopperArea->GetCuAreaMaskByBox(
														  $cuThickness, $pcbThick, $inCAM, $jobId,
														  $stepName, $l, undef, \@refLayers,
														  undef, \%limBathExposed, 0 
			);
		}
		elsif ( $l eq "s" ) {
			%areaTmp = CamCopperArea->GetCuAreaMaskByBox( $cuThickness, $pcbThick, $inCAM, $jobId, $stepName, undef, $l, undef, \@refLayers, \%limBathExposed, 0
														    );
		}

		$area{"area"}       += $areaTmp{"area"};
		$area{"percentage"} += $areaTmp{"percentage"};

	}

	if ( $area{"area"} > 0 ) {
		$area{"exist"} = 1;
	}

	return %area;
}


# Return goldfinger count
# (count is computed from all features, which has .gold_plated attribut)
sub GetGoldFingerCount {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my $count = 0;

	my $infoFile = $inCAM->INFO(
								 units           => 'mm',
								 angle_direction => 'ccw',
								 entity_type     => 'layer',
								 entity_path     => "$jobId/$step/$layer",
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

	my @platedFeats = grep { $_ =~ /\.gold_plating/ } @feat;

	return scalar(@platedFeats);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamGoldArea';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobName = "d025028";

	my $layerNameTop = shift;
	my $layerNameBot = shift;

	my $considerHole = shift;
	my $considerEdge = shift;

	my $mess = "";

	my %area = CamGoldArea->GetGoldFingerArea( 18, 1500, $inCAM, $jobName, "panel" );

	print $area{"area"};

}

1;

