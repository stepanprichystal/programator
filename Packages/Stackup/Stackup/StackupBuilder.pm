#-------------------------------------------------------------------------------------------#
# Description: Core of building multilayer pruduction process and
# building structure of stackup Input and Press products
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Stackup::Stackup::StackupBuilder;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq first_index last_index);
use List::Util qw(first min);
use Storable qw(dclone);

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamJob';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Stackup::StackupBase::Layer::CoverlayLayer';
use aliased 'Packages::Stackup::Stackup::StackupProduct::ProductPress';
use aliased 'Packages::Stackup::Stackup::StackupProduct::ProductInput';
use aliased 'Packages::Stackup::Stackup::StackupProduct::ProductLayer';
use aliased 'Packages::CAMJob::Drilling::DrillChecking::LayerErrorInfo';

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

	my @boardBase = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @NCLayers = CamJob->GetNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	CamDrilling->AddNCLayerType( \@NCLayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );

	$self->{"boardBaseLayers"} = \@boardBase;
	$self->{"NCLayers"}        = \@NCLayers;

	# PROPERTIES

	return $self;

}

sub BuildStackupLamination {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $sigLMatrixCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my $sigLStckpCnt = $self->{"stackup"}->GetCuLayerCnt();

	# Do some elementar check of signal layers and NC layers in matrix

	die "Signal layer cnt in matrix ($sigLMatrixCnt) didn't match witch signal layer cnt in stackup file ($sigLStckpCnt)"
	  if ( $sigLMatrixCnt != $sigLStckpCnt );

	my $NCCheck = 1;
	my $mess    = "";
	$NCCheck = 0 if ( !LayerErrorInfo->CheckWrongNames( $self->{"NCLayers"}, \$mess ) );
	$NCCheck = 0 if ( $NCCheck && !LayerErrorInfo->CheckDirBot2Top( $inCAM, $jobId, $self->{"NCLayers"}, \$mess ) );
	$NCCheck = 0 if ( $NCCheck && !LayerErrorInfo->CheckDirTop2Bot( $inCAM, $jobId, $self->{"NCLayers"}, \$mess ) );

	die "NC layer error: $mess " unless ($NCCheck);

	# 1) Check if there is any covelay in matrix and insert it to stackup layers
	$self->__AddCoverlayLayers();

	# 2) Prepare NC layers, which go through stackup
	my @NCLayers = @{ dclone( $self->{"NCLayers"} ) };

	# Each NC can participate in single product.
	# If they are used by product during build stackup set "usedInProduct" == 1
	$_->{"usedInProduct"} = 0 foreach (@NCLayers);

	CamDrilling->AddNCLayerType( \@NCLayers );
	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@NCLayers );

	# NC layers which influence stackup design
	my @NCAffect = grep { $_->{"plated"} && !$_->{"technical"} } @NCLayers;

	# NC layers which NOT influence stackup design (all NC except @NCInflStackup; coverlay; prepreg; stiffener; score routs)
	my %tmp;
	@tmp{ map { $_->{"gROWname"} } @NCAffect } = ();
	my @NCNoAffect = grep { !exists $tmp{ $_->{"gROWname"} } } @NCLayers;
	@NCNoAffect = grep { defined $_->{"NCSigStartOrder"} } @NCNoAffect;                      # Layers which go through signal layers
	@NCNoAffect = grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_score } @NCNoAffect;

	# 3) Prepare stackup products
	my @parsed = map { { "l" => $_, "t" => Enums->ProductL_MATERIAL } } @{ $self->{"stackup"}->{"layers"} };

	my @productInputs = $self->__BuildProductInput( \@parsed, \@NCAffect, \@NCNoAffect );

	my @productPress = $self->__BuildProductPress( \@parsed, \@NCAffect, \@NCNoAffect );

	# 4) Set attributes plugging; outer core; and

	$self->__SetProductOuterCore( \@productPress );

	$self->__SetProductPlugging( \@productPress );

	$self->__SetProductEmptyFoil( \@productPress );

	# 5) Build searching matrix of products by copper layer

	my @matrix = $self->__BuildCopperProductMatrix( \@productPress );

	# adjust prepreg thickness
	$self->__AdjustPrepregThickness( $productPress[-1], \@matrix );

	# 6) Set stackup properties
	my $stackup = $self->{"stackup"};

	$stackup->{"productInputs"} = \@productInputs;

	for ( my $i = 1 ; $i <= scalar(@productPress) ; $i++ ) {

		$stackup->{"productPress"}->{$i} = $productPress[ $i - 1 ];
	}

	$stackup->{"copperMatrix"} = \@matrix;

	$stackup->{"pressCount"} = scalar(@productPress);

	$stackup->{"sequentialLam"} = scalar(@productPress) > 1 ? 1 : 0;
}

