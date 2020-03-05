
#-------------------------------------------------------------------------------------------#
# Description: Base class for BIF builders. Nif Builder is responsible for
# creation nif file depend on pcb type
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustStackup::StackupMngr::StackupMngrBase;

#3th party library
use strict;
use warnings;
use List::Util qw(first);

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	#require rows in nif section
	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	my @boardBase = CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} );
	my @NCLayers = CamJob->GetNCLayers( $self->{"inCAM"}, $self->{"jobId"} );
	CamDrilling->AddNCLayerType( \@NCLayers );
	CamDrilling->AddLayerStartStop( $self->{"inCAM"}, $self->{"jobId"}, \@NCLayers );

	$self->{"boardBaseLayers"} = \@boardBase;
	$self->{"NCLayers"}        = \@NCLayers;

	$self->{"pcbType"}   = JobHelper->GetPcbType( $self->{"jobId"} );
	$self->{"pcbInfoIS"} = ( HegMethods->GetAllByPcbId( $self->{"jobId"} ) )[0];

	return $self;
}

sub GetExistSMTop {
	my $self = shift;

	my $mc = first { $_->{"gROWname"} eq "mc" } @{ $self->{"boardBaseLayers"} };

	return defined $mc ? 1 : 0;

}

sub GetExistSMFlexTop {
	my $self = shift;

	my $mc = first { $_->{"gROWname"} eq "mcflex" } @{ $self->{"boardBaseLayers"} };

	return defined $mc ? 1 : 0;

}

sub GetExistSMBFlexot {
	my $self = shift;

	my $mc = first { $_->{"gROWname"} eq "msflex" } @{ $self->{"boardBaseLayers"} };

	return defined $mc ? 1 : 0;

}

sub GetExistPCTop {
	my $self = shift;

	my $mc = first { $_->{"gROWname"} eq "pc" } @{ $self->{"boardBaseLayers"} };

	return defined $mc ? 1 : 0;

}

sub GetExistPCBot {
	my $self = shift;

	my $mc = first { $_->{"gROWname"} eq "ps" } @{ $self->{"boardBaseLayers"} };

	return defined $mc ? 1 : 0;
}

sub GetPcbType {
	my $self = shift;

	return $self->{"pcbType"};
}

sub GetPlatedNC {
	my $self = shift;

	my @NC = grep { $_->{"plated"} && !$_->{"technical"} } @{ $self->{"NCLayers"} };

	my @sorted = ();

	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill     && $_->{"NCSigStartOrder"} == 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $_->{"NCSigStartOrder"} == 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nDrill     && $_->{"NCSigStartOrder"} > 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_nFillDrill && $_->{"NCSigStartOrder"} > 1 } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillTop } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillTop } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bDrillBot } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_bFillDrillBot } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cDrill } @NC );
	push( @sorted, grep { $_->{"type"} eq EnumsGeneral->LAYERTYPE_plt_cFillDrill } @NC );

	return @sorted;
}

sub GetGetExistStiff {
	my $self     = shift;
	my $side = shift; # top/bot
	my $stifInfo = shift;    # reference for storing info
	
	my $l = $side eq "top" ? "stiffc" : "stiffs";

	my $exist = defined (first { $_->{"gROWname"} eq $l } @{ $self->{"boardBaseLayers"} }) ? 1 : 0;

	if ($exist) {

		my $matInfo = HegMethods->GetPcbStiffenerMat( $self->{"jobId"} );

		if ( defined $stifInfo ) {
			$stifInfo->{"adhesiveText"} = "3M tape";
			$stifInfo->{"adhesiveThick"} = 50;                               # ? is not store
			$stifInfo->{"stiffText"}     = $matInfo->{"nazev_subjektu"};     # ? is not store
			$stifInfo->{"stiffThick"}    = $matInfo->{"tloustka"} * 1000;    # µm
		}
	}

	return $exist;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

