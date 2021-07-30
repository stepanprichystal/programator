
#-------------------------------------------------------------------------------------------#
# Description: Class is responsible for creating panel profile
# Import/Export settings method are meant for using class in bacground
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::SchemePnlCreator::SchemeCreatorBase;
use base('Programs::Panelisation::PnlCreator::PnlCreatorBase');

#3th party library
use strict;
use warnings;
use List::Util qw(first);
use File::Basename;

#local library
use aliased 'Programs::Panelisation::PnlCreator::Enums';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::Other::CustomerNote';
use aliased 'Enums::EnumsCAM';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Packages::Stackup::StackupBase::StackupBase';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $jobId   = shift;
	my $pnlType = shift;
	my $key     = shift;

	my $self = $class->SUPER::new( $jobId, $pnlType, $key );
	bless $self;

	# Setting values
	$self->{"settings"}->{"stdSchemeList"}       = [];
	$self->{"settings"}->{"specSchemeList"}      = [];
	$self->{"settings"}->{"schemeType"}          = undef;
	$self->{"settings"}->{"scheme"}              = undef;    # standard/special
	$self->{"settings"}->{"signalLayerSpecFill"} = {};

	return $self;                                            #
}

#-------------------------------------------------------------------------------------------#
# Interface method
#-------------------------------------------------------------------------------------------#

