
#-------------------------------------------------------------------------------------------#
# Description: Manager responsible for AOI files creation
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::PreExport::PreMngr;
use base('Packages::Export::MngrBase');

use Class::Interface;
&implements('Packages::Export::IMngr');

#3th party library
use strict;
use warnings;

#local library


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
	$self->{"layers"} = shift;
	

	return $self;
}

sub Run {
	my $self = shift;
	
	
	# Set 

}


sub ExportItemsCount {
	my $self = shift;

	my $totalCnt = 0;
 
	$totalCnt += scalar(@{$self->{"layers"}});    #export each layer

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

