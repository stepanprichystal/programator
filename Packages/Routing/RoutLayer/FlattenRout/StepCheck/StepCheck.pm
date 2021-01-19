
#-------------------------------------------------------------------------------------------#
# Description: Cover checking rout layer during flatenning layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Routing::RoutLayer::FlattenRout::StepCheck::StepCheck;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::Polygon::PointsTransform';
use aliased 'Packages::Polygon::Enums' => "PolyEnums";
use aliased 'Packages::Polygon::Polygon::PolygonPoints';

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

sub OnlyBridges {
	my $self = shift;

	my $resultItem = ItemResult->new("Check rout bridges");

	foreach my $s ( $self->{"SRStep"}->GetNestedSteps() ) {

		$self->__OnlyBridges( $s, "f", $resultItem );
	}

	return $resultItem;
}

sub OutsideChains {
	my $self = shift;

	my $resultItem = ItemResult->new("Check outside rout");

	foreach my $s ( $self->{"SRStep"}->GetNestedSteps() ) {

		$self->__OutsideChains( $s, "f", $resultItem );
	}

	return $resultItem;
}

sub OutlineRoutChecks {
	my $self = shift;

	my $resultItem = ItemResult->new("Check outline rout");

	# 1) Do checks on nested step level

	foreach my $s ( $self->{"SRStep"}->GetNestedSteps() ) {

		$self->__OutlineRoutChecks( $s, "f", $resultItem );
	}

	# 2) Do check on panel step level
	$self->__OutlineTypeCheck( "f", $resultItem );

	return $resultItem;
}

sub OutlineToolIsLast {
	my $self = shift;

	my $resultItem = ItemResult->new("Check tools order");

	foreach my $s ( $self->{"SRStep"}->GetNestedSteps() ) {

		$self->__OutlineToolIsLast( $s, "f", $resultItem );
	}

	return $resultItem;
}

# Check if there is noly bridges rout
# if so, save this information to job attribute "rout_on_bridges"
sub __OnlyBridges {
	my $self       = shift;
	my $nestedStep = shift;
	my $layer      = shift;
	my $resItem    = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	# reset attribut "rout_on_bridges" to NO, thus pcb is not on bridges

	my $unitRTM  = $nestedStep->GetUniRTM();
	my @outlines = $unitRTM->GetOutlineChainSeqs();

	my @chains = $unitRTM->GetChains();
	my @lefts = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } @chains;

	# If not exist outline rout, check if pcb is on bridges
	unless ( scalar(@outlines) ) {

		# no chains at layer
		if ( !$nestedStep->GetUserRoutOnBridges() ) {

			my $m =
			    "Ve stepu: \""
			  . $nestedStep->GetStepName()
			  . "\", ve vrstvě: \"$layer\""
			  . " není ani obrysová vrstva ani můstky s kompenzací left. Pokud je pcb na můstky nastav jim kompenzaci left.";

			$resItem->AddError($m);
		}
	}
}

# Check if there is outline layer, if all other layer (inner, right etc) are in this outline layer
sub __OutsideChains {
	my $self = shift;

	my $nestedStep = shift;
	my $layer      = shift;
	my $resItem    = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $unitRTM = $nestedStep->GetUniRTM();

	my @lefts = $unitRTM->GetOutlineChainSeqs();

	# If exist outline rout, check if other chains are inside
	if ( scalar(@lefts) ) {

		my @seq = $unitRTM->GetChainSequences();

		my %tmp;
		@tmp{ map { $_ } @lefts } = ();

		my @otherLayers = grep { !exists $tmp{$_} } @seq;

		my @notInside = grep { !$_->GetIsInside() } @otherLayers;

		if ( scalar(@notInside) && !$nestedStep->GetUserRoutOnBridges() ) {

			# chain sequences, which are not inside limits
			# Limits are limits of outline sequence resyed by 6mm on all sides
			# (6, because steps on panel has minimal spacing 6 mm)

			for ( my $i = scalar(@notInside) - 1 ; $i >= 0 ; $i-- ) {

				my $outside = $notInside[$i];

				my @outsidePoint = $outside->GetShapePoints();

				foreach my $outline (@lefts) {

					my @points = map { { "x" => $_->[0], "y" => $_->[1] } } $outline->GetShapePoints();
					my %lim = PointsTransform->GetLimByPoints( \@points );
					$lim{"xMin"} -= 6;
					$lim{"xMax"} += 6;
					$lim{"yMin"} -= 6;
					$lim{"yMax"} += 6;
					my @resizedOutline = ();
					push( @resizedOutline, [ $lim{"xMin"}, $lim{"yMin"} ] );
					push( @resizedOutline, [ $lim{"xMin"}, $lim{"yMax"} ] );
					push( @resizedOutline, [ $lim{"xMax"}, $lim{"yMax"} ] );
					push( @resizedOutline, [ $lim{"xMax"}, $lim{"yMin"} ] );

					if ( PolygonPoints->GetPoints2PolygonPosition( \@outsidePoint, \@resizedOutline ) eq PolyEnums->Pos_INSIDE ) {
						splice @notInside, $i, 1;
						last;
					}
				}
			}

			if (@notInside) {
				my @info = map { $_->GetStrInfo() } @notInside;
				my $str = join( "; ", @info );

				my $m =
				    "Ve stepu: \""
				  . $nestedStep->GetStepName()
				  . "\", ve vrstvě: \""
				  . $layer
				  . "\" jsou frézy, které by měly být uvnitř obrysové frézy, ale nejsou ($str).";

				$resItem->AddError($m);
			}

		}
	}

}