# Init creator class in order process panelisation
# (instead of Init method is possible init by import JSON settings)
# Return 1 if succes 0 if fail
sub _Init {
	my $self     = shift;
	my $inCAM    = shift;
	my $stepName = shift;

	my $jobId = $self->{"jobId"};

	my $result = 1;

	my $layerCnt  = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	my $pSch      = EnumsPaths->InCAM_server . "\\site_data\\library\\panel_schemes\\";
	my @allScheme = map { basename($_) } grep { $_ =~ /^\w/ } glob( $pSch . '/*' );

	my @stdSchemes  = ();
	my @specSchemes = ();
	my $schemeType  = "standard";
	my $scheme      = undef;

	$self->SetStep($stepName);

	if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

		# Get standard schemes - customers

		my $custInfo = HegMethods->GetCustomerInfo($jobId);
		my $custNote = CustomerNote->new( $custInfo->{"reference_subjektu"} );

		my @custSchemes = $custNote->RequiredSchemas();

		if ( scalar(@custSchemes) ) {

			# Filter schemes by cust scheme
			my @cust = ();

			foreach my $custScheme (@custSchemes) {
				my @s = grep { $_ =~ /^$custScheme/ } @allScheme;
				push( @cust, @s ) if ( scalar(@s) );
			}

			push( @stdSchemes, @cust ) if ( scalar(@cust) );
		}

		# Get special scheme for customers
		my @spec = grep { $_ =~ /^mpanel/ } @allScheme;
		push( @specSchemes, @spec ) if ( scalar(@spec) );

		# Set default type
		if ( scalar(@stdSchemes) > 0 ) {

			$schemeType = "standard";
		}
		else {

			$schemeType = "special";
		}

		# Set default scheme
		if ( scalar(@stdSchemes) > 0 ) {

			$scheme = $stdSchemes[0];
		}
		else {

			$scheme = $specSchemes[0];
		}

	}
	elsif ( $self->GetPnlType() eq Enums->PnlType_PRODUCTIONPNL ) {

		# Get standard schemes - customers

		my $matKind      = HegMethods->GetMaterialKind($jobId);
		my $isSemiHybrid = 0;
		my $isHybrid     = JobHelper->GetIsHybridMat( $jobId, $matKind, [], \$isSemiHybrid );
		my $isFlex       = JobHelper->GetIsFlex($jobId);

		my $pcbLayerCntStr = $layerCnt > 2 ? "vv" : "2v";
		my $pcbMatTypeStr = undef;

		if ($isSemiHybrid) {

			# Exception 1 -  if multilayer + coverlay, return hybrid
			if ( $layerCnt > 2 ) {

				$pcbMatTypeStr = "hybrid";
			}

			# Exception 2 -  if doublesided layer + coverlay, return flex
			if ( $layerCnt <= 2 ) {

				$pcbMatTypeStr = "flex";
			}

		}
		elsif ($isHybrid) {

			$pcbMatTypeStr = "hybrid";

		}
		elsif ( $isFlex ) {

			$pcbMatTypeStr = "flex";

		}
		else {

			$pcbMatTypeStr = "rigid";
		}

		my $schemeStr = "${pcbMatTypeStr}_${pcbLayerCntStr}";
		my @std = grep { $_ =~ /^$schemeStr/ } @allScheme;
		push( @stdSchemes, @std ) if ( scalar(@std) );

		# Set default type

		$schemeType = "standard";

		# Set default scheme
		
		$scheme = $stdSchemes[0];

	}

	$self->SetStdSchemeList( \@stdSchemes );
	$self->SetSpecSchemeList( \@specSchemes );
	$self->SetSchemeType($schemeType);
	$self->SetScheme($scheme);

	# Set inner layer settings

	my %sigLayerFill = ();
	my @outer        = CamJob->GetSignalLayerNames( $inCAM, $jobId, 0, 1 );
	my @inner        = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1, 0 );

	# Outer layer

	my @stiff = grep { $_->{"gROWlayer_type"} eq "stiffener" } CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	foreach my $layer (@outer) {

		my $specAttr = EnumsCAM->AttSpecLayerFill_NONE;    # Default no special pattern

		if ( $self->GetPnlType() eq Enums->PnlType_CUSTOMERPNL ) {

			if ( defined( first { $_->{"gROWname"} =~ /$layer/ } @stiff ) ) {

				$specAttr = EnumsCAM->AttSpecLayerFill_EMPTY;
			}
		}

		$sigLayerFill{$layer} = $specAttr;
	}

	# Inner layers
	if ( scalar(@inner) ) {

		# Temporary - if stackup do'nt exist set all layers to non special fill
		unless ( JobHelper->StackupExist( $self->{"jobId"} ) ) {

			my @inLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1 );

			foreach my $in (@inLayers) {

				$sigLayerFill{$in} = EnumsCAM->AttSpecLayerFill_NONE;
			}

		}
		else {

			my $stackup = Stackup->new( $inCAM, $jobId );

			my @inner =
			  grep { $_->GetType() eq StackEnums->MaterialType_COPPER && !$_->GetIsFoil() && $_->GetCopperName() =~ /^v\d+/ }
			  $stackup->GetAllLayers();

			foreach my $cuLayer (@inner) {

				my $core     = $stackup->GetCoreByCuLayer( $cuLayer->GetCopperName() );
				my %lPars    = JobHelper->ParseSignalLayerName( $cuLayer->GetCopperName() );
				my $IProduct = $stackup->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

				my $specAttr = EnumsCAM->AttSpecLayerFill_NONE;    # Default no special pattern

				if ( $cuLayer->GetUssage() == 0 ) {

					$specAttr = EnumsCAM->AttSpecLayerFill_EMPTY;

				}
				elsif ( $cuLayer->GetUssage() > 0 && $core->GetCoreRigidType() eq StackEnums->CoreType_FLEX ) {

					$specAttr = EnumsCAM->AttSpecLayerFill_SOLID100PCT;

				}
				elsif ( ( $cuLayer->GetThick() >= 35 && $IProduct->GetIsPlated() )
						|| $cuLayer->GetThick() >= 70 )
				{
					# Case when thick base Cu
					$specAttr = EnumsCAM->AttSpecLayerFill_CIRCLE80PCT;

				}

				$sigLayerFill{ $cuLayer->GetCopperName() } = $specAttr;
			}
		}
	}

	$self->SetSignalLayerSpecFill( \%sigLayerFill );

	return $result;

}

