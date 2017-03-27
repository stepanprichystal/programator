
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ExportPool::Routing::StepCheck::StepCheck;

#3th party library
use utf8;
use strict;
use warnings;

#local library
#use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';

#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Helpers::FileHelper';
#use aliased 'CamHelpers::CamHelper';
#use aliased 'Packages::Gerbers::Export::ExportLayers' => 'Helper';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';

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

sub OnlyBridges {
	my $self = shift;

	my $resultItem = ItemResult->new("Rout bridges");

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		$self->__OnlyBridges( $s, "f", $resultItem );
	}

	return $resultItem;
}

sub OutsideChains {
	my $self = shift;

	my $resultItem = ItemResult->new("Outside rout");

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		$self->__OutsideChains( $s, "f", $resultItem );
	}

	return $resultItem;
}

sub LeftRoutChecks {
	my $self = shift;

	my $resultItem = ItemResult->new("Left comp. rout");

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		$self->__LeftRoutChecks( $s, "f", $resultItem );
	}

	return $resultItem;
}

sub OutlineToolIsLast {
	my $self = shift;

	my $resultItem = ItemResult->new("Tools order");

	foreach my $s ( $self->{"stepList"}->GetSteps() ) {

		$self->__OutlineToolIsLast( $s, "f", $resultItem );
	}

	return $resultItem;
}

# Check if there is noly bridges rout
# if so, save this information to job attribute "rout_on_bridges"
sub __OnlyBridges {
	my $self    = shift;
	my $stepObj = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	# reset attribut "rout_on_bridges" to NO, thus pcb is not on bridges

	my $unitRTM  = $stepObj->GetUniRTM();
	my @outlines = $unitRTM->GetOutlineChains();

	my @chains = $unitRTM->GetChains();
	my @lefts = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } @chains;

	# If not exist outline rout, check if pcb is on bridges
	unless ( scalar(@outlines) ) {

		# no chains at layer
		if ( scalar(@lefts) == 0 && !$stepObj->GetUserRoutOnBridges() ) {

			my $m =
			    "Ve stepu: \""
			  . $stepObj->GetStepName()
			  . "\", ve vrstvě: \"$layer\""
			  . " není ani obrysová vrstva ani můstky s kompenzací left. Pokud je pcb na můstky nastav jim kompenzaci left.";

			$resItem->AddWarning($m);
		}
	}
}

# Check if there is outline layer, if all other layer (inner, right etc) are in this outline layer
sub __OutsideChains {
	my $self = shift;

	my $stepObj = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $unitRTM = $stepObj->GetUniRTM();

	my @lefts = $unitRTM->GetOutlineChains();

	# If exist outline rout, check if other chains are inside
	if ( scalar(@lefts) ) {

		my @seq = $unitRTM->GetChainSequences();

		my %tmp;
		@tmp{ map { $_ } @lefts } = ();

		my @otherLayers = grep { !exists $tmp{$_} } @seq;

		my @notInside = grep { !$_->GetIsInside() } @otherLayers;

		if ( scalar(@notInside) && !$stepObj->GetUserRoutOnBridges() ) {

			my @info = map { $_->GetStrInfo() } @notInside;
			my $str = join( "; ", @info );

			my $m =
			    "Ve stepu: \""
			  . $stepObj->GetStepName()
			  . "\", ve vrstvě: \""
			  . $layer
			  . "\" jsou frézy, které by měly být uvnitř obrysové frézy, ale nejsou ($str)."
			  . "Je to tak sprvně?";

			$resItem->AddWarning($m);

		}
	}

}

# Check when left rout exists
sub __LeftRoutChecks {
	my $self    = shift;
	my $stepObj = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $unitRTM = $stepObj->GetUniRTM();

	# 1) test if tehere are left no cyclic rout, which has foot down
	my @lefts   = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } $unitRTM->GetChains();
	my @leftSeq = map  { $_->GetChainSequences() } @lefts;
	@leftSeq = grep { $_->HasFootDown() } @leftSeq;

	if ( scalar(@leftSeq) ) {

		my @info = map { $_->GetStrInfo() } @leftSeq;
		my $str = join( "; ", @info );
		my $m =
		    "Ve stepu: \""
		  . $stepObj->GetStepName()
		  . "\", ve vrstvě: \"$layer\" jsou frézy s kompenzací left, které mají nastavenou patku (.foot_down attribut) ($str).";

		$resItem->AddError($m);
	}

	# 2) Test if outline orut has only one attribute "foot_down_<angle>deg" of specific kind
	my @outlines = $unitRTM->GetOutlineChains();

	foreach my $oSeq (@outlines) {

		my $m = "";

		my @foot_down_0deg = grep { defined $_->{"att"}->{"foot_down_0deg"} } $oSeq->GetFeatures();

		if ( scalar(@foot_down_0deg) > 1 ) {
			my $m =
			    "Ve stepu: \""
			  . $stepObj->GetStepName()
			  . "\", ve vrstvě: \"$layer\" je fréza: "
			  . $oSeq->GetStrInfo()
			  . ", která má více atributů \"foot_down_0deg\". Oprav to.\n";

			$resItem->AddError($m);
		}

		my @foot_down_270deg = grep { defined $_->{"att"}->{"foot_down_270deg"} } $oSeq->GetFeatures();

		if ( scalar(@foot_down_270deg) > 1 ) {

			my $m =
			    "Ve stepu: \""
			  . $stepObj->GetStepName()
			  . "\", ve vrstvě: \"$layer\" je fréza: "
			  . $oSeq->GetStrInfo()
			  . ", která má více atributů \"foot_down_270deg\". Oprav to.\n";

			$resItem->AddError($m);
		}
	}

	# 3) Outline rout. Test if one feature doesn\t have more attributes "foot_down" eg: foot_down_0deg + foot_down_90deg

	foreach my $oSeq (@outlines) {

		my @wrongAtt = grep { defined $_->{"att"}->{"foot_down_0deg"} && defined $_->{"att"}->{"foot_down_270deg"} } $oSeq->GetFeatures();

		if ( scalar(@wrongAtt) > 1 ) {

			my @ids = map { $_->{"id"} } @wrongAtt;
			my $str = join( ";", @ids );

			my $m =
			    "Ve stepu: \""
			  . $stepObj->GetStepName()
			  . "\", ve vrstvě: \"$layer\" jsou \"features\", ktereé mají zároveň atribut \"foot_down_0deg\" i \"foot_down_270deg\". Oprav to.\n";

			$resItem->AddError($m);
		}
	}
	
	# 4) If some chain tool containoutline, all another chain must by outline
	my @chains   =  $unitRTM->GetChains();
	
	foreach my $ch (@chains){
		
		my @outline = grep { $_->IsOutline() } $ch->GetChainSequences();
		
		if(scalar(@outline) && scalar(@outline) != scalar($ch->GetChainSequences())){
			
			my $m =
			    "Ve stepu: \""
			  . $stepObj->GetStepName()
			  . "\", ve vrstvě: \"$layer\" jsou jedním nástrojem: \"".$ch->GetStrInfo."\" dfinovány orbysové i neobrysové frézy dohromady. Nelze, oprav to.\n";

			$resItem->AddError($m);
		}
		
			
		
	}

}

# Check if tool sizes are sorted ASC
sub __OutlineToolIsLast {
	my $self    = shift;
	my $stepObj = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $unitRTM = $stepObj->GetUniRTM();

	my @chains = $unitRTM->GetChains();

	my @outlines = $unitRTM->GetOutlineChains();

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
					  . $stepObj->GetStepName()
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

