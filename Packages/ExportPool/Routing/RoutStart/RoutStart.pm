
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

use aliased 'Enums::EnumsRout';
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
	
	my @errStep = (); 
	$resultItem->{"errStartSteps"} = \@errStep; # save stepPlace, where start was not found

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		foreach my $sRot ( $s->GetStepRotations() ) {


			$self->__RemoveFootAttr($sRot);
			
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
		my $footEdge      = undef;
		
		my $routModify = 0; # indicate, if rout is modifie during searching start

		# 1) Find start of chain by user foot down attribute
		my $attFootName = undef;
		if ( defined $stepRot->GetAngle() && $stepRot->GetAngle() >= 0 ) {
			$attFootName = "foot_down_".$stepRot->GetAngle()."deg";
		}
		 
		if ( defined $attFootName ) {

			my $edge = ( grep { $_->{"att"}->{$attFootName} } @features )[0];

			if ( defined $edge ) {
				$startByAtt = 1;
				
				$footEdge   = $edge;
				$startEdge  = $self->__GetStartByFootEdge( $edge, \@features );

			}
		}

		# 2) Find start of chain by script, if is not already found
		if ( !$startByAtt ) {

			my %modify = RoutStart->RoutNeedModify( \@features );
 

			if ( $modify{"result"} ) {

				$routModify = 1;
				RoutStart->ProcessModify( \%modify, \@features );
			}

			my %startResult = RoutStart->GetRoutStart( \@features );
			my %footResult  = RoutStart->GetRoutFootDown( \@features );

			if ( $startResult{"result"} ) {

				$startByScript = 1;

				if ( $routModify || $outline->GetModified() ) {

					# Redraw outline chain
					my $draw = RoutDrawing->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $stepRot->GetRoutLayer() );

					my @delete = grep { $_->{"id"} > 0 } @features;

					$draw->DeleteRoute( \@delete );

					$draw->DrawRoute( \@features, 2000, EnumsRout->Comp_LEFT, $startResult{"edge"}, 1 );    # draw new

				}
				else {

					$startEdge = $startResult{"edge"};
					$footEdge = $self->__GetFootEdgeByStart( $startResult{"edge"}, \@features );
				}
			}
		}

		# 3) If start found, set it
		if ( $startByAtt || $startByScript ) {

			# Set rout start + foot down attribute, if is no already set
			if ( !( $routModify || $outline->GetModified() ) ) {

				# 1)  set rout start attribute
				my $f = FeatureFilter->new( $inCAM, $jobId, $stepRot->GetRoutLayer() );
				my @ids = ( $footEdge->{"id"} );
				$f->AddFeatureIndexes( \@ids );

				if ( $f->Select() ) {

					CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, ".foot_down" );

				}
				else {
					die "Foot down feature was not selected\n";
				}

				# 2) set rout start attribute

				$f->Reset();
				my @ids2 = ( $startEdge->{"id"} );
				$f->AddFeatureIndexes( \@ids2 );

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
			  
			  
			  
			my %inf = ("stepRotation" => $stepRot, "outlineChaibSeq" => $outline) ;
			push(@{$resItem->{"errStartSteps"}}, \%inf);

			$resItem->AddError($m);

		}
	}

	# Reload UniRTM for "rotated step" layer, because set route start or rout modification, changed feature ids
	$self->{"stepList"}->ReloadStepRotation($stepRot);

}



sub CreateFsch {
	my $self      = shift;
	my $convTable = shift;    # old rout chain order => "fsch" chain order

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

				$self->__CopyRoutToFsch( $sRot, $sPlc, $convTable );

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



sub __RemoveFootAttr {
	my $self    = shift;
	my $stepRot = shift;
	
	 my $inCAM = $self->{"inCAM"};
	 
	CamLayer->WorkLayer($inCAM, $stepRot->GetRoutLayer()); 
	
	CamAttributes->DelFeatuesAttribute( $inCAM, ".foot_down", "" );
}


sub __GetFootEdgeByStart {
	my $self      = shift;
	my $startEdge = shift;
	my @features  = @{ shift(@_) };
	my $foot      = undef;

	for ( my $i = 0 ; $i < scalar(@features) ; $i++ ) {

		if ( $features[$i] == $startEdge ) {

			if ( $i == 0 ) {
				$foot = $features[ scalar(@features) - 1 ];
			}
			else {
				$foot = $features[ $i - 1 ];
			}
		}
	}

	return $foot;
}

sub __GetStartByFootEdge {
	my $self      = shift;
	my $foot = shift;
	my @features  = @{ shift(@_) };
	my $startEdge      = undef;

	for ( my $i = 0 ; $i < scalar(@features) ; $i++ ) {

		if ( $features[$i] == $foot ) {

			if ( $i +1 == scalar(@features)) {
				$startEdge = $features[ 0 ];
			}
			else {
				$startEdge = $features[ $i + 1 ];
			}
		}
	}

	return $startEdge;
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

	# 2) Get new chain ids

	# Get new chain number and store to conversion table
	my @oldChains = $sRot->GetUniRTM()->GetChainList();

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $self->{"stepList"}->GetStep(), $fschLayer );

	my @newChains = ( $unitRTM->GetChainList() )[ -scalar(@oldChains) .. -1 ];

	# 3) Generate guid for each new chain and set this guid to all chain features in fsch
	for ( my $i = 0 ; $i < scalar(@oldChains) ; $i++ ) {

		my $oldChain = $oldChains[$i];
		my $newChain = $newChains[$i];

		my $chainId = GeneralHelper->GetGUID();    # Guid, which will be signed all features with sam chain

		my $f = FeatureFilter->new( $inCAM, $jobId, $fschLayer );

		my %idVal = ( "min" => $newChain->GetChainOrder(), "max" => $newChain->GetChainOrder() );
		$f->AddIncludeAtt( ".rout_chain", \%idVal );

		# Test if count of selected features in fsch is ok
		my $featCnt = scalar( $sRot->GetUniRTM()->GetChainByChainTool($oldChain)->GetFeatures() );

		if ( $f->Select() == $featCnt ) {

			CamAttributes->SetFeaturesAttribute( $inCAM, $jobId, "feat_group_id", $chainId );
		}
		else {
			die "not chain featuer selected";
		}

		$convTable->{ $sPlc->GetStepId() }->{ $oldChain->GetChainOrder() } = $chainId;
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

