
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
use aliased 'CamHelpers::CamHistogram';
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

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	#nplated nc layers
	my %npltDrillInfo = DrillingHelper->GetNPltNCLayerInfo( $self->{"jobId"}, $self->{"stepName"}, $self->{"inCAM"}, $self->{"npltLayers"} );
	$self->{"npltDrillInfo"} = \%npltDrillInfo;

	# Filter out layers which are empty - do not contain any symbols. Panel with has filled only some layers

	foreach my $lType ( keys %npltDrillInfo ) {

		my @l = @{ $npltDrillInfo{$lType} };

		for ( my $i = scalar(@l) - 1 ; $i >= 0 ; $i-- ) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $self->{"stepName"}, $l[$i]->{"gROWname"}, 1 );
			splice @l, $i, 1 if ( $hist{"total"} == 0 );
		}

		$npltDrillInfo{$lType} = \@l;
	}

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
	my @nplt_nDrillBot   = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nDrillBot } };      #normall nplt drill from BOT
	my @nplt_nMillBot    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nMillBot } };       #normall mill slits from BOT
	my @nplt_bMillTop    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } };       #z-axis top mill
	my @nplt_bMillBot    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } };       #z-axis bot mill
	my @nplt_bstiffcMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bstiffcMill } };    # depth milling of stiffener from side c
	my @nplt_bstiffsMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bstiffsMill } };    # depth milling of stiffener from side s

	#Define operation:

	# 1) Operation name = fcpnc - can contain layer
	# - @nplt_nDrill
	# - @nplt_nMill
	# - @nplt_bMillTop
	# - @nplt_bstiffcMill

	my @topLayers = ();
	push( @topLayers, @nplt_bMillTop )    if ( scalar(@nplt_bMillTop) );
	push( @topLayers, @nplt_bstiffcMill ) if ( scalar(@nplt_bstiffcMill) );

	if ( scalar(@topLayers) ) {

		push( @topLayers, @nplt_nMill )  if ( scalar(@nplt_nMill) );
		push( @topLayers, @nplt_nDrill ) if ( scalar(@nplt_nDrill) );

		$opManager->AddOperationDef( "fcpnc", \@topLayers, -1 );
	}

	# 2) Operation name = fcpns - can contain layer
	# - @nplt_nDrill
	# - @nplt_nMill
	# - @nplt_bMillBot
	# - @nplt_bstiffsMill

	my @botLayers = ();

	push( @botLayers, @nplt_bMillBot )    if ( scalar(@nplt_bMillBot) );
	push( @botLayers, @nplt_bstiffsMill ) if ( scalar(@nplt_bstiffsMill) );

	if ( scalar(@botLayers) ) {

		push( @botLayers, @nplt_nMillBot )  if ( scalar(@nplt_nMillBot) );
		push( @botLayers, @nplt_nDrillBot ) if ( scalar(@nplt_nDrillBot) );

		$opManager->AddOperationDef( "fcpns", \@botLayers, -1 );

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

