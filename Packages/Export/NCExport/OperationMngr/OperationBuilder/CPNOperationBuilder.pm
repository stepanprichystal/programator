
#-------------------------------------------------------------------------------------------#
# Description: Class, allow build "operations" for technical procedure
# Special case for prepare operations for coupons (depth milling)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::OperationMngr::OperationBuilder::CPNOperationBuilder;

use Class::Interface;

&implements('Packages::Export::NCExport::OperationMngr::OperationBuilder::IOperationBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::NCExport::OperationMngr::DrillingHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Helpers::JobHelper';

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

	#nplated nc layers
	my %npltDrillInfo = DrillingHelper->GetNPltNCLayerInfo( $self->{"jobId"}, $self->{"stepName"}, $self->{"inCAM"}, $self->{"npltLayers"} );
	$self->{"npltDrillInfo"} = \%npltDrillInfo;

	$self->__DefineNPlatedOperations($opManager);
 
}

 
# Create single operations, which represent operation on technical procedure
# Every operation containc name of exportin nc file, layers to merging
sub __DefineNPlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my %npltDrillInfo = %{ $self->{"npltDrillInfo"} };    #contain array of hashes of all NC layers with info (start/stop drill layer)

	#non plated
	my @nplt_nDrill      = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nDrill } };         #normall nplt drill
	my @nplt_nMill       = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nMill } };          #normall mill slits
	my @nplt_bMillTop    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } };       #z-axis top mill
	my @nplt_bMillBot    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } };       #z-axis bot mill
	my @nplt_bstiffcMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bstiffcMill } };    # depth milling of stiffener from side c
	my @nplt_bstiffsMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bstiffsMill } };    # depth milling of stiffener from side s

	#Define operation:

	# 1) Operation name = fcouponc - can contain layer
	# - @nplt_nDrill
	# - @nplt_nMill
	# - @nplt_bMillTop
	# - @nplt_bstiffcMill

	my @topLayers = ();

	# add all @nplt_nDrill which has dir from top2bot
	my @nplt_nDrill_t2b = grep { $_->{"gROWdrl_dir"} eq "top2bot" } @nplt_nDrill;

	push( @topLayers, @nplt_nDrill_t2b );
	push( @topLayers, @nplt_bMillTop );
	push( @topLayers, @nplt_bstiffcMill );

	$opManager->AddOperationDef( "fcouponc", \@topLayers, -1 );

	# 2) Operation name = fcoupons - can contain layer
	# - @nplt_nDrill
	# - @nplt_nMill
	# - @nplt_bMillBot
	# - @nplt_bstiffsMill

	my @botLayers = ();

	# add all @nplt_nDrill which has dir from bot2top
	my @nplt_nDrill_b2t = grep { $_->{"gROWdrl_dir"} eq "bot2top" } @nplt_nDrill;

	push( @botLayers, @nplt_nDrill_b2t );
	push( @botLayers, @nplt_bMillBot );
	push( @botLayers, @nplt_bstiffsMill );

	$opManager->AddOperationDef( "fcoupons", \@botLayers, -1 );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

