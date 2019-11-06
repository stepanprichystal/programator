#-------------------------------------------------------------------------------------------#
# Description: Helper class, which is used by Stackup.pm class for various helper purposes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupBuilder;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq first_index);
use List::Util qw(first min);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Packages::Stackup::Stackup::StackupProduct::ProductPress';
use aliased 'Packages::Stackup::Stackup::StackupProduct::ProductInput';
use aliased 'Packages::Stackup::Stackup::StackupProduct::ProductLayer';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"stackup"} = shift;

	# PROPERTIES

	# Get plated NC layers which affect press lamination
	my @NCLayers = CamDrilling->GetNCLayersByTypes(
													$self->{"inCAM"},
													$self->{"jobId"},
													[
													   EnumsGeneral->LAYERTYPE_plt_nDrill,        EnumsGeneral->LAYERTYPE_plt_bDrillTop,
													   EnumsGeneral->LAYERTYPE_plt_bDrillBot,     EnumsGeneral->LAYERTYPE_plt_nFillDrill,
													   EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot,
													   EnumsGeneral->LAYERTYPE_plt_cDrill,        EnumsGeneral->LAYERTYPE_plt_cFillDrill
													]
	);
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );

	my @NCCoreDrill =
	  grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NCLayers;

	my @NCBlindDrill =
	  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NCLayers;

	$self->{"NCLayers"} = \@NCLayers;

	$self->{"NCCore"} = \@NCCoreDrill;

	$self->{"NCBlind"} = \@NCBlindDrill;

	return $self;

}

sub BuildStackupLamination {
	my $self = shift;

	my $stackup = $self->{"stackup"};

	# 1) Prepare stackup products
	my @parsed = map { { "l" => $_, "t" => Enums->ProductL_MATERIAL } } @{ $stackup->{"layers"} };

	my @productInputs = $self->__BuildProductInput( \@parsed );

	my @productPress = $self->__BuildProductPress( \@parsed );

	# 2) Set attributes plugging; outer core to all products

	$self->__SetProductOuterCore( \@productPress );

	$self->__SetProductPlugging( \@productPress );

	# 3) Build searching matrix of products by copper layer

	my @matrix = $self->__BuildCopperProductMatrix( \@productPress );

	# 4) Set stackup properties

	$stackup->{"productInputs"} = \@productInputs;

	for ( my $i = 1 ; $i < scalar(@productPress) ; $i++ ) {

		$stackup->{"productPress"}->{$i} = $productPress[ $i - 1 ];
	}

	$stackup->{"copperMatrix"} = \@matrix;

	$stackup->{"pressCount"} = scalar(@productPress);

	$stackup->{"sequentialLam"} = scalar(@productPress) > 1 ? 1 : 0;
}

#-------------------------------------------------------------------------------------------#
#  Build input products
#-------------------------------------------------------------------------------------------#

