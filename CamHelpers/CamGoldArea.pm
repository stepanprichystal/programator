#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains calculation about surface area
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamGoldArea;

#3th party library
use strict;
use warnings;

#loading of locale modules
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::InCAM::InCAM';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Polygon::Features::Features::Features';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamCopperArea';

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

	my $result = 0;

	my @layers = ();

	if ( defined $layer ) {
		push( @layers, $layer );
	}
	else {
		push( @layers, "c" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) );
		push( @layers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );
	}

	CamHelper->SetStep( $inCAM, $step );

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

		my @platedFeats = grep { $_ =~ /\.gold_plating/ } @feat;
		if ( scalar(@platedFeats) ) {

			$result = 1;
			last;
		}
	}

	return $result;
}

# return area of gold fingers, if exist
# area is in mm^2
sub GetGoldFingerArea {
	my $self        = shift;
	my $cuThickness = shift;
	my $pcbThick    = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $stepName    = shift;

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my %area = ( "area" => 0, "percentage" => 0, "exist" => 0 );
	my @layers = ();

	push( @layers, "c" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "c" ) );
	push( @layers, "s" ) if ( CamHelper->LayerExists( $inCAM, $jobId, "s" ) );

	CamHelper->OpenStep( $inCAM, $jobId, $stepName );

	foreach my $l (@layers) {

		CamHelper->ClearEditor( $inCAM, $jobId );

		$inCAM->COM( 'flatten_layer', source_layer => $l, target_layer => $l . "__gold__" );
		$inCAM->COM( 'affected_layer', name => $l . "__gold__", mode => "single", affected => "yes" );
		$inCAM->COM( 'filter_reset', filter_name => "popup" );
		$inCAM->COM( 'filter_atr_set', filter_name => 'popup', condition => 'yes', attribute => '.gold_plating' );
		$inCAM->COM('filter_area_strt');
		$inCAM->COM(
					 'filter_area_end',
					 layer          => '',
					 filter_name    => 'popup',
					 operation      => 'select',
					 area_type      => 'none',
					 inside_area    => 'no',
					 intersect_area => 'yes',
					 lines_only     => 'no',
					 ovals_only     => 'no',
					 min_len        => 0,
					 max_len        => 0,
					 min_angle      => 0,
					 max_angle      => 0
		);

		$inCAM->COM('get_select_count');

		if ( $inCAM->GetReply() > 0 ) {
			$inCAM->COM('sel_reverse');
			$inCAM->COM('sel_delete');

			my %areaTmp;

			if ( $l eq "c" ) {
				%areaTmp =
				  CamCopperArea->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, $stepName, $l . "__gold__", undef, "m" . $l, undef );
			}
			elsif ( $l eq "s" ) {
				%areaTmp =
				  CamCopperArea->GetCuAreaMask( $cuThickness, $pcbThick, $inCAM, $jobId, $stepName, undef, $l . "__gold__", undef, "m" . $l );
			}

			$area{"area"}       += $areaTmp{"area"};
			$area{"percentage"} += $areaTmp{"percentage"};

		}
		$inCAM->COM( 'affected_layer', name => $l . "__gold__", mode => "single", affected => "no" );
		$inCAM->COM( 'delete_layer', layer => $l . "__gold__" );
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

	my $jobName = "f13610";

	my $layerNameTop = shift;
	my $layerNameBot = shift;

	my $considerHole = shift;
	my $considerEdge = shift;

	my $mess = "";

	my $result = CamGoldArea->GetGoldFingerCount( $inCAM, $jobName, "panel", "s" );

	print $result. " - $mess";

}

1;

