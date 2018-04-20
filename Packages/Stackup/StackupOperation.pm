#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupOperation;

#3th party library

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Enums::EnumsIS';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

#Return final thickness of pcb base on Cu layer number
sub GetThickByLayer {
	my $self     = shift;
	my $pcbId    = shift;    #pcb id
	my $layer    = shift;    #layer of number. Simple c,1,2,s or v1, v2 use ENUMS::Layers
	my $noResist = shift;    #indicate id add resit

	my $thick = 0;           #total thick

	if ( HegMethods->GetTypeOfPcb($pcbId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($pcbId);

		$thick = $stackup->GetThickByLayerName($layer);

		my $cuLayer = $stackup->GetCuLayer($layer);

		#test by Mira, add 80um (except cores)
		if ( $cuLayer->GetType() eq EnumsGeneral->Layers_TOP || $cuLayer->GetType() eq EnumsGeneral->Layers_BOT ) {
			$thick += 0.080;
		}

	}
	else {

		$thick = HegMethods->GetPcbMaterialThick($pcbId);

		#test by Mira, add 80um (except cores)
		$thick += 0.080;
	}

	#there are two resist from top and bottom. Top resis 40um + bottom 20um
	if ( !$noResist ) {
		$thick += 0.080;

	}

	return ( sprintf "%3.2f", ($thick) );
}

# Return if Cu layer has orientation TOP/BOT
# Orientation is based on view pcb from top
# Return string "top" or "bot"
sub GetSideByLayer {
	my $self      = shift;
	my $jobId     = shift;
	my $layerName = shift;
	my $stackup   = shift;

	unless ( defined $stackup ) {
		$stackup = Stackup->new($jobId);
	}

	my $side = "";

	my %pressInfo = $stackup->GetPressInfo();
	my $core      = $stackup->GetCoreByCopperLayer($layerName);
	my $press     = undef;

	if ($core) {

		my $topCopperName = $core->GetTopCopperLayer()->GetCopperName();
		my $botCopperName = $core->GetBotCopperLayer()->GetCopperName();

		if ( $layerName eq $topCopperName ) {

			$side = "top";
		}
		elsif ( $layerName eq $botCopperName ) {

			$side = "bot";
		}
	}
	else {

		# find, which press was layer pressed in
		foreach my $pNum ( keys %pressInfo ) {

			my $p = $pressInfo{$pNum};

			if ( $p->GetTopCopperLayer() eq $layerName ) {

				$side = "top";
				last;

			}
			elsif ( $p->GetBotCopperLayer() eq $layerName ) {

				$side = "bot";
				last;
			}
		}
	}

	return $side;
}

# If stackup contains core topmost or very bottom (Cu-core-cu-prepreg-Cu-core-cu)
# Return 1, else 0
sub OuterCore {
	my $self  = shift;
	my $pcbId = shift;    #pcb id

	my $result = 0;

	if ( HegMethods->GetTypeOfPcb($pcbId) eq 'Vicevrstvy' ) {

		my $stackup = Stackup->new($pcbId);
		my @cores   = $stackup->GetAllCores();

		my $firstC = $cores[0];
		my $lastC  = $cores[ scalar(@cores) - 1 ];

		my $topCopper = $firstC->GetTopCopperLayer()->GetCopperName();

		my $botCopper = $lastC->GetBotCopperLayer()->GetCopperName();

		if ( $topCopper eq "c" || $botCopper eq "s" ) {

			$result = 1;
		}

	}

	return $result;
}

# Check if material for multilayer pcb is actually on the store
sub StackupMatInStock {
	my $self    = shift;
	my $pcbId   = shift;    #pcb id
	my $stackup = shift;    # if not defined, stackup will e loaded
	my $errMess = shift;    # if err, missin materials in stock

	my $result = 1;

	unless ($stackup) {
		$stackup = Stackup->new($pcbId);
	}

	# 1) check cores
	my @prepregs = map {$_->GetAllPrepregs() } grep {  $_->GetType() eq Enums->MaterialType_PREPREG} $stackup->GetAllLayers() ;
 
 
	foreach my $m ( $stackup->GetAllCores() ) {

		# abs - because copper id can be negative (plated core)
		my  $sInfo = HegMethods->GetCoreStoreInfo( $m->GetQId(), $m->GetId(), abs($m->GetTopCopperLayer()->GetId()) ); 
 
		if ( $sInfo == 0 ) {

			$result = 0;
			$$errMess .=
			  "- Material: " . $m->GetType() . " - "  . $m->GetTextType() . "," . $m->GetText() ." - ".$m->GetTopCopperLayer()->GetText(). " is not in  IS stock evidence\n";

		}
		elsif ( $sInfo->{"stav_skladu"} == 0 ) {

			$result = 0;
			$$errMess .= "- Material quantity of " . $sInfo->{"nazev_mat"} . "  is 0m2 in IS stock\n";

		}
	}

	
	foreach my $m ( map {$_->GetAllPrepregs() } grep {  $_->GetType() eq Enums->MaterialType_PREPREG} $stackup->GetAllLayers() ) {

		my $sInfo = HegMethods->GetPrepregStoreInfo( $m->GetQId(), $m->GetId() );
 
		if ( $sInfo == 0 ) {

			$result = 0;
			$$errMess .=
			  "- Material: " . $m->GetType() . " - "  . $m->GetTextType() . "," . $m->GetText() . " is not in  IS stock evidence\n";

		}
		elsif ( $sInfo->{"stav_skladu"} == 0 ) {

			$result = 0;
			$$errMess .= "- Material quantity of " . $sInfo->{"nazev_mat"} . "  is 0m2 in IS stock\n";

		}
	}
	

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupOperation';

	my $mes = "";

	my $test = StackupOperation->StackupMatInStock("d152456", undef, \$mes);
	
	print $mes;

	print $test;

}

1;