sub __BuildProductInput {
	my $self = shift;
	my $pars = shift;

	my $stackup = $self->{"stackup"};
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};

	$_->{"pId"} = undef foreach @{$pars};    # Temporary key for identification new product

	# 1) Build input "semi products"
	# Input semi product can by single core or core + one extra copper foil (rigidFlex)
	# Firstly identify produc by core number

	my $currPId = 1;

	$self->__IdentifyRigidFlexProduct( $pars, \$currPId );
	$self->__IdentifyRigidProduct( $pars, \$currPId );
	$self->__IdentifyFlexProduct( $pars, \$currPId );

	# 2) Sort Input product like theare are ordered in Stackup
	my %mapId          = ();
	my $currPIdOrdered = 1;
	foreach my $pLayer ( @{$pars} ) {

		if ( defined $pLayer->{"pId"} && !defined $mapId{ $pLayer->{"pId"} } ) {

			$mapId{ $pLayer->{"pId"} } = $currPIdOrdered;
			$pLayer->{"pId"} = $currPIdOrdered;
			$currPIdOrdered++;

		}
		elsif ( defined $pLayer->{"pId"} && defined $mapId{ $pLayer->{"pId"} } ) {

			$pLayer->{"pId"} = $mapId{ $pLayer->{"pId"} };
		}
	}

	# 3) Replace identified layers by products and create input product structures
	my @products  = ();
	my @producIds = uniq( map { $_->{"pId"} } grep { defined $_->{"pId"} } @{$pars} );
	my $pId       = 1;                                                                   # start identifz Products from 1

	foreach my $pIdOri (@producIds) {

		my @layers = map { $_->{"l"} } grep { $_->{"pId"} eq $pIdOri } @{$pars};
		my @pLayers = ();

		my $pIdChild = 1;
		foreach my $pL (@layers) {

			if ( $pL->GetType() eq Enums->MaterialType_PREPREG
				 || ( $pL->GetType() eq Enums->MaterialType_COPPER && $pL->GetIsFoil() ) )
			{
				# Store to parent input product
				push( @pLayers, ProductLayer->new( Enums->ProductL_MATERIAL, $pL ) );

			}
			elsif ( $pL->GetType() eq Enums->MaterialType_CORE ) {

				# Sotre to nested input product
				my $pChildTopCopper = $pL->GetTopCopperLayer();
				my $pChildBotCopper = $pL->GetBotCopperLayer();

				my @pChildLayers = ();
				push( @pChildLayers, ProductLayer->new( Enums->ProductL_MATERIAL, $pChildTopCopper ) );    # Top core copper
				push( @pChildLayers, ProductLayer->new( Enums->ProductL_MATERIAL, $pL ) );                 # Core
				push( @pChildLayers, ProductLayer->new( Enums->ProductL_MATERIAL, $pChildBotCopper ) );    # Bot core copper

				my @pChildNClayers =
				  grep {
					( $_->{"NCSigStartOrder"} eq $pChildTopCopper->GetCopperNumber() && $_->{"NCSigEndOrder"} eq $pChildBotCopper->GetCopperNumber() )
					  || (    $_->{"NCSigStartOrder"} eq $pChildBotCopper->GetCopperNumber()
						   && $_->{"NCSigEndOrder"} eq $pChildTopCopper->GetCopperName() )
				  } @{ $self->{"NCCore"} };

				my $childProduct = ProductInput->new(
													  $pId . "." . $pIdChild,              $pChildTopCopper->GetCopperName(),
													  $pChildTopCopper->GetCopperNumber(), $pChildBotCopper->GetCopperName(),
													  $pChildBotCopper->GetCopperNumber(), \@pChildLayers,
													  \@pChildNClayers
				);

				push( @pLayers, ProductLayer->new( Enums->ProductL_PRODUCT, $childProduct ) );

				$pIdChild++;
			}
		}

		my $pTopCu = first { $_->GetType() eq Enums->MaterialType_COPPER } @layers;
		my $pBotCu = first { $_->GetType() eq Enums->MaterialType_COPPER } reverse(@layers);

		#		my @pNCPlated = grep {
		#			     $_->{"NCSigStartOrder"} eq $pTopCu->GetCopperNumber()
		#			  || $_->{"NCSigStartOrder"} eq $pBotCu->GetCopperNumber()
		#
		#		} @{$self->{"NCBlind"};

		# Find index where product starts
		my $idx = first_index { $_->{"pId"} eq $pIdOri } @{$pars};

		# Remove product layers
		for ( my $i = scalar( @{$pars} ) - 1 ; $i >= 0 ; $i-- ) {
			splice @{$pars}, $i, 1 if ( $pars->[$i]->{"pId"} eq $pIdOri );
		}

		my $product = ProductInput->new( $pId,
										 $pTopCu->GetCopperName(),
										 $pTopCu->GetCopperNumber(),
										 $pBotCu->GetCopperName(),
										 $pBotCu->GetCopperNumber(),
										 \@pLayers, [] );

		# Insert new product
		splice @{$pars}, $idx, 0, { "l" => $product, "t" => Enums->ProductL_PRODUCT };
		push( @products, $product );

		$pId++;
	}

	delete $_->{"pId"} foreach @{$pars};    # Remove temporary kye

	return @products;

}

