
#-------------------------------------------------------------------------------------------#
# Description: Special class, allow export layer as are. No group operations, no merging layers
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::OperationMngr::OperationBuilder::SimpleOperationBuilder;

use Class::Interface;

&implements('Packages::Export::NCExport::OperationMngr::OperationBuilder::IOperationBuilder');

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
#use aliased 'Packages::Export::NCExport::NCExportHelper';
use aliased 'Packages::Export::NCExport::OperationMngr::DrillingHelper';


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	return $self;
}

sub Init {

	my $self = shift;
	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"stepName"}   = shift;
	$self->{"pltLayers"}  = shift;
	$self->{"npltLayers"} = shift;

}

sub DefineOperations {
	my $self      = shift;
	my $opManager = shift;

	#plated nc layers
	my %pltDrillInfo = DrillingHelper->GetPltNCLayerInfo( $self->{"jobId"}, $self->{"stepName"}, $self->{"inCAM"}, $self->{"pltLayers"} );
	$self->{"pltDrillInfo"} = \%pltDrillInfo;

	#nplated nc layers
	my %npltDrillInfo = DrillingHelper->GetNPltNCLayerInfo( $self->{"jobId"}, $self->{"stepName"}, $self->{"inCAM"}, $self->{"npltLayers"} );
	$self->{"npltDrillInfo"} = \%npltDrillInfo;

	$self->__DefinePlatedOperations($opManager);
	$self->__DefineNPlatedOperations($opManager);

}

sub __DefinePlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my @layers = ();
	my %plt    = %{ $self->{"pltDrillInfo"} };

	#get all plated layers
	foreach my $k (keys %plt) {

		push( @layers, @{ $plt{$k} } );
	}

	foreach my $l (@layers) {

		my @a = ($l);
		$opManager->AddOperationDef( $l->{"gROWname"}, \@a, -1 );
	}
}

sub __DefineNPlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my @layers = ();
	my %nplt    = %{ $self->{"npltDrillInfo"} };

	#get all plated layers
	foreach my $k (keys %nplt) {

		push( @layers, @{ $nplt{$k} } );
	}

	foreach my $l (@layers) {

		my @a = ($l);
		$opManager->AddOperationDef( $l->{"gROWname"}, \@a, -1 );
	}
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