# Check when left rout exists
sub __OutlineRoutChecks {
	my $self       = shift;
	my $nestedStep = shift;
	my $layer      = shift;
	my $resItem    = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $unitRTM = $nestedStep->GetUniRTM();

	# 2) Test if outline orut has only one attribute "foot_down_<angle>deg" of specific kind
	my @outlines = $unitRTM->GetOutlineChainSeqs();

	foreach my $oSeq (@outlines) {

		my $m = "";

		my @foot_down_0deg = grep { defined $_->{"att"}->{"foot_down_0deg"} } $oSeq->GetFeatures();

		if ( scalar(@foot_down_0deg) > 1 ) {
			my $m =
			    "Ve stepu: \""
			  . $nestedStep->GetStepName()
			  . "\", ve vrstvě: \"$layer\" je fréza: "
			  . $oSeq->GetStrInfo()
			  . ", která má více attributů \"foot_down_0deg\". Oprav to.\n";

			$resItem->AddError($m);
		}

		my @foot_down_270deg = grep { defined $_->{"att"}->{"foot_down_270deg"} } $oSeq->GetFeatures();

		if ( scalar(@foot_down_270deg) > 1 ) {

			my $m =
			    "Ve stepu: \""
			  . $nestedStep->GetStepName()
			  . "\", ve vrstvě: \"$layer\" je fréza: "
			  . $oSeq->GetStrInfo()
			  . ", která má více atributů \"foot_down_270deg\". Oprav to.\n";

			$resItem->AddError($m);
		}
	}

	# 3) Outline rout. Test if one feature doesn\t have more attributes "foot_down" eg: foot_down_0deg + foot_down_90deg

	foreach my $oSeq (@outlines) {

		foreach my $f ( $oSeq->GetFeatures() ) {

			my @wrongFeats = grep { $_ =~ /foot_down_/i } keys %{ $f->{"att"} };

			if ( scalar(@wrongFeats) > 1 ) {

				my $m =
				    "Ve stepu: \""
				  . $nestedStep->GetStepName()
				  . "\", ve vrstvě: \"$layer\" je \"feature\" ("
				  . $f->{"id"}
				  . "), které má zároveň atribut \"foot_down_0deg\" i \"foot_down_270deg\". Oprav to.\n";

				$resItem->AddError($m);
			}
		}
	}

	# 4) If some chain tool containoutline, all another chain must by outline
	my @chains = $unitRTM->GetChains();

	foreach my $ch (@chains) {

		my @outline = grep { $_->IsOutline() } $ch->GetChainSequences();

		if ( scalar(@outline) && scalar(@outline) != scalar( $ch->GetChainSequences() ) ) {

			my $m =
			    "Ve stepu: \""
			  . $nestedStep->GetStepName()
			  . "\", ve vrstvě: \"$layer\" jsou jedním nástrojem: \""
			  . $ch->GetStrInfo
			  . "\" definovány orbysové i neobrysové frézy dohromady - nelze. "
			  . " Každá obrysová fréza musí mít svůj vlastní \"chain\".\n";

			$resItem->AddError($m);
		}

	}

	# 5) Each outline rout must have own chain tool

	foreach my $ch (@chains) {

		my @outline = grep { $_->IsOutline() } $ch->GetChainSequences();

		if ( scalar(@outline) > 1 ) {

			my $m =
			    "Ve stepu: \""
			  . $nestedStep->GetStepName()
			  . "\", ve vrstvě: \"$layer\" je jedním nástrojem: \""
			  . $ch->GetStrInfo
			  . "\" definováno více obrysových vrstev frézy dohromady - nelze. "
			  . " Každá obrysová fréza musí mít svůj vlastní \"chain\".\n";

			$resItem->AddError($m);
		}

	}

}