# Return extra layer count which will be added to core and create final input product
# Consider input polotovars and its drilling on both side of flexible core (if Rigid flex)
sub __IdentifyRigidFlexProduct {
	my $self      = shift;
	my $pars      = shift;
	my $currPId   = shift;
	my $extraLTop = undef;
	my $extraLBot = undef;

	for ( my $i = 0 ; $i < scalar( @{$pars} ) ; $i++ ) {

		next if ( $pars->[$i]->{"l"}->GetType() ne Enums->MaterialType_CORE );

		my $corePrev = first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } reverse( @{$pars}[ 0 .. ( $i - 1 ) ] );
		my $coreNext = first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } @{$pars}[ ( $i + 1 ) .. scalar( @{$pars} ) - 1 ];

		if (
			 $pars->[$i]->{"l"}->GetCoreRigidType() eq Enums->CoreType_RIGID
			 && (    ( defined $coreNext && $coreNext->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX )
				  || ( defined $corePrev && $corePrev->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) )
		  )
		{

			if ( defined $coreNext && $coreNext->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) {

				my $upToIdx = $i - 1;    # Take core TOP copper by default;
				for ( my $j = $i - 1 ; $j >= 0 ; $j-- ) {

					next if ( $pars->[$j]->{"l"}->GetType() ne Enums->MaterialType_COPPER );

					if ( $pars->[$j]->{"l"}->GetIsFoil() ) {

						# First copper foil indicate end of input products

						$upToIdx = $j;
						last;
					}
					else {

						# First core copper with blind drill indicate end of input products
						my @coreBlindDrill =
						  grep { $_->{"NCSigStartOrder"} eq $pars->[$j]->{"l"}->GetCopperNumber() } @{ $self->{"NCBlind"} };
						if (@coreBlindDrill) {
							$upToIdx = $j;
							last;
						}
					}
				}

				$extraLTop = $i - $upToIdx;
			}

			if ( defined $corePrev && $corePrev->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) {

				my $upToIdx = $i + 1;    # Take core TOP copper by default;
				for ( my $j = $i + 1 ; $j >= 0 ; $j++ ) {

					next if ( $pars->[$j]->{"l"}->GetType() ne Enums->MaterialType_COPPER );

					if ( $pars->[$j]->{"l"}->GetIsFoil() ) {

						# First copper foil indicate end of input products

						$upToIdx = $j;
						last;
					}
					else {

						# First core copper with blind drill indicate end of input products
						my @coreBlindDrill =
						  grep { $_->{"NCSigStartOrder"} eq $pars->[$j]->{"l"}->GetCopperNumber() } @{ $self->{"NCBlind"} };
						if (@coreBlindDrill) {
							$upToIdx = $j;
							last;
						}
					}
				}

				$extraLBot = $upToIdx - $i;
			}
		}
	}

	my $extraL = 0;
	$extraL = $extraLTop if ( defined $extraLTop  && !defined $extraLBot );
	$extraL = $extraLBot if ( !defined $extraLTop && defined $extraLBot );
	$extraL = min( $extraLTop, $extraLBot ) if ( defined $extraLTop && defined $extraLBot );

	for ( my $i = 0 ; $i < scalar( @{$pars} ) ; $i++ ) {

		next if ( $pars->[$i]->{"l"}->GetType() ne Enums->MaterialType_CORE );

		my $corePrev = first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } reverse( @{$pars}[ 0 .. ( $i - 1 ) ] );
		my $coreNext =
		  first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } @{$pars}[ ( $i + 1 ) .. scalar( @{$pars} ) - 1 ];

		if (
			 $pars->[$i]->{"l"}->GetCoreRigidType() eq Enums->CoreType_RIGID
			 && (    ( defined $coreNext && $coreNext->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX )
				  || ( defined $corePrev && $corePrev->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) )
		  )
		{
			my $producPos;

			if ( defined $coreNext && $coreNext->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) {
				$producPos = -1;
			}
			elsif ( defined $corePrev && $corePrev->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) {
				$producPos = 1;
			}

			my $startLIdx = $i + $producPos * $extraL;

			# b) Sign layers frm TOP to BOT until there is not noflow prepreg
			while (1) {

				if (    $pars->[$startLIdx]->{"l"}->GetType() eq Enums->MaterialType_PREPREG
					 && $pars->[$startLIdx]->{"l"}->GetIsNoFlow() )
				{
					last;
				}

				#push( @productL, $pars->[$startLIdx]->{"l"} );
				$pars->[$startLIdx]->{"pId"} = $$currPId;
				$startLIdx -= $producPos * 1;
			}

			$$currPId++;    # increment product id
		}
	}

}

