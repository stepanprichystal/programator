#-------------------------------------------------------------------------------------------#
# Description: Silkscreen checks
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Material::MaterialInfo;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Check if material for 1v +2v pcb is on the stock
# Check if material for multilayer pcb is actually on the store
sub BaseMatInStock {
	my $self      = shift;
	my $pcbId     = shift;    #pcb id
	my $orderArea = shift;    # if defined, area is considered with avalaible amount on stock
	my $errMess   = shift;    # if err, missin materials in stock

	my $result = 1;

	my $matRef = ( HegMethods->GetAllByPcbId($pcbId) )[0]->{"material_reference_subjektu"};

	die 'Material reference is not defined for pcbId: $pcbId' unless ( defined $matRef );

	my $storeInfo = HegMethods->GetMatStoreInfo($matRef);

	if ( !defined $storeInfo ) {

		$result = 0;
		$$errMess .= "- Material with reference: $matRef is not in  IS stock evidence\n";

	}
	else {
		my $amount    = sprintf( "%.2f", $storeInfo->{"stav_skladu"} );
		my $requested = sprintf( "%.2f", $storeInfo->{"pocet_poptavano_vyroba"} );
		my $avalaible = sprintf( "%.2f", $amount - $requested - ( defined $orderArea ? $orderArea : 0 ) );

		if ( $avalaible <= 0 ) {

			$result = 0;
			$$errMess .= "- Avalaible material quantity (" . $storeInfo->{"nazev_mat"} . ") is: " . $avalaible . "m2 in IS stock.\n";
			$$errMess .= "(real amount is: " . $amount . "m2; requested by production is: " . $requested . "m2";
			$$errMess .= "; request by order:$orderArea m2" if ( defined $orderArea );
			$$errMess .= ")\n";
		}
	}

	return $result;
}

 

# Check if material for multilayer pcb is actually on the store
sub StackupMatInStock {
	my $self      = shift;
	my $inCAM     = shift;
	my $pcbId     = shift;    #pcb id
	my $stackup   = shift;    # if not defined, stackup will e loaded
	my $orderArea = shift;    # if defined, area is considered with avalaible amount on stock
	my $errMess   = shift;    # if err, missin materials in stock

	my $result = 1;

	unless ($stackup) {
		$stackup = Stackup->new( $inCAM, $pcbId );
	}

	my $pnl = StandardBase->new( $inCAM, $pcbId );

	# 1) check cores
	foreach my $m ( $stackup->GetAllCores() ) {

		# abs - because copper id can be negative (plated core)
		my @mat = HegMethods->GetCoreStoreInfoByUDA( $m->GetQId(), $m->GetId(), abs( $m->GetTopCopperLayer()->GetId() ) );

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
			my $amount    = sprintf( "%.2f", $mat[0]->{"stav_skladu"} );
			my $requested = sprintf( "%.2f", $mat[0]->{"pocet_poptavano_vyroba"} );
			my $avalaible = sprintf( "%.2f", $amount - $requested - ( defined $orderArea ? $orderArea : 0 ) );

			if ( $avalaible <= 0 ) {

				$result = 0;
				$$errMess .= "- Avalaible material quantity (" . $mat[0]->{"nazev_mat"} . ") is: " . $avalaible . "m2 in IS stock.\n";
				$$errMess .= "(real amount is: " . $amount . "m2; requested by production is: " . $requested . "m2";
				$$errMess .= "; request by order:$orderArea m2" if ( defined $orderArea );
				$$errMess .= ")\n";
			}
		}
	}

	# 2) Check prepregs
	foreach my $m ( map { $_->GetAllPrepregs() } grep { $_->GetType() eq StackEnums->MaterialType_PREPREG } $stackup->GetAllLayers() ) {

		my $prepregW = undef;
		my $prepregH = undef;

		my @mat = ();

		if ( $pnl->IsStandard() ) {

			$prepregW = $pnl->GetStandard()->PrepregW();
			$prepregH = $pnl->GetStandard()->PrepregH();

			if ( $m->GetTextType() =~ /49np|no.*flow/i ) {

				@mat = HegMethods->GetPrepregStoreInfoByUDA( $m->GetQId(), $m->GetId(), undef, undef, 1 );

				# Flex prepreg material is always cut from dimension 305*456mm, test if panel height is smaller than 456mm
				# (tolerance +-3mm)
				@mat = grep { abs( $_->{"sirka"} - $prepregW ) <= 3 && $prepregH <= $_->{"hloubka"} } @mat;

			}
			else {

				@mat = HegMethods->GetPrepregStoreInfoByUDA( $m->GetQId(), $m->GetId() );

				# Check if material dimension are in tolerance +-2mm for width
				# Check if material dimension are in tolerance +-10mm for height
				# (we use sometimes shorter version -10mm of standard prepregs because of stretching prepregs by temperature and pressure)
				@mat = grep { abs( $_->{"sirka"} - $prepregW ) <= 2 && abs( $_->{"hloubka"} - $prepregH ) <= 10 } @mat;

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

			my $amount    = sprintf( "%.2f", $mat[0]->{"stav_skladu"} );
			my $requested = sprintf( "%.2f", $mat[0]->{"pocet_poptavano_vyroba"} );
			my $avalaible = sprintf( "%.2f", $amount - $requested - ( defined $orderArea ? $orderArea : 0 ) );

			if ( $avalaible <= 0 ) {

				$result = 0;
				$$errMess .= "- Avalaible material quantity (" . $mat[0]->{"nazev_mat"} . ") is: " . $avalaible . "m2 in IS stock.\n";
				$$errMess .= "(real amount is: " . $amount . "m2; requested by production is: " . $requested . "m2";
				$$errMess .= "; request by order:$orderArea m2" if ( defined $orderArea );
				$$errMess .= ")\n";

			}
		}
	}

	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use Data::Dump qw(dump);

		use aliased 'Packages::CAMJob::Material::MaterialInfo';
		use aliased 'Packages::InCAM::InCAM';
	
		#my $inCAM = InCAM->new();
		my $jobId = "d235159";
	
		my $mess = "";
	 
		my $result = MaterialInfo->BaseMatInStock($jobId, undef, \$mess);
	 
		print $mess;
}

1;