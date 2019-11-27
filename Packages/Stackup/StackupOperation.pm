#-------------------------------------------------------------------------------------------#
# Description: Contain special function, which work with stackup
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::StackupOperation;

#3th party library
use List::Util;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupBase::StackupBase';
use aliased 'Enums::EnumsIS';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'CamHelpers::CamJob';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

#Return final thickness of pcb base on Cu layer number
sub GetThickByLayer {
	my $self     = shift;
	my $inCAM    = shift;
	my $pcbId    = shift;    #pcb id
	my $layer    = shift;    #layer of number. Simple c,1,2,s or v1, v2 use ENUMS::Layers
	my $noResist = shift;    #indicate id add resit

	my $thick = 0;           #total thick

	if ( HegMethods->GetBasePcbInfo($pcbId)->{"pocet_vrstev"} > 2 ) {

		my $stackup = Stackup->new( $inCAM, $pcbId );

		$thick = $stackup->GetThickByCuLayer($layer) / 1000;

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
	my $inCAM     = shift;
	my $jobId     = shift;
	my $layerName = shift;
	my $stackup   = shift;

	unless ( defined $stackup ) {
		$stackup = Stackup->new( $inCAM, $jobId );
	}

	my $side = "";

	my $product = $stackup->GetProductByLayer($layerName);
 
	if ( $layerName eq $product->GetTopCopperLayer() ) {

		$side = "top";
	}
	elsif ( $layerName eq $product->GetBotCopperLayer() ) {

		$side = "bot";
	}
	
	return $side;
}

# If stackup contains core topmost or very bottom (Cu-core-cu-prepreg-Cu-core-cu)
# Return 1, else 0
sub OuterCore {
	my $self          = shift;
	my $inCAM         = shift;
	my $pcbId         = shift;    #pcb id
	my $inputProducts = shift;    # input products which contain outer core

	my $result = 0;

	if ( CamJob->GetSignalLayerCnt( $inCAM, $pcbId ) > 2 ) {

		my $stackup = Stackup->new( $inCAM, $pcbId );

		my @input = grep { $_->GetOuterCoreTop() || $_->GetOuterCoreBot() } $stackup->GetInputProducts();

		if ( scalar(@input) ) {
			$result = 1;
			push( @{$inputProducts}, @input ) if ( defined $inputProducts );
		}
	}

	return $result;
}

# Check if material for multilayer pcb is actually on the store
sub StackupMatInStock {
	my $self    = shift;
	my $inCAM   = shift;
	my $pcbId   = shift;    #pcb id
	my $stackup = shift;    # if not defined, stackup will e loaded
	my $errMess = shift;    # if err, missin materials in stock

	my $result = 1;

	unless ($stackup) {
		$stackup = Stackup->new( $inCAM, $pcbId );
	}

	my $pnl = StandardBase->new( $inCAM, $pcbId );

	# 1) check cores
	foreach my $m ( $stackup->GetAllCores() ) {

		# abs - because copper id can be negative (plated core)
		my @mat = HegMethods->GetCoreStoreInfo( $m->GetQId(), $m->GetId(), abs( $m->GetTopCopperLayer()->GetId() ) );

		if ( $m->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {

			# Flex material is always cut from dimension 305*456mm, test if panel height is smaller than 456mm
			# (tolerance +-3mm)
			@mat = grep { abs( $_->{"sirka"} - $pnl->W() ) <= 3 && $pnl->H() <= $_->{"hloubka"} } @mat;

		}
		else {

			# Check if material dimension are in tolerance +-2mm
			@mat = grep { abs( $_->{"sirka"} - $pnl->W() ) <= 2 && abs( $_->{"hloubka"} - $pnl->H() ) <= 2 } @mat;

		}

		if ( scalar(@mat) == 0 ) {

			$result = 0;
			$$errMess .=
			    "- Material: "
			  . $m->GetType() . " - "
			  . $m->GetTextType() . ","
			  . $m->GetText() . " - "
			  . $m->GetTopCopperLayer()->GetText() . " ("
			  . $pnl->W() . "mm x "
			  . $pnl->H()
			  . "mm) is not in  IS stock evidence\n";

		}
		else {

			if ( $mat[0]->{"stav_skladu"} == 0 ) {

				$result = 0;
				$$errMess .= "- Material quantity of " . $mat[0]->{"nazev_mat"} . "  is 0m2 in IS stock\n";

			}
		}
	}

	# 2) Check prepregs
	foreach my $m ( map { $_->GetAllPrepregs() } grep { $_->GetType() eq Enums->MaterialType_PREPREG } $stackup->GetAllLayers() ) {

		my $prepregW = undef;
		my $prepregH = undef;

		my @mat = ();

		if ( $pnl->IsStandard() ) {

			$prepregW = $pnl->GetStandard()->PrepregW();
			$prepregH = $pnl->GetStandard()->PrepregH();

			if ( $m->GetTextType() =~ /49np|no.*flow/i ) {

				@mat = HegMethods->GetPrepregStoreInfo( $m->GetQId(), $m->GetId(), undef, undef, 1 );

				# Flex prepreg material is always cut from dimension 305*456mm, test if panel height is smaller than 456mm
				# (tolerance +-3mm)
				@mat = grep { abs( $_->{"sirka"} - $prepregW ) <= 3 && $prepregH <= $_->{"hloubka"} } @mat;

			}
			else {

				@mat = HegMethods->GetPrepregStoreInfo( $m->GetQId(), $m->GetId() );

				# Check if material dimension are in tolerance +-2mm
				@mat = grep { abs( $_->{"sirka"} - $prepregW ) <= 2 && abs( $_->{"hloubka"} - $prepregH ) <= 2 } @mat;

			}

		}

		if ( scalar(@mat) == 0 ) {

			$result = 0;
			$$errMess .=
			    "- Material: "
			  . $m->GetType() . " - "
			  . $m->GetTextType() . ","
			  . $m->GetText() . " ("
			  . $prepregW . "mm x "
			  . $prepregH
			  . "mm) is not in  IS stock evidence\n";

		}
		else {

			if ( $mat[0]->{"stav_skladu"} == 0 ) {

				$result = 0;
				$$errMess .= "- Material quantity of " . $mat[0]->{"nazev_mat"} . "  is 0m2 in IS stock\n";

			}
		}
	}

	return $result;
}

# Return array of couples
# Couple contain top + bot "package" and its layers
# Package is set of cores+prepregs+cu foil laminated in separately
# Attention
# - NoFlow prepregs are removed - bond bbetween package
# - Not entirely implemnted couple: flex + flex package
sub GetJoinedFlexRigidPackages {
	my $self    = shift;
	my $pcbId   = shift;    #pcb id
	my $stackup = shift;    # if not defined, stackup will e loaded

	my $result = 1;

	unless ($stackup) {
		$stackup = StackupBase->new($pcbId);
	}

	my @laminatePckgsInf = ();

	#	my @laminatePckgs = ();

	my @layers = $stackup->GetAllLayers();

	my $firstCore;
	my $secondCore;

	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		if ( $layers[$i]->GetType() eq Enums->MaterialType_CORE ) {

			if ( !defined $firstCore ) {
				$firstCore = $layers[$i]->GetCoreRigidType();
			}
			elsif ( !defined $secondCore ) {

				if ( !( $layers[$i]->GetCoreRigidType() eq Enums->CoreType_RIGID && $firstCore eq Enums->CoreType_RIGID ) ) {

					$secondCore = $layers[$i]->GetCoreRigidType();
				}
			}
		}

		if ( defined $firstCore && $secondCore ) {

			# Flex core was found second (after rigid core)
			# Create "laminate package" info
			my @packgLayersTop;
			my @packgLayersBot;

			if ( $firstCore eq Enums->CoreType_FLEX && $secondCore eq Enums->CoreType_RIGID ) {

				# look index of flex core
				my $flexIdx = undef;
				for ( my $k = $i ; $k >= 0 ; $k-- ) {

					if ( $layers[$k]->GetType() eq Enums->MaterialType_CORE && $layers[$k]->GetCoreRigidType() eq Enums->CoreType_FLEX ) {
						$flexIdx = $k;
						last;
					}
				}

				# look layers up
				@packgLayersTop = @layers[ $flexIdx - 1 .. $flexIdx + 1 ];
				@packgLayersBot = @layers[ $flexIdx + 2 .. scalar(@layers) - 1 ];

			}
			elsif (    ( $secondCore eq Enums->CoreType_FLEX && $firstCore eq Enums->CoreType_RIGID )
					|| ( $firstCore eq Enums->CoreType_FLEX && $secondCore eq Enums->CoreType_FLEX ) )
			{

				@packgLayersBot = @layers[ $i - 1 .. $i + 1 ];

				# search up through stackup up next flex core or start of stackup
				my $endIdx = 0;
				for ( my $k = $i - 1 ; $k >= 0 ; $k-- ) {

					if ( $layers[$k]->GetType() eq Enums->MaterialType_CORE && $layers[$k]->GetCoreRigidType() eq Enums->CoreType_FLEX ) {
						$endIdx = $k;
						$endIdx -= 1;    # include core copper
						last;
					}
				}

				# look layers down
				@packgLayersTop = @layers[ $endIdx .. $i - 2 ];

			}

			# Remove noflow prepreg from layers
			my @prepregs = grep { $_->GetType() eq Enums->MaterialType_PREPREG } ( @packgLayersTop, @packgLayersBot );
			foreach my $p (@prepregs) {

				my @all = @{ $p->{"prepregs"} };

				for ( my $i = scalar( @{ $p->{"prepregs"} } ) - 1 ; $i >= 0 ; $i-- ) {

					if ( $p->{"prepregs"}->[$i]->GetText() =~ /49np/i ) {

						$p->{"thick"} -= $p->{"prepregs"}->[$i]->GetThick();

						splice @{ $p->{"prepregs"} }, $i, 1;

					}
				}

			}

			my %infJoin = ();

			my %infTop = ();
			$infTop{"coreType"}      = $firstCore;
			$infTop{"layers"}        = \@packgLayersTop;
			$infTop{"topCopperName"} = ( grep { $_->GetType() eq Enums->MaterialType_COPPER } @packgLayersTop )[0]->GetCopperName();
			$infTop{"botCopperName"} = ( grep { $_->GetType() eq Enums->MaterialType_COPPER } reverse @packgLayersTop )[0]->GetCopperName();
			$infJoin{"packageTop"}   = \%infTop;

			my %infBot = ();
			$infBot{"coreType"}      = $secondCore;
			$infBot{"layers"}        = \@packgLayersBot;
			$infBot{"topCopperName"} = ( grep { $_->GetType() eq Enums->MaterialType_COPPER } @packgLayersBot )[0]->GetCopperName();
			$infBot{"botCopperName"} = ( grep { $_->GetType() eq Enums->MaterialType_COPPER } reverse @packgLayersBot )[0]->GetCopperName();
			$infJoin{"packageBot"}   = \%infBot;

			push( @laminatePckgsInf, \%infJoin );

			$i--;
			$firstCore  = undef;
			$secondCore = undef;
		}
	}

	return @laminatePckgsInf;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Stackup::StackupOperation';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $mes   = "";

	#	my $side;
	#	my @package = StackupOperation->GetJoinedFlexRigidPackages("d222775");
	#
	#	my @package2 = StackupOperation->GetJoinedFlexRigidPackages2("d222777");

	print StackupOperation->StackupMatInStock( $inCAM, "d251561", undef, \$mes );

	#print @package;

}

1;