sub __IdentifyRigidProduct {
	my $self      = shift;
	my $pars      = shift;
	my $currPId   = shift;
	my $extraLTop = undef;
	my $extraLBot = undef;

	for ( my $i = 0 ; $i < scalar( @{$pars} ) ; $i++ ) {

		next if ( $pars->[$i]->{"l"}->GetType() ne Enums->MaterialType_CORE );

		# find preview and next core
		my $corePrev = first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } reverse( @{$pars}[ 0 .. ( $i - 1 ) ] );
		my $coreNext =
		  first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } @{$pars}[ ( $i + 1 ) .. scalar( @{$pars} ) - 1 ];

		if (    $pars->[$i]->{"l"}->GetCoreRigidType() eq Enums->CoreType_RIGID
			 && ( !defined $corePrev || $corePrev->{"l"}->GetCoreRigidType() eq Enums->CoreType_RIGID )
			 && ( !defined $coreNext || $coreNext->{"l"}->GetCoreRigidType() eq Enums->CoreType_RIGID ) )
		{

			next if ( defined $pars->[$i]->{"pId"} );    # lowest priority. Core can by included in another product

			# - Rigid core between rigid cores
			$pars->[ $i - 1 ]->{"pId"} = $$currPId;      # copper
			$pars->[$i]->{"pId"}       = $$currPId;      # core
			$pars->[ $i + 1 ]->{"pId"} = $$currPId;      #copper

			$$currPId++;                                 # increment product id

		}
	}

}

