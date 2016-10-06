
#-------------------------------------------------------------------------------------------#
# Description: Class, allow build multilayer "operations" for technical procedure
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::OperationBuilder::SLOperationBuilder;

use Class::Interface;

&implements('Packages::Export::NCExport::OperationBuilder::IOperationBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Drilling::DrillingHelper';
use aliased 'Enums::EnumsGeneral';
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

	#my %pressInfo = StackupHelper->GetStackupPressInfo( $self->{'jobId'} );
	#$self->{'pressInfo'} = \%pressInfo;    #hash

	#my %sigLayerInfo = DrillingHelper->GetStackupDrillingInfo( $self->{'jobId'}, $self->{'stepName'}, $self->{'inCAM'}, $self->{'pressInfo'} );
	#$self->{'sigLayerInfo'} = \%sigLayerInfo;    #hash

	#plated nc layers
	my %pltDrillInfo = DrillingHelper->GetPltNCLayerInfo( $self->{"jobId"}, $self->{"stepName"}, $self->{"inCAM"}, $self->{"pltLayers"} );
	$self->{"pltDrillInfo"} = \%pltDrillInfo;

	#nplated nc layers
	my %npltDrillInfo = DrillingHelper->GetNPltNCLayerInfo( $self->{"jobId"}, $self->{"stepName"}, $self->{"inCAM"}, $self->{"npltLayers"} );
	$self->{"npltDrillInfo"} = \%npltDrillInfo;

	$self->__DefinePlatedOperations($opManager);
	$self->__DefineNPlatedOperations($opManager);
	$self->__DefinePlatedGroups($opManager);
	$self->__DefineNPlatedGroups($opManager);

	#$self->__BuildOperationItems($opManager);

}

# Create groups from single operations
# Layer contaned in these operations will be merged to one nc file
sub __DefinePlatedGroups {
	my $self      = shift;
	my $opManager = shift;

	# No groups here

}

# Create groups from single operations
# Layer contaned in these operations will be merged to one nc file
sub __DefineNPlatedGroups {
	my $self      = shift;
	my $opManager = shift;

	# 1) Create group FROM TOP for mill and z-axis mill

	my @operations = ();
	my $name       = "fc";

	my $operFc = $opManager->GetOperationDef("fc");
	if ($operFc) {
		push( @operations, $operFc );
	}

	my $operFzc = $opManager->GetOperationDef("fzc");
	if ($operFzc) {
		push( @operations, $operFzc );
	}

	$opManager->AddGroupDef( $name, \@operations, -1 );
}

# Create single operations, which represent operation on technical procedure
# Every operation containc name of exportin nc file, layers to merging
sub __DefinePlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my %pltDrillInfo = %{ $self->{"pltDrillInfo"} };    #contain array of hashes of all NC layers with info (start/stop drill layer)

	#plated
	my @plt_nDrill    = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_nDrill} };       #normall through holes plated
	my @plt_cDrill    = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_cDrill} };       #core plated
	my @plt_bDrillTop = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_bDrillTop} };    #blind holes top
	my @plt_bDrillBot = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_bDrillBot} };    #blind holes bot
	my @plt_fDrill    = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_fDrill} };       #frame drilling
	my @plt_nMill     = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_nMill} };        #normall mill slits
	my @plt_bMillTop  = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_bMillTop} };     #z-axis top mill slits
	my @plt_bMillBot  = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_bMillBot} };     #z-axis bot mill slits
	my @plt_dcDrill   = @{ $pltDrillInfo{EnumsGeneral->LAYERTYPE_plt_dcDrill} };      #drill crosses

	# 1) Operation name = c - can contain layer
	# - $plt_nDrill
	$opManager->AddOperationDef( "c", \@plt_nDrill, -1 );

	# 2) Operation name = r - can contain layer
	# - @plt_nMill
	$opManager->AddOperationDef( "r", \@plt_nMill, -1 );

	# 3) Operation name = rzc - can contain layer
	# - @plt_bMillTop
	$opManager->AddOperationDef( "rzc", \@plt_bMillTop, -1 );

	# 4) Operation name = rzs - can contain layer
	# - @plt_bMillBot
	$opManager->AddOperationDef( "rzs", \@plt_bMillBot, -1 );

}

# Create single operations, which represent operation on technical procedure
# Every operation containc name of exportin nc file, layers to merging
sub __DefineNPlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my %npltDrillInfo = %{ $self->{"npltDrillInfo"} };    #contain array of hashes of all NC layers with info (start/stop drill layer)

	#non plated
	my @nplt_nMill    = @{ $npltDrillInfo{EnumsGeneral->LAYERTYPE_nplt_nMill} };       #normall mill slits
	my @nplt_bMillTop = @{ $npltDrillInfo{EnumsGeneral->LAYERTYPE_nplt_bMillTop} };    #z-axis top mill
	my @nplt_bMillBot = @{ $npltDrillInfo{EnumsGeneral->LAYERTYPE_nplt_bMillBot} };    #z-axis bot mill
	my @nplt_rsMill   = @{ $npltDrillInfo{EnumsGeneral->LAYERTYPE_nplt_rsMill} };      #rs mill before plating
	my @nplt_frMill   = @{ $npltDrillInfo{EnumsGeneral->LAYERTYPE_nplt_frMill} };      #milling frame
	my @nplt_kMill   = @{ $npltDrillInfo{EnumsGeneral->LAYERTYPE_nplt_kMill} };      #milling conneector 
	
	#Define operation:

	# 1) Operation name = f - can contain layer
	# - @nplt_nMill

	# Exception, if "fsch" layer is created. Thus remove "f" and use instead onlz "fch" layer
	# "f_sch" contains final rout, which have right set footdown
	my @fsch = grep { $_->{"gROWname"} =~ /fsch/i } @nplt_nMill;

	if ( scalar(@fsch) > 0 ) {
		@nplt_nMill = grep { $_->{"gROWname"} !~ /^f[0-9]*$/i } @nplt_nMill;
	}

	$opManager->AddOperationDef( "fc", \@nplt_nMill, -1 );

	# 2) Operation name = fzc - can contain layer
	# - @nplt_bMillTop
	$opManager->AddOperationDef( "fzc", \@nplt_bMillTop, -1 );

	# 3) Operation name = fzs - can contain layer
	# - @nplt_bMillBot
	$opManager->AddOperationDef( "fzs", \@nplt_bMillBot, -1 );

	# 4) Operation name = rs - can contain layer
	# - @nplt_rsMill
	$opManager->AddOperationDef( "rs", \@nplt_rsMill, -1 );

	# 5) Operation name = k - can contain layer
	# - @nplt_kMill
	$opManager->AddOperationDef( "fk", \@nplt_kMill, -1 );

}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

