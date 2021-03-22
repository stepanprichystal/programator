#-------------------------------------------------------------------------------------------#
# Description: Return information about material stability
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Technology::DataComp::SigLayerComp;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Technology::DataComp::PanelComp::PanelComp';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift // 'panel';

	# PROPERTY

	$self->{"inCAM"}    = $inCAM;
	$self->{"jobId"}    = $jobId;
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackup"} = Stackup->new( $inCAM, $jobId );
	}

	$self->{"panelComp"} = PanelComp->new( $inCAM, $jobId, $step, $self->{"stackup"} );

	return $self;
}

sub GetLayerCompensation {
	my $self     = shift;
	my $sigLayer = shift;

	my %comp = ( "x" => undef, "y" => undef );

	if ( $self->{"layerCnt"} > 2 ) {
		%comp = $self->__GetCompensationVV($sigLayer);

	}
	else {

		%comp = $self->__GetCompensation2V($sigLayer);

	}

	$comp{"x"} = sprintf( "%.3f", $comp{"x"} );
	$comp{"y"} = sprintf( "%.3f", $comp{"y"} );

	return %comp;
}

sub __GetCompensation2V {
	my $self     = shift;
	my $sigLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %comp = $self->{"panelComp"}->GetBaseMatComp();

	return %comp;
}

sub __GetCompensationVV {
	my $self     = shift;
	my $sigLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %comp = ( "x" => undef, "y" => undef );

	my $coreNum     = undef;
	my $coreMatKind = undef;

	my %lPars = JobHelper->ParseSignalLayerName($sigLayer);
	my $product = $self->{"stackup"}->GetProductByLayer( $lPars{"sourceName"}, $lPars{"outerCore"}, $lPars{"plugging"} );

	if ( $product->GetProductType() eq StackEnums->Product_INPUT ) {

		my $p = $product->GetIsParent() ? ( $product->GetLayers( StackEnums->ProductL_PRODUCT ) )[0]->GetData() : $product;

		my $c = ( map { $_->GetData() } grep { $_->GetData()->GetType() eq StackEnums->MaterialType_CORE } $p->GetLayers() )[0];
		$coreNum     = $c->GetCoreNumber();
		$coreMatKind = $c->GetTextType();
		%comp        = $self->{"panelComp"}->GetCoreMatComp( $coreNum, $coreMatKind );

	}
	else {
		%comp = ( "x" => 0, "y" => 0 );
	}
	return %comp;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Technology::DataComp::SigLayerComp';

	use aliased 'Packages::Export::PreExport::FakeLayers';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d267628";
	my $stepName = "panel";

	FakeLayers->CreateFakeLayers( $inCAM, $jobId, undef, 1 );

	my $lc = SigLayerComp->new( $inCAM, $jobId );

	my %comp1 = $lc->GetLayerCompensation("c");

}

1;