sub __IdentifyFlexProduct {
	my $self      = shift;
	my $pars      = shift;
	my $currPId   = shift;
	my $extraLTop = undef;
	my $extraLBot = undef;

	for ( my $i = 0 ; $i < scalar( @{$pars} ) ; $i++ ) {

		next if ( $pars->[$i]->{"l"}->GetType() ne Enums->MaterialType_CORE );

		# find preview and next core
		my $corePrev = first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } reverse( @{$pars}[ 0 .. ( $i - 1 ) ] );
		my $coreNext =
		  first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } @{$pars}[ ( $i + 1 ) .. scalar( @{$pars} ) - 1 ];

		if ( $pars->[$i]->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) {

			# - Flex Core with extra prepregs P1 from both side
			my $P1Top = $pars->[ $i - 2 ];
			my $P1Bot = $pars->[ $i + 2 ];

			if (
				 defined $P1Top
				 && (    $P1Top->{"l"}->GetType() ne Enums->MaterialType_PREPREG
					  || $P1Top->{"l"}->GetNoFlowType() ne Enums->NoFlowPrepreg_P1 )
			  )
			{
				die "Top layer is not NoFlow P1";
			}
			if (
				 defined $P1Bot
				 && (    $P1Top->{"l"}->GetType() ne Enums->MaterialType_PREPREG
					  || $P1Top->{"l"}->GetNoFlowType() ne Enums->NoFlowPrepreg_P1 )
			  )
			{
				die "Bot layer is not NoFlow P1";
			}

			$P1Top->{"pId"} = $$currPId if ( defined $P1Top );    # prepreg is missing at Outer RigidFlex
			$pars->[ $i - 1 ]->{"pId"} = $$currPId;               # copper
			$pars->[$i]->{"pId"}       = $$currPId;               # core
			$pars->[ $i + 1 ]->{"pId"} = $$currPId;               #copper
			$P1Bot->{"pId"} = $$currPId if ( defined $P1Bot );    # prepreg is missing at Outer RigidFlex;

			$$currPId++;                                          # increment product id
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Build press product
#-------------------------------------------------------------------------------------------#

sub __BuildProductPress {
	my $self = shift;
	my $pars = shift;

	my $stackup = $self->{"stackup"};
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};

	my @press      = ();
	my $curPressId = 1;

	while (1) {

		# get top cu of First semi product
		#my $topP = first { defined $_->{"pId"} } @{$pars};
		#my $botP = first { defined $_->{"pId"} } reverse( @{$pars} );

		my $topPIdx = undef;
		my $botPIdx = undef;

		if ( scalar(@press) == 0 ) {

			# 1) Firstly, Create initial press from prduct inputs
			my @inputProducts = map { $_->{"l"} } grep { $_->{"t"} eq Enums->ProductL_PRODUCT } @{$pars};

			# Determine if it is Outer RigidFlex with one flex core on outer side of stackup
			if (
				 ( $inputProducts[0]->GetCoreRigidType() eq Enums->CoreType_FLEX && $inputProducts[-1]->GetCoreRigidType() eq Enums->CoreType_RIGID )
				 || (    $inputProducts[-1]->GetCoreRigidType() eq Enums->CoreType_FLEX
					  && $inputProducts[0]->GetCoreRigidType() eq Enums->CoreType_RIGID )
			  )
			{

				$topPIdx = first_index {
					$_->{"l"} eq Enums->ProductL_PRODUCT && $_->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX
				}
				@{$pars};
				$botPIdx = $topPIdx;

			}
			else {

				# starts from middle of input product list and search wchih input product can be pressed together
				# start from flex core input product list and search wchih input product can be pressed together
				$topPIdx = scalar( @{$pars} ) % 2 != 0 ? ( scalar( @{$pars} ) - 1 ) / 2 - 1 : scalar( @{$pars} ) / 2 - 1;
				$botPIdx = scalar( @{$pars} ) % 2 != 0 ? ( scalar( @{$pars} ) + 1 ) / 2     : scalar( @{$pars} ) / 2;

			}
		}
		else {

			# Start from Product Press
			#$topP = first { defined $_->{"pId"} && $_->GetProductType() eq Enums->Product_PRESS } @{$pars};
			#$botP = $topP;

			$topPIdx =
			  first_index { $_->{"t"} eq Enums->ProductL_PRODUCT && $_->{"l"}->GetProductType() eq Enums->Product_PRESS }
			@{$pars};
			$botPIdx = $topPIdx;
		}

		#		my @NCPlated = grep {
		#			     $_->{"NCSigStartOrder"} eq $pars->[$topPIdx]->{"l"}->GetTopCopperNum()
		#			  || $_->{"NCSigStartOrder"} eq $pars->[$botPIdx]->{"l"}->GetBotCopperNum()
		#
		#		} @NCBlind;

		my $sLIdx = $topPIdx;    # start layer index of prepared press (defaultly it starts on top Cu of top inout product)
		my $eLIdx = $botPIdx;    # end layer index of prepared press (defaultly it starts on bot Cu of bot inout product)

		# Find nearest copper layer OR input Products next by selected "semi products". Search until
		# - If Copper layer is found => create presss
		# - If Input product is found and any blind drilling starts from it => create press
		# - If Input product is found and is located outer at stackup
		while (1) {

			my $search = 0;

			if ( defined $pars->[$sLIdx] ) {

				if (
					 ( $pars->[$sLIdx]->{"t"} eq Enums->ProductL_MATERIAL && $pars->[$sLIdx]->{"l"}->GetType() eq Enums->MaterialType_COPPER )
					 || (    $pars->[$sLIdx]->{"t"} eq Enums->ProductL_PRODUCT
						  && $pars->[$sLIdx]->{"l"}->GetProductType() eq Enums->Product_INPUT
						  && scalar( grep { $_->{"NCSigStartOrder"} eq $pars->[$sLIdx]->{"l"}->GetTopCopperNum() } @{ $self->{"NCBlind"} } ) )
				  )
				{
					last;
				}
			}

			if ( defined $pars->[$eLIdx] ) {

				if (
					( $pars->[$eLIdx]->{"t"} eq Enums->ProductL_MATERIAL && $pars->[$eLIdx]->{"l"}->GetType() eq Enums->MaterialType_COPPER )
					|| (
						   $pars->[$eLIdx]->{"t"} eq Enums->ProductL_PRODUCT
						&& $pars->[$eLIdx]->{"l"}->GetProductType() eq Enums->Product_INPUT
						&& scalar( grep { $_->{"NCSigStartOrder"} eq $pars->[$eLIdx]->{"l"}->GetBotCopperNum() } @{ $self->{"NCBlind"} } )

					)
				  )
				{
					last;
				}
			}

			if ( defined $pars->[ $sLIdx - 1 ] ) {
				$sLIdx--;
				$search = 1;
			}

			if ( defined $pars->[ $eLIdx + 1 ] ) {
				$eLIdx++;
				$search = 1;
			}

			last unless ($search);
		}

		# Build product

		my $pTopCuName  = undef;
		my $pTopCuOrder = undef;
		if ( $pars->[$sLIdx]->{"t"} eq Enums->ProductL_PRODUCT ) {
			$pTopCuName  = $pars->[$sLIdx]->{"l"}->GetTopCopperLayer();
			$pTopCuOrder = $pars->[$sLIdx]->{"l"}->GetTopCopperNum();
		}
		else {
			$pTopCuName  = $pars->[$sLIdx]->{"l"}->GetCopperName();
			$pTopCuOrder = $pars->[$sLIdx]->{"l"}->GetCopperNumber();
		}

		my $pBotCuName  = undef;
		my $pBotCuOrder = undef;
		if ( $pars->[$eLIdx]->{"t"} eq Enums->ProductL_PRODUCT ) {
			$pBotCuName  = $pars->[$eLIdx]->{"l"}->GetBotCopperLayer();
			$pBotCuOrder = $pars->[$eLIdx]->{"l"}->GetBotCopperNum();
		}
		else {
			$pBotCuName  = $pars->[$eLIdx]->{"l"}->GetCopperName();
			$pBotCuOrder = $pars->[$eLIdx]->{"l"}->GetCopperNumber();
		}

		my @pLayers =
		  map { ProductLayer->new( $_->{"t"}, $_->{"l"} ) } ( @{$pars}[ $sLIdx .. $eLIdx ] );

		my @pNCPlated = grep {
			     $_->{"NCSigStartOrder"} eq $pTopCuOrder
			  || $_->{"NCSigStartOrder"} eq $pBotCuOrder

		} @{ $self->{"NCBlind"} };

		#$_->{"pId"} = $curPressId foreach @{$pars}[ $sLIdx .. $eLIdx ];

		my $product = ProductPress->new( $curPressId, $pTopCuName, $pTopCuOrder, $pBotCuName, $pBotCuOrder, \@pLayers, \@pNCPlated );

		$curPressId++;

		# Remove product layers
		splice @{$pars}, $sLIdx, $eLIdx - $sLIdx + 1;

		# Insert new product
		splice @{$pars}, $sLIdx, 0, { "l" => $product, "t" => Enums->ProductL_PRODUCT };
		push( @press, $product );

		# End loop when very top outer and very bottom outer cper are reached/used

		last if ( $pTopCuOrder == 1 && $pBotCuOrder == $stackup->GetCuLayerCnt() );
	}

	#$_->{"pId"} = undef foreach @{$pars};            # Clear key "pId"""

	return @press;
}

