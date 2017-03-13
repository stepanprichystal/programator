#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Routing::Check1UpChain;

#3th party library
use utf8;
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Check if there is outline layer, if all other layer (inner, right etc) are in this outline layer
sub OutsideChains {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @lefts = $unitRTM->GetOutlineChains();

	# If exist outline rout, check if other chains are inside
	if ( scalar(@lefts) ) {

		my @seq = $unitRTM->GetChainSequences();

		my %tmp;
		@tmp{ map { $_ } @lefts } = ();

		my @otherLayers = grep { !exists $tmp{ $_ } } @seq;

		my @notInside = grep { !$_->GetIsInside() } @otherLayers;

		if ( scalar(@notInside) ) {

			my @info = map { $_->GetStrInfo() } @notInside;
			my $str = join( "; ", @info );

			my @m =
			  ( "Ve vrstvě: \"" . $layer . "\" jsou frézy, které by měly být uvnitř obrysové frézy, ale nejsou ($str).", "Je to tak správně?" );
			my @b = ( "Ano", "Není, opravím to" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}

		}
	}

	return $result;
}

# Check if there is noly bridges rout
# if so, save this information to job attribute "rout_on_bridges"
sub OnlyBridges {
	my $self = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my $result = 1;

	# reset attribut "rout_on_bridges" to NO, thus pcb is not on bridges
	CamAttributes->SetJobAttribute($inCAM, $jobId, "rout_on_bridges", 0 );

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @outlines = $unitRTM->GetOutlineChains();

	my @chains = $unitRTM->GetChains();
	my @lefts = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } @chains;

	# If not exist outline rout, check if pcb is on bridges
	unless ( scalar(@outlines) ) {

		# no chains at layer
		unless (@chains) {

			my @m = ("Ve vrstvě není ani obrysová vrstva ani můstky. Je to tak správně?");
			my @b = ( "Ano", "Ne" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}

		}

		# maybe thera are bridges, but not LEFT
		elsif ( scalar(@lefts) == 0 ) {

			my @m = ("Ve vrstvě není ani obrysová vrstva ani můstky s kompenzací left. Pokud je pcb na můstky nastav jim kompenzaci left.");
			my @b = ( "Takhle je to správně", "Opravím můstky na LEFT" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}

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

# Check when left rout exists
sub LeftRoutChecks {
	my $self = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $mess  = shift;

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	# 1) test if tehere are left no cyclic rout, which has foot down
	my @lefts   = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } $unitRTM->GetChains();
	my @leftSeq = map  { $_->GetChainSequences() } @lefts;
	@leftSeq = grep { !$_->GetCyclic() && $_->HasFootDown() } @leftSeq;

	if ( scalar(@leftSeq) ) {
		$result = 0;

		my @info = map { $_->GetStrInfo() } @leftSeq;
		my $str = join( "; ", @info );
		$$mess .= "Ve vrstvě: \"" . $layer . "\" jsou frézy s kompenzací left, které nejsou obrysové a mají patku. " . $str;
	}
}

sub TestFindFoots {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my $result     = 1;
	my $routModify = 0;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @lefts = $unitRTM->GetOutlineChains();

	foreach my $left (@lefts) {

		my @features = $left->GetFeatures();
		my %modify   = RoutStart->RoutNeedModify( \@features );

		if ( $modify{"result"} ) {

			my @m = ("Byly nalezeni vhodní kandidáti na patku, ale fréza se musí uparvit.");
			my @b = ( "Upravit frézu", "Neupravovat" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {

				$routModify = 1;

			}
			else {

				$result = 0;
				return $result;
			}

			RoutStart->ProcessModify( \%modify, \@features );
			my %footResult = RoutStart->GetRoutFootDown( \@features );

			unless ( $footResult{"result"} ) {

				my @m = ( "Začátek frézy pro levý horní roh frézy: " . $left->GetStrInfo() . " nebyl nalezen" );

				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m );    #  Script se zastavi
				$result = 0;
			}
			else {

				if ($routModify) {

					# překreslit frézu
				}

			}
		}
	}

	return $result;
}

sub FindFoots90Deg {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my $result     = 1;
	my $routModify = 0;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @lefts = $unitRTM->GetOutlineChains();

	foreach my $left (@lefts) {

		my @features = $left->GetFeatures();

		my $rotation = RoutRotation->new( \@features );
		$rotation->Rotate(90);

		my %modify = RoutStart->RoutNeedModify( \@features );

		if ( $modify{"result"} ) {

			my @m = ("Byly nalezeni vhodní kandidáti na patku, ale fréza se musí uparvit.");
			my @b = ( "Upravit frézu", "Neupravovat" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {

				$routModify = 1;

			}
			else {

				$result = 0;
				return $result;
			}

			RoutStart->ProcessModify( \%modify, \@features );
			my %footResult = RoutStart->GetRoutFootDown( \@features );

			unless ( $footResult{"result"} ) {

				my @m = ( "Začátek frézy pro levý horní roh frézy: " . $left->GetStrInfo() . " nebyl nalezen" );

				$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m );    #  Script se zastavi
				$result = 0;
			}
			else {

				if ($routModify) {
					$rotation->RotateBack();
				}
			}
		}
	}

	return $result;
}

sub __GetUnitRTM {
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	return $unitRTM;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Routing::Check1UpChain';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';
	use aliased 'Enums::EnumsGeneral';

	my $messMngr = MessageMngr->new("D3333");

	my $inCAM = InCAM->new();

	my $jobId = "f52456";
	my $step  = "o+1";
	my $layer = "f";

	my $res = Check1UpChain->LeftRoutChecks($inCAM, $jobId, $step, $layer, $messMngr );

	print STDERR "test";

}

1;

