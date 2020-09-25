#-------------------------------------------------------------------------------------------#
# Description: Return information about material stability
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Technology::DataComp::NCLayerComp;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Technology::DataComp::PanelComp::PanelComp';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Packages::Stackup::Enums' => "StackEnums";
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $inCAM = shift;
	my $jobId = shift;
	my $step = shift // 'panel'; 

	# PROPERTY

	$self->{"inCAM"}    = $inCAM;
	$self->{"jobId"}    = $jobId;
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackupNC"} = StackupNC->new( $inCAM, $jobId );
	}

	$self->{"panelComp"} = PanelComp->new( $inCAM, $jobId, $step, $self->{"stackupNC"} );

	return $self;
}

sub GetLayerCompensation {
	my $self    = shift;
	my $NClayer = shift;

	my %NCLInfo = CamDrilling->GetNCLayerInfo( undef, $self->{"jobId"}, $NClayer, 1 );

	my %comp = ();

	if ( $self->{"layerCnt"} > 2 ) {

		%comp = $self->__GetCompensationVV( \%NCLInfo );

	}
	else {

		%comp = $self->__GetCompensation2V( \%NCLInfo );
	}

	$comp{"x"} = sprintf( "%.3f", $comp{"x"} );
	$comp{"y"} = sprintf( "%.3f", $comp{"y"} );

	return %comp;

}

sub __GetCompensation2V {
	my $self    = shift;
	my $NCLInfo = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %comp = ( "x" => undef, "y" => undef );

	if (    $NCLInfo->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill
		 || $NCLInfo->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill
		 || $NCLInfo->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fDrill
		 || $NCLInfo->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill )
	{

		%comp = $self->{"panelComp"}->GetBaseMatComp();

	}
	else {

		%comp = ( "x" => 0, "y" => 0 );
	}

	return %comp;

}

sub __GetCompensationVV {
	my $self    = shift;
	my $NCLInfo = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $coreNum     = undef;
	my $coreMatKind = undef;

	my %comp = ( "x" => undef, "y" => undef );

	if ( $NCLInfo->{"type"} eq EnumsGeneral->LAYERTYPE_plt_fcDrill && $NCLInfo->{"gROWname"} =~ /^v1j(\d+)$/ ) {

		$coreNum     = ( $NCLInfo->{"gROWname"} =~ /^v1j(\d+)$/ )[0];
		$coreMatKind = $self->{"stackupNC"}->GetCore($coreNum)->GetTextType();

		%comp = $self->{"panelComp"}->GetCoreMatComp( $coreNum, $coreMatKind );

	}
	elsif ( $NCLInfo->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill || $NCLInfo->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill ) {

		my @coreProducts = $self->{"stackupNC"}->GetNCCoreProducts();
		my $NCCore = first { $_->ExistNCLayers( undef, undef, $NCLInfo->{"type"}, 1 ) } @coreProducts;

		my $c = ( map { $_->GetData() } grep { $_->GetData()->GetType() eq StackEnums->MaterialType_CORE } $NCCore->GetIProduct()->GetLayers() )[0];

		$coreNum     = $c->GetCoreNumber();
		$coreMatKind = $c->GetTextType();

		%comp = $self->{"panelComp"}->GetCoreMatComp( $coreNum, $coreMatKind );

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

	use aliased 'Packages::Technology::DataComp::NCLayerComp';
	use aliased 'Packages::Export::PreExport::FakeLayers';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d222773";
	my $stepName = "panel";

	FakeLayers->CreateFakeLayers( $inCAM, $jobId );

	my $lc = NCLayerComp->new( $inCAM, $jobId, undef, 1 );

	my %comp1 = $lc->GetLayerCompensation("m");

	print "Comp j1 X:" . $comp1{"x"} . "; Y:" . $comp1{"y"} . "\n";

	my %comp2 = $lc->GetLayerCompensation("v");
	print "Comp j2 X:" . $comp2{"x"} . "; Y:" . $comp2{"y"};

}

1;