#-------------------------------------------------------------------------------------------#
#  Set products additional attributes
#-------------------------------------------------------------------------------------------#

sub __SetProductOuterCore {
	my $self    = shift;
	my $presses = shift;

	foreach my $press ( @{$presses} ) {

		my @l = $press->GetLayers();

		my $topInput = $l[0]->GetData()
		  if (    $l[0]->GetType() eq Enums->ProductL_PRODUCT
			   && $l[0]->GetData()->GetProductType() eq Enums->Product_INPUT );

		my $botInput = $l[-1]->GetData()
		  if (    $l[-1]->GetType() eq Enums->ProductL_PRODUCT
			   && $l[-1]->GetData()->GetProductType() eq Enums->Product_INPUT );

		# If pressing contains Produc input on outer side
		# Check if product input is created from single core without extra cu foil
		if ( $topInput || $botInput ) {

			# If parent input product not contains copper foil
			# Set full TOP coper attribut to child input products (core)
			if (
				 !(
					   ( $topInput->GetLayers() )[0]->GetType() eq Enums->ProductL_MATERIAL
					&& ( $topInput->GetLayers() )[0]->GetData()->GetType() eq Enums->MaterialType_COPPER
				 )
			  )
			{
				( $topInput->GetChildProducts() )[0]->GetData()->SetTopOuterCore(1);

			}

			# If parent input product not contains copper foil
			# Set full BOT coper attribut to child input products (core)
			if (
				 !(
					   ( $botInput->GetLayers() )[-1]->GetType() eq Enums->ProductL_MATERIAL
					&& ( $botInput->GetLayers() )[-1]->GetData()->GetType() eq Enums->MaterialType_COPPER
				 )
			  )
			{
				( $botInput->GetChildProducts() )[-1]->GetData()->SetBotOuterCore(1);

			}

		}
	}
}

