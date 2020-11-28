
#-------------------------------------------------------------------------------------------#
# Description: Find start of rout and add foot down atribut to rout layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::RoutStart::RoutStart;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsRout';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
use aliased 'Packages::Polygon::PointsTransform';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#



sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}  = shift;
	$self->{"jobId"}  = shift;
	$self->{"SRStep"} = shift;

	return $self;
}

sub FindStart {
	my $self      = shift;
	# Packages::Routing::RoutLayer::RoutStart::RoutStart::START_LEFTTOP
	# Packages::Routing::RoutLayer::RoutStart::RoutStart::START_RIGHTTOP
	my $startType = shift; 

	die "Rout start type is not defined" unless ( defined $startType);

	my $resultItem = ItemResult->new("Identify rout start");

	my @errStep = ();
	$resultItem->{"errStartSteps"} = \@errStep;                            # save information, where start was not found

	CamHelper->SetStep( $self->{"inCAM"}, $self->{"SRStep"}->GetStep() );

	foreach my $s ( $self->{"SRStep"}->GetNestedSteps() ) {

		$self->__RemoveFootAttr($s);

		$self->__FindStart( $s, $resultItem );

	}

	return $resultItem;
}

sub __FindStart {
	my $self    = shift;
	my $stepRot = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# reset attribut "rout_on_bridges" to NO, thus pcb is not on bridges

	my $unitRTM = $stepRot->GetUniRTM();

	# 1) Set rout start for outlines (no outline on bridges)
	my @outlines = $unitRTM->GetOutlineChainSeqs();

	foreach my $outline (@outlines) {

		my @features      = $outline->GetFeatures();
		my $startByAtt    = 0;
		my $startByScript = 0;
		my $startEdge     = undef;
		my $footEdge      = undef;

		my $routModify = 0;    # indicate, if rout is modifie during searching start

		# 1) Find start of chain by user foot down attribute
		my $attFootName = undef;
		if ( defined $stepRot->GetAngle() && $stepRot->GetAngle() >= 0 ) {
			$attFootName = "foot_down_" . $stepRot->GetAngle() . "deg";
		}

		if ( defined $attFootName ) {

			my $edge = ( grep { $_->{"att"}->{$attFootName} } @features )[0];

			if ( defined $edge ) {
				$startByAtt = 1;

				$footEdge = $edge;
				$startEdge = $self->__GetStartByFootEdge( $edge, \@features );

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

					print STDERR "\n\n Modifikace " . $stepRot->GetAngle() . "\n\n";

					# Redraw outline chain
					my $draw = RoutDrawing->new( $inCAM, $jobId, $self->{"SRStep"}->GetStep(), $stepRot->GetRoutLayer() );

					my @delete = grep { $_->{"id"} > 0 } @features;

					$draw->DeleteRoute( [ $outline->GetOriFeatures() ] );    # dlete ori features

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
			  . "\", vrstvu: \""
			  . $self->{"SRStep"}->GetSourceLayer() . "\""
			  . " při rotaci dps: \""
			  . $stepRot->GetAngle()
			  . "\" nebyl nalezen vhodný počátek frézy. Urči počátek frézy při otočení dps: \""
			  . $stepRot->GetAngle()
			  . "\" pomocí atributu: \"$attFootName\"";

			my %inf = ( "stepRotation" => $stepRot, "outlineChaibSeq" => $outline );
			push( @{ $resItem->{"errStartSteps"} }, \%inf );

			$resItem->AddError($m);

		}
	}

	# 2) Set rout start for outlines on bridges
	my @outlinesOnBridges = $unitRTM->GetOutlineChainsOnBridges();

	foreach my $outlineChain (@outlinesOnBridges) {

		my @seq = $outlineChain->GetChainSequences();

		# Consider only starting edge of each sequence
		my @candidates = map { ( $_->GetFeatures() )[0] } @seq;
		my $startEdge = undef;

		my @points = ();
		foreach my $e (@candidates) {
			push( @points, { "x" => $e->{"x1"}, "y" => $e->{"y1"} } );
		}

		my %lim = PointsTransform->GetLimByPoints( \@points );

		#Compute nearest distance from ledt-top corner of polygon points from selected features.
		my $min  = undef;
		my $idx  = -1;
		my $dist = 0;

		for ( my $i = 0 ; $i < scalar(@candidates) ; $i++ ) {

			$dist =
			  sqrt( ( $lim{"xMin"} - $candidates[$i]{"x2"} )**2 + ( ( $lim{"yMax"} - $lim{"yMin"} ) - ( $candidates[$i]{"y2"} - $lim{"yMin"} ) )**2 );

			if ( !defined $min || $dist < $min ) {
				$min = $dist;
				$idx = $i;
			}
		}

		# Set start feature
		if ( $idx >= 0 ) {

			my $startFeat = $candidates[$idx];

			# 1)  set rout start attribute
			my $f = FeatureFilter->new( $inCAM, $jobId, $stepRot->GetRoutLayer() );
			my @ids = ( $startFeat->{"id"} );
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
				die "Rout start was not selected for outline rout on bridges\n";
			}
		}
		else {
			die "Rout start was not selected for outline rout on bridges\n";
		}

	}

	# Reload UniRTM for "rotated step" layer, because set route start or rout modification, changed feature ids
	$self->{"SRStep"}->ReloadStepUniRTM($stepRot);

}

sub __RemoveFootAttr {
	my $self    = shift;
	my $stepRot = shift;

	my $inCAM = $self->{"inCAM"};

	CamLayer->WorkLayer( $inCAM, $stepRot->GetRoutLayer() );

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
	my $foot      = shift;
	my @features  = @{ shift(@_) };
	my $startEdge = undef;

	for ( my $i = 0 ; $i < scalar(@features) ; $i++ ) {

		if ( $features[$i] == $foot ) {

			if ( $i + 1 == scalar(@features) ) {
				$startEdge = $features[0];
			}
			else {
				$startEdge = $features[ $i + 1 ];
			}
		}
	}

	return $startEdge;
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

