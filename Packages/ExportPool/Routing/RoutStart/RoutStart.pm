
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
use aliased 'CamHelpers::CamAttributes';

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

	# Reload UniRTM for "rotated step" layer, because set route start or rout modification, changed feature ids
	$self->{"stepList"}->ReloadStepRotation($stepRot);

}

sub CreateFsch {
	my $self       = shift;
	my $convTable1 = shift;    # old rout chain order => "fsch" chain order
	my $convTable2 = shift;    # "fsch" chain order =>   "fsch" chain tool guid

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

				#				# Fill conver tables
				#				my %t  = ();
				#				my %t2 = ();
				#				for ( my $i = 0 ; $i < scalar(@oldChains) ; $i++ ) {
				#
				#					$t{ $oldChains[$i]->GetChainOrder() } = $newChains[$i]->GetChainOrder();
				#
				#					# fill conver table. Each item is couple : "new fsch chain order" => chain tool id
				#					$t2{ $t{ $oldChains[$i]->GetChainOrder() } } = $convTmp{ $oldChains[$i]->GetChainOrder()};
				#				}
				#
				#				$convTable1->{ $sPlc->GetStepId() } = \%t;
				#				$convTable2->{ $sPlc->GetStepId() } = \%t2;

			}
		}
	}

	return $resultItem;
}

sub __CopyRoutToFsch {
	my $self      = shift;
	my $sRot      = shift;
	my $sPlc      = shift;
	my $convTable = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $fschLayer = "fsch";


	# 1) Copy prepared rout to fsch

	CamLayer->WorkLayer( $inCAM, $sRot->GetRoutLayer() );

	my %convTmp = ();    # temporary convert table

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

	# 2) Get new rout id

	# Get new chain number and store to conversion table
	my @oldChains = $sRot->GetUniRTM()->GetChainList();

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $fschLayer );

	my @newChains = ( $unitRTM->GetChainList() )[ -scalar(@oldChains) .. -1 ];

	# Set "stepPlace" guid to all rout features to possible identification
	for ( my $i = 0; $i < scalar(@oldChains); $i++ ){

			my $chainId = GeneralHelper->GetGUID();    # Guid, which will be signed all features with sam chain

			my $f = FeatureFilter->new( $inCAM, $jobId, $sRot->GetRoutLayer() );

			my %idVal = ( "min" => $chTool->GetChainOrder(), "max" => $chTool->GetChainOrder() );
			$f->AddIncludeAtt( ".rout_chain", \%idVal );

			if ( $f->Select() ) {

				CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, "feat_group_id", $chainId );
			}
			else {
				die "not chain featuer selected";
			}

			$convTable1->{ $sPlc->GetStepId() }->{ $chTool->GetChainOrder() } = $chainId;

		}

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