# 6) Check if outline routs are all in same type (type = direction + compensation)
# take first outline and comepare to others
sub __OutlineTypeCheck {
	my $self    = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @nestedSteps = $self->{"SRStep"}->GetNestedSteps();

	# Get random step outline rout
	my $typeRandom = undef;
	foreach my $nestedStep ( $self->{"SRStep"}->GetNestedSteps() ) {

		my @outlines = $nestedStep->GetUniRTM()->GetOutlineChainSeqs();

		if (@outlines) {
			$typeRandom = $outlines[0]->GetOutlineType();
			last;
		}
	}

	return 0 if ( !defined $typeRandom );

	my $outlineEq = 1;

	foreach my $nestedStep ( $self->{"SRStep"}->GetNestedSteps() ) {

		foreach my $o ( $nestedStep->GetUniRTM()->GetOutlineChainSeqs() ) {

			my $typeCur = $o->GetOutlineType();

			if ( $typeCur ne $typeRandom ) {
				$outlineEq = 0;
				last;
			}
		}

		last unless ($outlineEq);
	}

	# Form error message if all outline are not same tape
	unless ($outlineEq) {

		my $m =
		    "Všechny obrysové frézy musí být stejného typu."
		  . "Typ obrysové frézy je dán jednoznačne pomocí: směru frézování (CW/CCW) + kompenzace pojezdu(right/left)."
		  . "\nSeznam obrysových fréz:\n";

		my @otput = ();

		foreach my $nestedStep ( $self->{"SRStep"}->GetNestedSteps() ) {

			foreach my $o ( $nestedStep->GetUniRTM()->GetOutlineChainSeqs() ) {

				push(
					  @otput,
					  {
						 "step"     => $nestedStep->GetStepName(),
						 "outlDir"  => $o->GetDirection(),
						 "outlComp" => $o->GetChain()->GetComp(),
						 "chainNum" => $o->GetChain()->GetChainOrder()
					  }
				);
			}
		}

		$m .= join(
			"\n",
			map {
				    "- step:"
				  . $_->{"step"}
				  . "; chain number:"
				  . $_->{"chainNum"}
				  . "; chain direction:"
				  . $_->{"outlDir"}
				  . "; chain compensation:"
				  . $_->{"outlComp"}
			} @otput
		);

		$resItem->AddError($m);
	}
}

# Check if tool sizes are sorted ASC
sub __OutlineToolIsLast {
	my $self       = shift;
	my $nestedStep = shift;
	my $layer      = shift;
	my $resItem    = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $unitRTM = $nestedStep->GetUniRTM();

	my @chains = $unitRTM->GetChains();

	my @outlines = $unitRTM->GetOutlineChainSeqs();

	unless ( scalar(@outlines) ) {
		return 0;
	}

	my $outlineStart = 0;
	foreach my $ch (@chains) {

		foreach my $chSeq ( $ch->GetChainSequences() ) {

			if ( $chSeq->IsOutline() && !$outlineStart ) {

				$outlineStart = 1;
				next;
			}

			# if first outline was passed, all chain after has to be outline
			if ($outlineStart) {
				unless ( $chSeq->IsOutline() ) {
					my $m =
					    "Ve stepu: \""
					  . $nestedStep->GetStepName()
					  . "\", ve vrstvě: \"$layer\" jsou špatně seřazené frézy. Fréza "
					  . $chSeq->GetStrInfo()
					  . " nesmí být za obrysovými frézami. Oprav to.\n";

					$resItem->AddError($m);

				}
			}
		}

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

