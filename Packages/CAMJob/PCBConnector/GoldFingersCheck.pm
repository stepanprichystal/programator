#-------------------------------------------------------------------------------------------#
# Description: GoldFingerChecks check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::PCBConnector::GoldFingersCheck;

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
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamFilter';
use aliased 'CamHelpers::CamStepRepeat';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#
 
# Return if all gold fingers are connected to panel frame pad
sub GoldFingersConnected {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my @layers = @{ shift(@_) };
	my $mess   = shift;

	my $stepName = "panel";
	my $stepGold = "gold_step";

	my @goldLayer = ();
	
	# flatten step, keep only requested signal layer and NC layer - plated, rs, r
	
	my @ncLayers = ();
	push(@ncLayers, CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill ));
	push(@ncLayers, CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bDrillTop ));
	push(@ncLayers, CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_bDrillBot ));
	push(@ncLayers, CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_cDrill ));
	push(@ncLayers, CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nMill ));
	push(@ncLayers, CamDrilling->GetNCLayersByType($inCAM, $jobId, EnumsGeneral->LAYERTYPE_nplt_rsMill ));
	
	@ncLayers = map {$_->{"gROWname"}} @ncLayers;
 
	CamStep->CreateFlattenStep( $inCAM, $jobId, $stepName, $stepGold, 0, [(@layers, @ncLayers)] );
 
	CamHelper->SetStep( $inCAM, $stepGold );
	
	#
	

	foreach my $l (@layers) {

		my $infoFile = $inCAM->INFO(
									 units           => 'mm',
									 angle_direction => 'ccw',
									 entity_type     => 'layer',
									 entity_path     => "$jobId/$stepGold/$l",
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

		# 
		if ( scalar( grep { $_ =~ /\.gold_plating/ } @feat ) ) {

			my $goldHolder = ( grep { $_ =~ /gold-pad/ } @feat )[0];

			unless ( defined $goldHolder ) {
				die "Missing \"gold holder\" in technical frame in step panel.\n";
			}

			my ( $x, $y ) = $goldHolder =~ /#\w\s+(\d+.?\d*)\s+(\d+.?\d*)/g;

			my %inf = ( "layer" => $l, "result" => 1 );

			my $lName = GeneralHelper->GetGUID();

			$inCAM->COM( 'merge_layers', "source_layer" => $l, "dest_layer" => $lName );
			CamLayer->SetLayerTypeLayer( $inCAM, $jobId, $lName, "signal" );
			CamLayer->SetLayerContextLayer( $inCAM, $jobId, $lName, "board" );
			CamLayer->WorkLayer( $inCAM, $lName );

			# do board net selection by "gold holder"
			$inCAM->COM( "sel_board_net_feat", "operation" => "select", "x" => $x, "y" => $y, "tol" => 0, "use_ffilter" => "no" );
			$inCAM->COM("sel_delete");    # delete all selected and check if some gold finger left

			my $infoFile = $inCAM->INFO(
										 units           => 'mm',
										 angle_direction => 'ccw',
										 entity_type     => 'layer',
										 entity_path     => "$jobId/$stepGold/$lName",
										 data_type       => 'FEATURES',
										 parse           => 'no'
			);

			my @featLeft = ();

			if ( open( my $f, "<" . $infoFile ) ) {
				@featLeft = <$f>;
				close($f);
				unlink($infoFile);
			}

			if ( scalar( grep { $_ =~ /\.gold_plating/ } @featLeft ) ) {

				# some gold finger left, thus are not connected
				$inf{"result"} = 0;
			}

			$inCAM->COM( 'delete_layer', "layer" => $lName );
			push( @goldLayer, \%inf );
		}
	}
	
	CamStep->DeleteStep($inCAM, $jobId, $stepGold);

	my $result = 1;
	my @wrongL = map { $_->{"layer"} } grep { $_->{"result"} == 0 } @goldLayer;

	if ( scalar(@wrongL) ) {
		$result = 0;
		$$mess .= "No conduct connection between some gold fingers and \"gold holder\" at layers: \"" . join( "; ", @wrongL ) . "\"";
	}

	return $result;
} 
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAMJob::PCBConnector::GoldFingersCheck';
	use Data::Dump qw(dump);
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $mess = "";
 
	my $result = GoldFingersCheck->GoldFingersConnected( $inCAM, $jobId,  ["c", "s"], \$mess );

	print STDERR "Result is $result \n $mess \n";

	 

}

1;
