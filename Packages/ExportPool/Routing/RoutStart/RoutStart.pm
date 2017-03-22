
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::RoutStart::RoutStart;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';

#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';

#use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"stepList"} = shift;

	return $self;
}

sub FindStart {
	my $self = shift;

	my $resultItem = ItemResult->new("Find rout start");

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		foreach my $sRot ( $s->GetStepRotations() ) {

			$self->__FindStart( $sRot, "f", $resultItem );

		}

	}

	return $resultItem;
}

# Check if there is noly bridges rout
# if so, save this information to job attribute "rout_on_bridges"
sub __FindStart {
	my $self    = shift;
	my $stepRot = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# reset attribut "rout_on_bridges" to NO, thus pcb is not on bridges

	my $unitRTM  = $stepRot->GetUniRTM();
	my @outlines = $unitRTM->GetOutlineChains();

	foreach my $outline (@outlines) {

		my @features      = $outline->GetFeatures();
		my $startByAtt    = 0;
		my $startByScript = 0;
		my $startEdge     = undef;

		# 1) Find start of chain by user foot down attribute
		my $attFootName = undef;
		if ( $stepRot->GetAngle() == 0 ) {
			$attFootName = "foot_down_0deg";
		}
		elsif ( $stepRot->GetAngle() == 270 ) {

			$attFootName = "foot_down_270deg";
		}

		if ( defined $attFootName ) {

			my $edge = ( grep { $_{"att"}->{$attFootName} } @features )[0];

			if ( defined $edge ) {
				$startByAtt = 1;
				$startEdge  = $edge;

			}
		}
		
		# 2) Find start of chain by script, if is not already found
		if ( !$startByAtt ) {

			my %modify = RoutStart->RoutNeedModify( \@features );

			my $routModify = 0;

			if ( $modify{"result"} ) {    

				$routModify = 1;
				RoutStart->ProcessModify( \%modify, \@features );
			}

			my %startResult = RoutStart->GetRoutStart( \@features );
			my %footResult  = RoutStart->GetRoutFootDown( \@features );

			if ( $startResult{"result"} ) {

				$startByScript = 1;
				$startEdge     = $startResult{"edge"};

				if ( $routModify || $outline->GetModified() ) {

					# Redraw outline chain
					my $draw = RoutDrawing->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $stepRot->GetRoutLayer() );

					my @delete = grep { $_->{"id"} > 0 } @features;

					$draw->DeleteRoute( \@delete );

					$draw->DrawRoute( \@features, 2000, EnumsRout->Comp_LEFT, $startResult{"edge"} );    # draw new
				}
			}
		}

		# 3) If start found, set it
		if ( $startByAtt || $startByScript ) {

			my $f = FeatureFilter->new( $inCAM, $jobId, $stepRot->GetRoutLayer() );
			my @ids = ( $startEdge->{"id"} );
			$f->AddFeatureIndexes( \@ids );

			if ( $f->Select() ) {

				$inCAM->COM(
							 "chain_set_plunge",
							 "start_of_chain" => "yes",
							 "mode"           => "straight",
							 "apply_to"       => "all",
							 "inl_mode"       => "straight",
							 "layer"          => $stepRot->GetRoutLayer(),
							 "type"           => "open"
				);

			}
			else {
				die "Rout start was not selected\n";
			}

		}
		else {

			my $m =
			    "Pro step: \""
			  . $stepRot->GetStepName()
			  . "\", vrstvu: \"$layer\""
			  . " při rotaci dps: \""
			  . $stepRot->GetAngle()
			  . "\" nebyl nalezen vhodný počátek frézy. Urči počátek frézy při otočení dps: \""
			  . $stepRot->GetAngle()
			  . "\" pomocí atributu: \"$attFootName\"";

			$resItem->AddError($m);

		}
	}
}

sub CreateFsch {
	my $self = shift;

	my $resultItem = ItemResult->new("Create fsch");

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $fschLayer = "fsch";

	if ( CamHelper->LayerExists( $inCAM, $jobId, $fschLayer ) ) {
		$inCAM->COM( 'delete_layer', "layer" => $fschLayer );
	}

	$inCAM->COM( 'create_layer', layer => $fschLayer, context => 'misc', type => 'rout', polarity => 'positive', ins_layer => '' );

	CamHelper->SetStep( $inCAM, $self->{"stepList"}->GetStep() );

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		foreach my $sRot ( $s->GetStepRotations() ) {

			foreach my $sPlc ( $sRot->GetStepPlaces() ) {

				my $lTmp = GeneralHelper->GetGUID();

				CamLayer->WorkLayer( $inCAM, $sRot->GetRoutLayer() );

				$inCAM->COM(
							 "sel_copy_other",
							 "target_layer" => $fschLayer,
							 "invert"       => "no",
							 "dx"           => $sPlc->GetPosX(),
							 "dy"           => $sPlc->GetPosY(),
							 "size"         => "0",
							 "x_anchor"     => "0",
							 "y_anchor"     => "0"
				);
			}

		}
	}

	return $resultItem;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

