
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::GerMngr;
use base('Packages::ItemResult::ItemResultMngr');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Export::PreExport::LayerInvert';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Export::GerExport::ExportGerMngr';
use aliased 'Packages::Export::GerExport::ExportPasteMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class     = shift;
	my $packageId = __PACKAGE__;
	my $self      = $class->SUPER::new( $packageId, @_ );
	bless $self;

	$self->{"inCAM"}  = shift;
	$self->{"jobId"}  = shift;
	$self->{"exportLayers"} = shift;
	$self->{"layers"} = shift;
	$self->{"paste"} = shift;
	 
	$self->{"gerberMngr"} =  ExportGerMngr->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"exportLayers"}, $self->{"layers"});
	$self->{"gerberMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );
	
	$self->{"pasteMngr"} = 	 ExportPasteMngr->new($self->{"inCAM"}, $self->{"jobId"}, $self->{"paste"});
	$self->{"pasteMngr"}->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );
	
	return $self;
}

sub Run {
	my $self = shift;

	 
	 $self->{"gerberMngr"}->Run();
	 $self->{"pasteMngr"}->Run();

}

sub ExportItemsCount {
	my $self = shift;

	my $totalCnt = 0;

	$totalCnt += $self->{"exportLayers"}  ? 1: 0;;    #gerbers
	$totalCnt += $self->{"paste"}->{"export"} ? 1: 0; # paste

	return $totalCnt;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::PlotExport::PlotMngr';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f13609";
	#
	#	my @layers = CamJob->GetBoardBaseLayers( $inCAM, $jobId );
	#
	#	foreach my $l (@layers) {
	#
	#		$l->{"polarity"} = "positive";
	#
	#		if ( $l->{"gROWname"} =~ /pc/ ) {
	#			$l->{"polarity"} = "negative";
	#		}
	#
	#		$l->{"mirror"} = 0;
	#		if ( $l->{"gROWname"} =~ /c/ ) {
	#			$l->{"mirror"} = 1;
	#		}
	#
	#		$l->{"compensation"} = 30;
	#		$l->{"name"}         = $l->{"gROWname"};
	#	}
	#
	#	@layers = grep { $_->{"name"} =~ /p[cs]/ } @layers;
	#
	#	my $mngr = PlotMngr->new( $inCAM, $jobId, \@layers );
	#	$mngr->Run();
}

1;

