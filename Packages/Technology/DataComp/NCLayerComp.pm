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
use aliased 'Enums::EnumsGeneral';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my $inCAM = shift;
	my $jobId = shift;

	# PROPERTY

	$self->{"inCAM"}    = $inCAM;
	$self->{"jobId"}    = $jobId;
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->{"stackupNC"} = StackupNC->new( $inCAM, $jobId );
	}

	$self->{"panelComp"} = PanelComp->new( $inCAM, $jobId, $self->{"stackupNC"} );

	return $self;
}

sub GetLayerCompensation {
	my $self    = shift;
	my $NClayer = shift;

	my %NCLInfo = CamDrilling->GetNCLayerInfo( undef, $jobId, $NClayer, 1 );

	if ( $self->{"layerCnt"} > 2 ) {

		$self->__GetCompensationVV( \%NCLInfo );

	}
	else {

		$self->__GetCompensation2V( \%NCLInfo );
	}

}

sub __GetCompensation2V {
	my $self    = shift;
	my $NCLInfo = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my %comp = ( "x" => undef, "y" => undef );

 
	if ( $NCLInfo{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill || $NCLInfo{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill ) {

		%comp = $self->{"panelComp"}->GetBaseMatComp();

	}
	else {

		%comp = ( "x" => 0, "y" => 0 );
	}

}

sub __GetCompensationVV {
	my $self    = shift;
	my $NCLInfo = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $coreNum     = undef;
	my $coreMatKind = undef;

	my %comp = ( "x" => undef, "y" => undef );

	if ( $NCLInfo{"type"} eq EnumsGeneral->LAYERTYPE_plt_fcDrill ) {

		$coreNum =~ (/^v(\d+)$/)[0];
		$coreMatKind = $self->{"stackupNC"}->GetCore($coreNum)->GetTextType();

		%comp = $self->{"panelComp"}->GetCoreMatComp( $coreNum, $coreMatKind );

	}
	elsif ( $NCLInfo{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill || $NCLInfo{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill ) {

		my @coreProducts = $self->{"stackupNC"}->GetNCCoreProduct();
		my $NCCore = first { $_->ExistNCLayers( undef, undef, $NCLInfo{"type"}, 1 ) } @coreProducts;

		my $c = ( map { $_->GetData() } grep { $_->GetData()->GetType() eq Enums->MaterialType_CORE } $NCCore->GetIProduct()->GetLayers() )[0];

		$coreNum     = $c->GetCoreNumber();
		$coreMatKind = $c->GetTextType();

		%comp = $self->{"panelComp"}->GetCoreMatComp( $coreNum, $coreMatKind );

	}
	else {

		%comp = ( "x" => 0, "y" => 0 );
	}

	return \%comp;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Technology::DataComp::MatStability';

	my $t = MatStability->new("PYRALUX");
	die $t;

}

1;