sub __AddCoverlayLayers {
	my $self = shift;

	my $stackup = $self->{"stackup"};
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};

	my @cvrL = grep { $_->{"gROWlayer_type"} eq "coverlay" } CamJob->GetBoardLayers( $inCAM, $jobId );

	return 0 unless (@cvrL);

	my $matInfo = HegMethods->GetPcbCoverlayMat($jobId);

	@cvrL = map { $_->{"gROWname"} } @cvrL;

	for ( my $i = 0 ; $i < scalar(@cvrL) ; $i++ ) {

		my $sigL    = ( $cvrL[$i] =~ /^\w+([csv]\d*)$/ )[0];
		my $cvrlPos = undef;

		foreach my $c ( $stackup->GetAllCores() ) {

			if ( $c->GetTopCopperLayer()->GetCopperName() eq $sigL ) {

				$cvrlPos = "above";
				last;
			}

			if ( $c->GetBotCopperLayer()->GetCopperName() eq $sigL ) {

				$cvrlPos = "below";
				last;
			}
		}

		# Build coverlay layer

		my $layerInfo = CoverlayLayer->new();
		$layerInfo->{"type"} = Enums->MaterialType_COVERLAY;

		my $name     = $matInfo->{"nazev_subjektu"};
		my $thick    = $matInfo->{"vyska"};
		my $thickAdh = $matInfo->{"doplnkovy_rozmer"};
		my $id       = $matInfo->{"dps_id"};
		my $qId      = $matInfo->{"dps_qid"};

		die "Coverlay ($name) thickness is not defined in IS "
		  if ( !defined $thick || $thick eq "" );
		die "Coverlay adhesive ($name) thickness is not defined in IS "
		  if ( !defined $thickAdh || $thickAdh eq "" );
		die "Coverlay ($name) UDA id is not defined in IS " if ( !defined $id || $id eq "" );
		die "Coverlay ($name) UDA qId is not defined in IS "
		  if ( !defined $qId || $qId eq "" );

		$layerInfo->{"thick"}         = $thick * 1000000;
		$layerInfo->{"adhesiveThick"} = $thickAdh * 1000000;
		$layerInfo->{"text"}          = ( $name =~ /LF\s*(\d{4})/i )[0];
		$layerInfo->{"typetext"}      = "Pyralux " . ( $name =~ /Coverlay\s+(\w+)\s*/i )[0];
		$layerInfo->{"method"} =
		  defined( first { $_->{"gROWname"} eq "coverlaypins" } @{ $self->{"boardBaseLayers"} } )
		  ? Enums->Coverlay_SELECTIVE
		  : Enums->Coverlay_FULL;
		$layerInfo->{"id"}  = $id;
		$layerInfo->{"qId"} = $qId;

		my $idx = first_index { $_->GetType() eq Enums->MaterialType_COPPER && $_->GetCopperName() eq $sigL }
		@{ $self->{"stackup"}->{"layers"} };

		if ( $sigL =~ /^[cs]$/ ) {

			# Coverlay is placed on outer side of stackup

			if ( $cvrlPos eq "above" ) {
				splice @{ $self->{"stackup"}->{"layers"} }, $idx, 0, $layerInfo;
			}
			elsif ( $cvrlPos eq "below" ) {
				splice @{ $self->{"stackup"}->{"layers"} }, $idx + 1, 0, $layerInfo;
			}
		}
		else {

			# Coverlay is placed inside stackup

			if ( $layerInfo->{"method"} eq Enums->Coverlay_FULL ) {

				# Put covelray next by core copper
				if ( $cvrlPos eq "above" ) {
					splice @{ $self->{"stackup"}->{"layers"} }, $idx, 0, $layerInfo;
				}
				elsif ( $cvrlPos eq "below" ) {
					splice @{ $self->{"stackup"}->{"layers"} }, $idx + 1, 0, $layerInfo;
				}
			}
			elsif ( $layerInfo->{"method"} eq Enums->Coverlay_SELECTIVE ) {

				# Include coverlay int NoFLow prepreg
				my $prprgIdx = undef;
				if ( $cvrlPos eq "above" ) {
					$prprgIdx = $idx - 1;
				}
				elsif ( $cvrlPos eq "below" ) {
					$prprgIdx = $idx + 1;
				}

				if (
					 !(
						   $self->{"stackup"}->{"layers"}->[$prprgIdx]->GetType() eq Enums->MaterialType_PREPREG
						&& $self->{"stackup"}->{"layers"}->[$prprgIdx]->GetIsNoFlow()
						&& $self->{"stackup"}->{"layers"}->[$prprgIdx]->GetNoFlowType() eq Enums->NoFlowPrepreg_P1
					 )
				  )
				{
					die "Above copper:$sigL has to be NoFlow prepreg type: P1 to include coverlay layer: " . $cvrL[$i];
				}

				$self->{"stackup"}->{"layers"}->[$prprgIdx]->AddCoverlay($layerInfo);
			}

		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Build input products
#-------------------------------------------------------------------------------------------#

sub __BuildProductInput {
	my $self       = shift;
	my $pars       = shift;
	my @NCAffect   = @{ shift(@_) };    # NC layers which influence stackup design
	my @NCNoAffect = @{ shift(@_) };    # NC layers which NOT influence stackup design

	my $stackup = $self->{"stackup"};
	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};

	$_->{"pId"} = undef foreach @{$pars};    # Temporary key for identification new product

	# 1) Build input "semi products"
	# Input semi product can by single core or core + one extra copper foil (rigidFlex)
	# Firstly identify produc by core number

	my $currPId = 1;

	$self->__IdentifyRigidFlexSemiProduct( $pars, \$currPId, \@NCAffect, \@NCNoAffect );
	$self->__IdentifyRigidSemiProduct( $pars, \$currPId, \@NCAffect, \@NCNoAffect );
	$self->__IdentifyRigidCoreProduct( $pars, \$currPId, \@NCAffect, \@NCNoAffect );
	$self->__IdentifyFlexCoreProduct( $pars, \$currPId, \@NCAffect, \@NCNoAffect );

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
	my $pId       = 1;                                                                   # start identify Products from 1

	foreach my $pIdOri (@producIds) {

		my @layers = map { $_->{"l"} } grep { defined $_->{"pId"} && $_->{"pId"} eq $pIdOri } @{$pars};
		my @pLayers = ();

		my $pIdChild = 1;
		foreach my $pL (@layers) {

			if (    $pL->GetType() eq Enums->MaterialType_PREPREG
				 || $pL->GetType() eq Enums->MaterialType_COVERLAY
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

				# Prepare NC which are core + which not influence stackup and start/stop at product
				my @NCCore =
				  grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NCAffect;

				my @pChildNClayers =
				  grep { !$_->{"usedInProduct"} }
				  grep {
					( $_->{"NCSigStartOrder"} eq $pChildTopCopper->GetCopperNumber() && $_->{"NCSigEndOrder"} eq $pChildBotCopper->GetCopperNumber() )
					  || (    $_->{"NCSigStartOrder"} eq $pChildBotCopper->GetCopperNumber()
						   && $_->{"NCSigEndOrder"} eq $pChildTopCopper->GetCopperNumber() )
				  } ( @NCNoAffect, @NCCore );

				$_->{"usedInProduct"} = 1 foreach (@pChildNClayers);

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

		# Find index where product starts
		my $idx = first_index { defined $_->{"pId"} && $_->{"pId"} eq $pIdOri } @{$pars};

		# Remove product layers
		for ( my $i = scalar( @{$pars} ) - 1 ; $i >= 0 ; $i-- ) {

			splice @{$pars}, $i, 1 if ( defined $pars->[$i]->{"pId"} && $pars->[$i]->{"pId"} eq $pIdOri );
		}

		# Prepare NC which are not core and start/stop at product
		my @NCNoCore =
		  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NCAffect;

		my @pNClayers =
		  grep { !$_->{"usedInProduct"} }
		  grep {
			( $_->{"NCSigStartOrder"} eq $pTopCu->GetCopperNumber() && $_->{"NCSigEndOrder"} eq $pTopCu->GetCopperNumber() )
			  || (    $_->{"NCSigStartOrder"} eq $pTopCu->GetCopperNumber()
				   && $_->{"NCSigEndOrder"} eq $pTopCu->GetCopperNumber() )
		  } ( @NCNoAffect, @NCNoCore );

		$_->{"usedInProduct"} = 1 foreach (@pNClayers);

		my $product = ProductInput->new( $pId,
										 $pTopCu->GetCopperName(),
										 $pTopCu->GetCopperNumber(),
										 $pBotCu->GetCopperName(),
										 $pBotCu->GetCopperNumber(),
										 \@pLayers, \@pNClayers );

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
sub __IdentifyRigidFlexSemiProduct {
	my $self     = shift;
	my $pars     = shift;
	my $currPId  = shift;
	my @NCAffect = @{ shift(@_) };    # NC layers which influence stackup design

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
						my @blindDrill =
						  grep { $_->{"NCSigStartOrder"} eq $pars->[$j]->{"l"}->GetCopperNumber() }
						  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cFillDrill }
						  @NCAffect;

						if (@blindDrill) {
							$upToIdx = $j;
							last;
						}
					}
				}

				$extraLTop = $i - $upToIdx;
			}

			if ( defined $corePrev && $corePrev->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) {

				my $upToIdx = $i + 1;    # Take core TOP copper by default;
				for ( my $j = $i + 1 ; $j < scalar( @{$pars} ) ; $j++ ) {

					next if ( $pars->[$j]->{"l"}->GetType() ne Enums->MaterialType_COPPER );

					if ( $pars->[$j]->{"l"}->GetIsFoil() ) {

						# First copper foil indicate end of input products

						$upToIdx = $j;
						last;
					}
					else {

						# First core copper with blind drill indicate end of input products
						my @blindDrill =
						  grep { $_->{"NCSigStartOrder"} eq $pars->[$j]->{"l"}->GetCopperNumber() }
						  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cFillDrill }
						  @NCAffect;
						if (@blindDrill) {
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

# Identifify semi product created by one or more cores + copper foils, defined by plated through (filled) drilling
sub __IdentifyRigidSemiProduct {
	my $self     = shift;
	my $pars     = shift;
	my $currPId  = shift;
	my @NCAffect = @{ shift(@_) };    # NC layers which influence stackup design

	my $extraLTop = undef;
	my $extraLBot = undef;

	my $lCnt = $self->{"stackup"}->GetCuLayerCnt();

	return 0 if ( $lCnt < 8 );        # This type of product is possible at least 8l stackup

	# 1) Identify through (blind drill) inside stackup
	my @blindThrough = grep {
		( $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill || $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill )

		  && (    ( $_->{"NCSigStartOrder"} > 1 && $_->{"NCSigEndOrder"} <= $lCnt / 2 )
			   || ( $_->{"NCSigStartOrder"} >= ( $lCnt / 2 ) + 1 && $_->{"NCSigEndOrder"} <= $lCnt ) )
	} @NCAffect;

	return 0 unless ( scalar(@blindThrough) );    # no drilling which define semi product was find

	# 2) Identify layer which go through the most number of copper layers

	@blindThrough = sort { $a->{"NCSigEndOrder"} - $a->{"NCSigStartOrder"} <=> $b->{"NCSigEndOrder"} - $b->{"NCSigStartOrder"} } @blindThrough;

	# 3) identify which copper layer packages start + end

	# Identify which stackup part TOP/BOT is NC layer located
	my $NC = $blindThrough[0];

	my $topProductSL = undef;
	my $topProductEL = undef;

	my $botProductSL = undef;
	my $botProductEL = undef;

	if ( $NC->{"NCSigStartOrder"} < $lCnt / 2 ) {

		#top half stackup
		$topProductSL = $NC->{"NCSigStartOrder"};
		$topProductEL = $NC->{"NCSigEndOrder"};

		#bot half stackup
		$botProductSL = $lCnt - $topProductEL + 1;
		$botProductEL = $lCnt - $topProductSL + 1;
	}
	else {

		#top half stackup
		$botProductSL = $NC->{"NCSigStartOrder"};
		$botProductEL = $NC->{"NCSigEndOrder"};

		#bot half stackup
		$topProductSL = $lCnt - $botProductEL + 1;
		$topProductEL = $lCnt - $botProductSL + 1;
	}

	# set top product
	my $topProductSIdx =
	  first_index { $_->{"l"}->GetType() eq Enums->MaterialType_COPPER && $_->{"l"}->GetCopperNumber() eq $topProductSL } @{$pars};
	my $topProductEIdx =
	  first_index { $_->{"l"}->GetType() eq Enums->MaterialType_COPPER && $_->{"l"}->GetCopperNumber() eq $topProductEL } @{$pars};

	for ( my $i = $topProductSIdx ; $i <= $topProductEIdx ; $i++ ) {

		$pars->[$i]->{"pId"} = $$currPId;
	}

	$$currPId++;

	# set bot product
	my $botProductSIdx =
	  first_index { $_->{"l"}->GetType() eq Enums->MaterialType_COPPER && $_->{"l"}->GetCopperNumber() eq $botProductSL } @{$pars};
	my $botProductEIdx =
	  first_index { $_->{"l"}->GetType() eq Enums->MaterialType_COPPER && $_->{"l"}->GetCopperNumber() eq $botProductEL } @{$pars};

	for ( my $i = $botProductSIdx ; $i <= $botProductEIdx ; $i++ ) {

		$pars->[$i]->{"pId"} = $$currPId;
	}

	$$currPId++;

}

sub __IdentifyRigidCoreProduct {
	my $self     = shift;
	my $pars     = shift;
	my $currPId  = shift;
	my @NCAffect = @{ shift(@_) };    # NC layers which influence stackup design

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

sub __IdentifyFlexCoreProduct {
	my $self     = shift;
	my $pars     = shift;
	my $currPId  = shift;
	my @NCAffect = @{ shift(@_) };                       # NC layers which influence stackup design

	my $extraLTop = undef;
	my $extraLBot = undef;

	for ( my $i = 0 ; $i < scalar( @{$pars} ) ; $i++ ) {

		next if ( $pars->[$i]->{"l"}->GetType() ne Enums->MaterialType_CORE );

		# find preview and next core
		my $corePrev = first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } reverse( @{$pars}[ 0 .. ( $i - 1 ) ] );
		my $coreNext =
		  first { $_->{"l"}->GetType() eq Enums->MaterialType_CORE } @{$pars}[ ( $i + 1 ) .. scalar( @{$pars} ) - 1 ];

		if ( $pars->[$i]->{"l"}->GetCoreRigidType() eq Enums->CoreType_FLEX ) {

			# - Flex Core with extra prepregs P1 from both side (or coverlay from one side and prepreg from other side)
			my $P1Top = $i - 2 >= 0 ? $pars->[ $i - 2 ] : undef;
			my $P1Bot = $i + 2 < scalar( @{$pars} ) ? $pars->[ $i + 2 ] : undef;

			if (
				 defined $P1Top
				 && (    $P1Top->{"l"}->GetType() ne Enums->MaterialType_PREPREG
					  || $P1Top->{"l"}->GetNoFlowType() ne Enums->NoFlowPrepreg_P1 )
				 && $P1Top->{"l"}->GetType() ne Enums->MaterialType_COVERLAY
			  )
			{
				die "Top layer is not NoFlow P1";
			}
			if (
				 defined $P1Bot
				 && (    $P1Bot->{"l"}->GetType() ne Enums->MaterialType_PREPREG
					  || $P1Bot->{"l"}->GetNoFlowType() ne Enums->NoFlowPrepreg_P1 )
				 && $P1Bot->{"l"}->GetType() ne Enums->MaterialType_COVERLAY
			  )
			{
				die "Bot layer is not NoFlow P1";
			}
			$P1Top->{"pId"} = $$currPId if ( defined $P1Top );    # prepreg can missing when Outer RigidFlex (if flex core is placed top)

			$pars->[ $i - 1 ]->{"pId"} = $$currPId;               # copper
			$pars->[$i]->{"pId"}       = $$currPId;               # core
			$pars->[ $i + 1 ]->{"pId"} = $$currPId;               # copper
			$P1Bot->{"pId"} = $$currPId if ( defined $P1Bot );    # prepreg is missing when Outer RigidFlex (if flex core is placed bottom);

			$$currPId++;                                          # increment product id
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Build press product
#-------------------------------------------------------------------------------------------#

sub __BuildProductPress {
	my $self       = shift;
	my $pars       = shift;
	my @NCAffect   = @{ shift(@_) };    # NC layers which influence stackup design
	my @NCNoAffect = @{ shift(@_) };    # NC layers which NOT influence stackup design

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
					$_->{"t"} eq Enums->ProductL_PRODUCT
				}
				@{$pars};
				$botPIdx = last_index {
					$_->{"t"} eq Enums->ProductL_PRODUCT
				}
				@{$pars};

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

				if ( $pars->[$sLIdx]->{"t"} eq Enums->ProductL_MATERIAL && $pars->[$sLIdx]->{"l"}->GetType() eq Enums->MaterialType_COPPER ) {
					last;
				}

				if (    $pars->[$sLIdx]->{"t"} eq Enums->ProductL_PRODUCT
					 && $pars->[$sLIdx]->{"l"}->GetProductType() eq Enums->Product_INPUT )
				{
					my $pInput = $pars->[$sLIdx]->{"l"};
					my @NC =
					  grep { !$_->{"usedInProduct"} && $_->{"NCSigStartOrder"} eq $pInput->GetTopCopperNum() }
					  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NCAffect;

					last if ( scalar(@NC) );
				}

			}

			if ( defined $pars->[$eLIdx] ) {

				if ( $pars->[$eLIdx]->{"t"} eq Enums->ProductL_MATERIAL && $pars->[$eLIdx]->{"l"}->GetType() eq Enums->MaterialType_COPPER ) {
					last;
				}

				if (    $pars->[$eLIdx]->{"t"} eq Enums->ProductL_PRODUCT
					 && $pars->[$eLIdx]->{"l"}->GetProductType() eq Enums->Product_INPUT )
				{
					my $pInput = $pars->[$eLIdx]->{"l"};
					my @NC =
					  grep { !$_->{"usedInProduct"} && $_->{"NCSigStartOrder"} eq $pInput->GetBotCopperNum() }
					  grep { $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cDrill && $_->{"type"} ne EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NCAffect;

					last if ( scalar(@NC) );
				}

				if ( $sLIdx - 1 >= 0 ) {
					$sLIdx--;
					$search = 1;
				}

				if ( $eLIdx + 1 < scalar( @{$pars} ) ) {
					$eLIdx++;
					$search = 1;
				}
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

		my @pExtraPressLayers = ();

		# Exception for pressing more flexocore together, which has laminated prepreg on outer side
		# OR if there is extra coverlay pressing
		if (
			 $pLayers[0]->GetType() eq Enums->ProductL_PRODUCT
			 && (    $pLayers[0]->GetData()->GetProductOuterMatLayer("first")->GetData()->GetType() eq Enums->MaterialType_PREPREG
				  || $pLayers[0]->GetData()->GetProductOuterMatLayer("first")->GetData()->GetType() eq Enums->MaterialType_COVERLAY )
		  )
		{
			# if Input products contains prepreg on outer, move it to this press and mark as "extra press layers"
			my $topL = $pLayers[0]->GetData()->RemoveProductOuterMatLayer("first");
			unshift @pLayers, $topL;

			push( @pExtraPressLayers, $topL );
		}

		# Exception for pressing more flexocore together, which has laminated prepreg on outer side
		# OR if there is extra coverlay pressing
		if (
			 $pLayers[0]->GetType() eq Enums->ProductL_PRODUCT
			 && (    $pLayers[-1]->GetData()->GetProductOuterMatLayer("last")->GetData()->GetType() eq Enums->MaterialType_PREPREG
				  || $pLayers[-1]->GetData()->GetProductOuterMatLayer("last")->GetData()->GetType() eq Enums->MaterialType_COVERLAY )
		  )
		{

			# if Input products contains prepreg on outer, move it to this press and mark as "extra press layers"
			my $botL = $pLayers[-1]->GetData()->RemoveProductOuterMatLayer("last");
			push( @pLayers, $botL );

			push( @pExtraPressLayers, $botL );
		}

		# Check if extra layers (coverlay) left after last pressing
		#		if ( $pTopCuOrder == 1 && $pBotCuOrder == $stackup->GetCuLayerCnt() ) {
		#
		#			if ( $sLIdx > 0 ) {
		#
		#				my @extraPressL = map { ProductLayer->new( $_->{"t"}, $_->{"l"} ) } @{$pars}[ 0 .. $sLIdx - 1 ];
		#				unshift( @pLayers, @extraPressL );
		#				push( @pExtraPressLayers, @extraPressL );
		#			}
		#
		#			if ( $eLIdx < scalar( @{$pars} ) ) {
		#
		#				my @extraPressL = map { ProductLayer->new( $_->{"t"}, $_->{"l"} ) } @{$pars}[ $eLIdx + 1 .. scalar( @{$pars} ) - 1 ];
		#				push( @pLayers,           @extraPressL );
		#				push( @pExtraPressLayers, @extraPressL );
		#			}
		#
		#		}

		# Prepare product NC layers
		my @pNC =
		  grep { !$_->{"usedInProduct"} }
		  grep { $_->{"NCSigStartOrder"} eq $pTopCuOrder || $_->{"NCSigStartOrder"} eq $pBotCuOrder } ( @NCAffect, @NCNoAffect );

		$_->{"usedInProduct"} = 1 foreach (@pNC);

		my $product = ProductPress->new( $curPressId, $pTopCuName, $pTopCuOrder, $pBotCuName, $pBotCuOrder, \@pLayers, \@pNC );
		$product->AddExtraPressLayers( \@pExtraPressLayers ) if ( scalar(@pExtraPressLayers) );

		$curPressId++;

		# Remove product layers
		splice @{$pars}, $sLIdx, $eLIdx - $sLIdx + 1;

		# Insert new product
		splice @{$pars}, $sLIdx, 0, { "l" => $product, "t" => Enums->ProductL_PRODUCT };
		push( @press, $product );

		# End loop when very top outer and very bottom outer Cu are reached/used

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

		# Check if there are product inputs on outer sides of press package
		# (warning: sometimes there can be noflow prepreg or coverlay very outer on press package then skip prepregs)
		my $topIdx = $l[0]->GetType() eq Enums->ProductL_MATERIAL
		  && $l[0]->GetData()->GetType() ne Enums->MaterialType_COPPER ? 1 : 0;
		my $botIdx = $l[-1]->GetType() eq Enums->ProductL_MATERIAL
		  && $l[-1]->GetData()->GetType() ne Enums->MaterialType_COPPER ? -2 : -1;

		my $topInput = $l[$topIdx]->GetData()
		  if (    $l[$topIdx]->GetType() eq Enums->ProductL_PRODUCT
			   && $l[$topIdx]->GetData()->GetProductType() eq Enums->Product_INPUT );

		my $botInput = $l[$botIdx]->GetData()
		  if (    $l[$botIdx]->GetType() eq Enums->ProductL_PRODUCT
			   && $l[$botIdx]->GetData()->GetProductType() eq Enums->Product_INPUT );

		# If pressing contains Produc input on outer side
		# Check if product input is created from single core without extra cu foil
		if ( $topInput || $botInput ) {

			# If parent input product not contains copper foil
			# Set full TOP coper attribut to parent and child input products (core)
			my $topMat = $topInput->GetProductOuterMatLayer("first")->GetData();

			if ( $topMat->GetType() eq Enums->MaterialType_COPPER && !$topMat->GetIsFoil() ) {
				$topInput->SetTopOuterCore(1);
				( $topInput->GetChildProducts() )[0]->GetData()->SetTopOuterCore(1);
			}

			#			}

			# If parent input product not contains copper foil
			# Set full BOT coper attribut to parent and child input products (core)

			my $botMat = $botInput->GetProductOuterMatLayer("last")->GetData();

			if ( $botMat->GetType() eq Enums->MaterialType_COPPER && !$botMat->GetIsFoil() ) {
				$botInput->SetBotOuterCore(1);
				( $botInput->GetChildProducts() )[-1]->GetData()->SetBotOuterCore(1);
			}

			#			}

		}
	}
}

# Set flag, coper foil in parent input product is not "exposed" during semi product production
# But is exposed afterwards pressing this semiproduct with another semiproduct
sub __SetProductEmptyFoil {
	my $self         = shift;
	my $productPress = shift;

	foreach my $productPress ( @{$productPress} ) {

		my @lAll   = $productPress->GetLayers();
		my @lPrduc = $productPress->GetLayers( Enums->ProductL_PRODUCT );

		next unless ( scalar(@lPrduc) );

		my $firstProducL = ( $lPrduc[0]->GetData()->GetLayers() )[0];

		if ( $firstProducL->GetType() eq Enums->ProductL_MATERIAL && $firstProducL->GetData()->GetType() eq Enums->MaterialType_COPPER ) {

			# Check if first nested product has same top copper as parent product
			if ( $lPrduc[0]->GetData()->GetTopCopperLayer() eq $productPress->GetTopCopperLayer() ) {
				$lPrduc[0]->GetData()->SetTopEmptyFoil(1);
			}
		}

		my $lastProducL = ( $lPrduc[-1]->GetData()->GetLayers() )[-1];

		if ( $lastProducL->GetType() eq Enums->ProductL_MATERIAL && $lastProducL->GetData()->GetType() eq Enums->MaterialType_COPPER ) {

			# Check if first nested product has same top copper as parent product
			if ( $lPrduc[-1]->GetData()->GetBotCopperLayer() eq $productPress->GetBotCopperLayer() ) {
				$lPrduc[-1]->GetData()->SetBotEmptyFoil(1);
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

# Computation of prepreg thickness depending on Cu ussage and Cu extra plating
sub __AdjustPrepregThickness {
	my $self       = shift;
	my $curProduct = shift;
	my $matrix     = shift;

	my @layers = $curProduct->GetLayers();

	for ( my $i = 0 ; $i < scalar( scalar(@layers) ) ; $i++ ) {

		if ( $layers[$i]->GetType() eq Enums->ProductL_PRODUCT ) {

			$self->__AdjustPrepregThickness( $layers[$i]->GetData(), $matrix );
		}

		elsif (    $layers[$i]->GetType() eq Enums->ProductL_MATERIAL
				&& $layers[$i]->GetData()->GetType() eq Enums->MaterialType_PREPREG )
		{

			# Get TOP  layer next by prepreg

			my $topPL        = undef;    # Product layer
			my $topPLSourceP = -1;       # Source product of product layer
			if ( $i - 1 >= 0 && $layers[ $i - 1 ]->GetType() eq Enums->ProductL_MATERIAL ) {
				$topPL        = $layers[ $i - 1 ];
				$topPLSourceP = $curProduct;
			}
			elsif ( $i - 1 >= 0 && $layers[ $i - 1 ]->GetType() eq Enums->ProductL_PRODUCT ) {
				$topPL        = $layers[ $i - 1 ]->GetData()->GetProductOuterMatLayer("last");
				$topPLSourceP = $layers[ $i - 1 ]->GetData();

			}

			my $topCopper = undef;

			# Consider only copper which is core copper (not  foil only copper). Because in time of pressing above copper foil
			#  is not eteched, thus no change of prepreg thickness due to copper foil ussage
			if ( defined $topPL && $topPL->GetData()->GetType() eq Enums->MaterialType_COPPER && !$topPL->GetData()->GetIsFoil() ) {

				$topCopper = $topPL->GetData();
			}

			# Get BOT  layer next by prepreg

			my $botPL        = undef;    # Product layer
			my $botPLSourceP = -1;       # Source product of product layer
			if ( $i + 1 < scalar(@layers) && $layers[ $i + 1 ]->GetType() eq Enums->ProductL_MATERIAL ) {
				$botPL        = $layers[ $i + 1 ];
				$botPLSourceP = $curProduct;
			}
			elsif ( $i + 1 < scalar(@layers) && $layers[ $i + 1 ]->GetType() eq Enums->ProductL_PRODUCT ) {
				$botPL        = $layers[ $i + 1 ]->GetData()->GetProductOuterMatLayer("first");
				$botPLSourceP = $layers[ $i + 1 ]->GetData();
			}

			my $botCopper = undef;

			# Consider all copper (core copper and only foil copper), because copper is already etched
			if ( defined $botPL && $botPL->GetData()->GetType() eq Enums->MaterialType_COPPER ) {

				$botCopper = $botPL->GetData();
			}

			#Theoretical calculation for one prepreg and two Cu is:
			# Thick = height(prepreg) - (height(topCu* (1-UsageInPer(topCu))  +   height(botCu* (1-UsageInPer(topCu)))
			my $thick = $layers[$i]->GetData()->GetThick();
			if ($topCopper) {

				my $plating = scalar( grep { $_->{"name"} eq $topCopper->GetCopperName() && $_->{"product"}->GetIsPlated() } @{$matrix} );

				$thick -= ( $topCopper->GetThick() + ( $plating ? Enums->Plating_STD : 0 ) ) * ( 1 - $topCopper->GetUssage() );
			}

			if ($botCopper) {

				my $plating = scalar( grep { $_->{"name"} eq $botCopper->GetCopperName() && $_->{"product"}->GetIsPlated() } @{$matrix} );

				$thick -= ( $botCopper->GetThick() + ( $plating ? Enums->Plating_STD : 0 ) ) * ( 1 - $botCopper->GetUssage() );
			}

			$layers[$i]->GetData()->SetThickCuUsage($thick);

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

	my $cuLCnt =
	  scalar( grep { $_->GetType() eq Enums->ProductL_MATERIAL && $_->GetData()->GetType() eq Enums->MaterialType_COPPER } $currP->GetLayers() );

	# Add TOP Press product Copper to matrix
	if ( !( $currP->GetProductType() eq Enums->Product_INPUT && ( $cuLCnt == 0 || $currP->GetTopEmptyFoil() || $currP->GetBotEmptyFoil() ) ) ) {
		$self->__AddCopperItems( $currP, Enums->SignalLayer_TOP, $matrix );
	}

	# Process Inpput Products
	foreach my $childP ( map { $_->GetData() } $currP->GetLayers( Enums->ProductL_PRODUCT ) ) {

		$self->__GenerateCopperProductMatrix( $childP, $matrix );
	}

	# Add BOT Input product Copper to matrix
	if ( !( $currP->GetProductType() eq Enums->Product_INPUT && ( $cuLCnt == 0 || $currP->GetTopEmptyFoil() || $currP->GetBotEmptyFoil() ) ) ) {
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