sub __SetProductPlugging {
	my $self    = shift;
	my $presses = shift;

	my @products = ();
	$self->__GetAllProducts( $presses->[-1], \@products );

	foreach my $p (@products) {

		my @plugL = grep {
			     $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
			  || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill
		} $p->GetPltNCLayers();

		if ( scalar(@plugL) ) {

			$p->SetPlugging(1);
		}
	}
}

# Layers in matrix are sorted according physical copper layer
# (plus order of exposition) on PCB from TOP to BOT
# Example of order for PCB with outer cores and plugging:
# 1. c
# 2. plgc
# 3. v2
# 4. outer2
# 5. v3
# 6. v4
# 7. outerv5
# 8. v5
# 9. plgs
# 10.s
sub __BuildCopperProductMatrix {
	my $self     = shift;
	my $products = shift;

	my @matrix = ();

	$self->__GenerateCopperProductMatrix( $products->[-1], \@matrix );

	return @matrix;
}

sub __GenerateCopperProductMatrix {
	my $self   = shift;
	my $currP  = shift;
	my $matrix = shift;

	if ( $currP->GetProductType() eq Enums->Product_PRESS ) {

		# Add TOP Press product Copper to matrix
		$self->__AddCopperItems( $currP, Enums->SignalLayer_TOP, $matrix );
	}

	# Process Inpput Products
	foreach my $childP ( map { $_->GetData() } $currP->GetLayers( Enums->ProductL_PRODUCT ) ) {

		$self->__GenerateCopperProductMatrix( $childP, $matrix );
	}

	if ( $currP->GetProductType() eq Enums->Product_INPUT && !$currP->GetIsParent() ) {

		# Add TOP Input product Copper to matrix
		$self->__AddCopperItems( $currP, Enums->SignalLayer_TOP, $matrix );

		# Add BOT Input product Copper to matrix
		$self->__AddCopperItems( $currP, Enums->SignalLayer_BOT, $matrix );

	}

	if ( $currP->GetProductType() eq Enums->Product_PRESS ) {

		# Add BOT Input product Copper to matrix
		$self->__AddCopperItems( $currP, Enums->SignalLayer_BOT, $matrix );
	}
}

sub __AddCopperItems {
	my $self   = shift;
	my $currP  = shift;
	my $side   = shift;
	my $matrix = shift;

	if ( $side eq Enums->SignalLayer_TOP ) {

		if ( !$currP->GetOuterCoreTop() ) {
			push( @{$matrix}, { "name" => $currP->GetTopCopperLayer(), "outerCore" => 0, "plugging" => 0, "product" => $currP } );
		}

		if ( $currP->GetPlugging() ) {
			push( @{$matrix}, { "name" => $currP->GetTopCopperLayer(), "outerCore" => 0, "plugging" => 1, "product" => $currP } );
		}

		if ( $currP->GetOuterCoreTop() ) {
			push( @{$matrix}, { "name" => $currP->GetTopCopperLayer(), "outerCore" => 1, "plugging" => 0, "product" => $currP } );
		}

	}
	elsif ( $side eq Enums->SignalLayer_BOT ) {

		if ( $currP->GetOuterCoreBot() ) {
			push( @{$matrix}, { "name" => $currP->GetBotCopperLayer(), "outerCore" => 1, "plugging" => 0, "product" => $currP } );
		}

		if ( $currP->GetPlugging() ) {
			push( @{$matrix}, { "name" => $currP->GetBotCopperLayer(), "outerCore" => 0, "plugging" => 1, "product" => $currP } );
		}

		if ( !$currP->GetOuterCoreBot() ) {
			push( @{$matrix}, { "name" => $currP->GetBotCopperLayer(), "outerCore" => 0, "plugging" => 0, "product" => $currP } );
		}
	}

}

# Find recursively all products at given press
# Sorted according product nesting (in other words sorted physically according production order)
sub __GetAllProducts {
	my $self        = shift;
	my $currProduct = shift;
	my $pList       = shift;

	my @childProducts = $currProduct->GetLayers( Enums->ProductL_PRODUCT );
	foreach my $childP ( map { $_->GetData() } @childProducts ) {

		$self->__GetAllProducts( $childP, $pList );
	}

	push( @{$pList}, $currProduct );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print 1;
	#my $test = Connectors::HeliosConnector::HegMethods->GetMaterialType("F34140");

	#print $test;

}

1;