# Do necessary check before processing panelisation
# This method is called always before Process method
# Return 1 if succes 0 if fail
sub _Check {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $jobId  = $self->{"jobId"};
	my $result = 1;

	# Check if schema is defined
	my $scheme = $self->GetScheme();

	if ( !defined $scheme || $scheme eq "" ) {

		$result = 0;
		$$errMess .= "Panel scheme is not defined.";
	}

	# Check if special fill is defined

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
	if ( $layerCnt > 2 ) {

		my @inLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId, 1 );
		my %specFill = %{ $self->GetSignalLayerSpecFill() };

		foreach my $layerName (@inLayers) {

			if ( !defined $specFill{$layerName} || $specFill{$layerName} eq "" ) {

				$result = 0;
				$$errMess .= "Special panel fill is not defined for inner layer: ${layerName}";
			}
		}
	}

	return $result;

}

# Return 1 if succes 0 if fail
sub _Process {
	my $self    = shift;
	my $inCAM   = shift;
	my $errMess = shift;    # reference to err message

	my $result = 1;

	my $jobId = $self->{"jobId"};
	my $step  = $self->GetStep();

	# 1) Set special inner layer
	my %specFill = %{ $self->GetSignalLayerSpecFill() };

	foreach my $layerName ( keys %specFill ) {

		CamAttributes->SetLayerAttribute( $inCAM, "spec_layer_fill", $specFill{$layerName}, $jobId, $step, $layerName );
	}

	# 2) Run schema

	# Set attributes regarding layer side

	my @sigLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	my $stackup = undef;

	if ( scalar(@sigLayers) > 2 ) {

		$stackup = Stackup->new( $inCAM, $jobId );
	}

	foreach my $layer (@sigLayers) {

		my $side = undef;

		if ( $layer =~ /c/ ) {
			$side = "top";
		}
		elsif ( $layer =~ /s/ ) {
			$side = "bot";
		}
		elsif ( $layer =~ /^v\d+$/ ) {

			my $IProduct = $stackup->GetProductByLayer( $layer, 0, 0 );

			if ( $layer eq $IProduct->GetTopCopperLayer() ) {
				$side = "top";
			}
			else {
				$side = "bot";
			}
		}

		CamAttributes->SetLayerAttribute( $inCAM, "layer_side", $side, $jobId, $step, $layer );
		CamAttributes->SetLayerAttribute( $inCAM, ".cdr_mirror", ( $side eq "top" ? "no" : "yes" ), $jobId, $step, $layer );

	}

	my $nestedStep = undef;
	my @childs = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $step );

	# prioritize mpanel/o+1
	my $mpanel = first { $_->{"stepName"} eq "mpanel" } @childs;
	if ($mpanel) {
		$nestedStep = "mpanel";
	}
	else {
		my $o1 = first { $_->{"stepName"} eq "o+1" } @childs;
		if ($o1) {
			$nestedStep = "o+1";
		}
		else {

			die "Panel doesn't contain proper nested step (mpanel or o+1)";
		}
	}

	$inCAM->COM( 'autopan_run_scheme', "job" => $jobId, "panel" => $step, "pcb" => $nestedStep, "scheme" => $self->GetScheme() );

	return $result;
}

#-------------------------------------------------------------------------------------------#
# Get/Set method for adjusting settings after Init/ImportSetting
#-------------------------------------------------------------------------------------------#

sub SetStdSchemeList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"stdSchemeList"} = $val;

}

sub GetStdSchemeList {
	my $self = shift;

	return $self->{"settings"}->{"stdSchemeList"};

}

sub SetSpecSchemeList {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"specSchemeList"} = $val;

}

sub GetSpecSchemeList {
	my $self = shift;

	return $self->{"settings"}->{"specSchemeList"};

}

sub SetSchemeType {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"schemeType"} = $val;

}

sub GetSchemeType {
	my $self = shift;

	return $self->{"settings"}->{"schemeType"};

}

sub SetScheme {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"scheme"} = $val;

}

sub GetScheme {
	my $self = shift;

	return $self->{"settings"}->{"scheme"};

}

sub SetSignalLayerSpecFill {
	my $self = shift;
	my $val  = shift;

	$self->{"settings"}->{"signalLayerSpecFill"} = $val;

}

sub GetSignalLayerSpecFill {
	my $self = shift;

	return $self->{"settings"}->{"signalLayerSpecFill"};

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

