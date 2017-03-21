
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers as gerber274x
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::ExportGerMngr;

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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"stepList"} = shift;

	return $self;
}

sub OnlyBridges {
	my $self = shift;

	my $messMngr = shift;

	my $resultItem = ItemResult->new("Rout bridges");

	foreach my $s ( @{ $self->{"steps"} } ) {

		$self->__OnlyBridges( $s, "f", $resultItem );
	}

	return $resultItem;
}

# Check if there is noly bridges rout
# if so, save this information to job attribute "rout_on_bridges"
sub __OnlyBridges {
	my $self    = shift;
	my $step    = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	# reset attribut "rout_on_bridges" to NO, thus pcb is not on bridges
	 
	my $stepObj = $self->{"stepList"}->GetStep($step);

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @outlines = $unitRTM->GetOutlineChains();

	my @chains = $unitRTM->GetChains();
	my @lefts = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } @chains;

	# If not exist outline rout, check if pcb is on bridges
	unless ( scalar(@outlines) ) {

		# no chains at layer
		unless (@chains) {

			my $m = "Ve stepu: \"$layer\", ve vrstvě: \"$layer\""
			  . " není ani obrysová vrstva ani můstky. Je to tak správně?";

			$resItem->AddWarning($m);
		}

		# maybe thera are bridges, but not LEFT
		elsif ( scalar(@lefts) == 0 ) {
			
				my $m = "Ve stepu: \"$layer\", ve vrstvě: \"$layer\""
			  . " není ani obrysová vrstva ani můstky s kompenzací left. Pokud je pcb na můstky nastav jim kompenzaci left.";

			$resItem->AddWarning($m);
 
		}

		# there are probably bridges with left comp
		else {

			my @m = ("Pravděpodobně je dps ponechaná na můstky, které mají kompenzaci left. Pokud to není pravda oprav frézu.");
			my @b = ( "Takhle je to správně", "Opravím frézu" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 0 ) {

				# set pcb is rout on bridges
				CamAttributes->SetJobAttribute( $inCAM, $jobId, "rout_on_bridges", 1 );

			}
			else {
				$result = 0;
			}
		}
	}

	return $result;
}

sub OutsideChains {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $messMngr = shift;

	my $resultItem = ItemResult->new("Outside rout");

	foreach my $s ( @{ $self->{"steps"} } ) {

		$self->__OutsideChains( $s, "f", $resultItem );
	}

	return $resultItem;
}

# Check if there is outline layer, if all other layer (inner, right etc) are in this outline layer
sub __OutsideChains {
	my $self = shift;

	my $step    = shift;
	my $layer   = shift;
	my $resItem = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @lefts = $unitRTM->GetOutlineChains();

	# If exist outline rout, check if other chains are inside
	if ( scalar(@lefts) ) {

		my @seq = $unitRTM->GetChainSequences();

		my %tmp;
		@tmp{ map { $_ } @lefts } = ();

		my @otherLayers = grep { !exists $tmp{$_} } @seq;

		my @notInside = grep { !$_->GetIsInside() } @otherLayers;

		if ( scalar(@notInside) ) {

			my @info = map { $_->GetStrInfo() } @notInside;
			my $str = join( "; ", @info );

			my $m =
			    "Ve stepu: \""
			  . $layer
			  . "\", ve vrstvě: \""
			  . $layer
			  . "\" jsou frézy, které by měly být uvnitř obrysové frézy, ale nejsou ($str)."
			  . "Je to tak sprvně?";

			$resItem->AddWarning($m);

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

