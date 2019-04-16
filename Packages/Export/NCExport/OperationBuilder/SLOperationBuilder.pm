
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
use aliased 'Packages::Export::NCExport::Helpers::DrillingHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamDrilling';

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
	$self->__DefinePlatedGroups($opManager);
	$self->__DefineNPlatedGroups($opManager);

}

# Create groups from single operations
# Layer contaned in these operations will be merged to one nc file
sub __DefinePlatedGroups {
	my $self      = shift;
	my $opManager = shift;

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
	my @plt_nDrill     = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nDrill } };        # normall through holes plated
	my @plt_nFillDrill = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nFillDrill } };    # normall filledthrough holes plated
	my @plt_cDrill     = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_cDrill } };        # core plated
	my @plt_fDrill     = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_fDrill } };        # frame drilling
	my @plt_fcDrill    = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_fcDrill } };       # core frame drilling
	my @plt_nMill      = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nMill } };         # normall mill slits
	my @plt_bMillTop   = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bMillTop } };      # z-axis top mill slits
	my @plt_bMillBot   = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bMillBot } };      # z-axis bot mill slits
	my @plt_dcDrill    = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_dcDrill } };       # drill crosses

	my $viaFill = CamDrilling->GetViaFillExists( $self->{"inCAM"}, $self->{"jobId"} );

	# 1) Operation name = c/c_d - can contain layer
	# - plt_nDrill
	# - plt_fDrill
	# if via fill, do not add frilled frame
	if ($viaFill) {

		$opManager->AddOperationDef( "c_d", \@plt_nDrill, -1 );
	}
	else {
		my @l = ();
		push( @l, @plt_nDrill );
		push( @l, @plt_fDrill );
		$opManager->AddOperationDef( "c", \@l, -1 );
	}

	# 2) Operation name = c - can contain layer
	# - plt_nFillDrill
	if ($viaFill) {
		my @l = ();
		push( @l, @plt_nFillDrill );
		push( @l, @plt_fDrill );
		$opManager->AddOperationDef( "c", \@l, -1 );
	}

	# 3) Operation name = r - can contain layer
	# - @plt_nMill
	$opManager->AddOperationDef( "r", \@plt_nMill, -1 );

	# 4) Operation name = rzc - can contain layer
	# - @plt_bMillTop
	$opManager->AddOperationDef( "rzc", \@plt_bMillTop, -1 );

	# 5) Operation name = rzs - can contain layer
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
	my @nplt_nDrill   = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nDrill } };      #normall nplt drill
	my @nplt_nMill    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nMill } };       #normall mill slits
	my @nplt_bMillTop = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } };    #z-axis top mill
	my @nplt_bMillBot = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } };    #z-axis bot mill
	my @nplt_rsMill   = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_rsMill } };      #rs mill before plating
	my @nplt_frMill   = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_frMill } };      #milling frame
	my @nplt_kMill    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_kMill } };       #milling conneector
	my @nplt_lcMill   = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_lcMill } };      #milling template snim lak c
	my @nplt_lsMill   = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_lsMill } };      #milling template snim lak s

	my @nplt_cvrlycMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill } };    #top coverlay mill
	my @nplt_cvrlysMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_cvrlysMill } };    #bot coverlay mill

	#Define operation:

	# 1) Operation name = fc - can contain layer
	# - @nplt_nDrill
	# - @nplt_nMill

	# Exception, if "fsch" layer is created. Thus remove "f" and use instead onlz "fch" layer
	# "f_sch" contains final rout, which have right set footdown
	my @fsch = grep { $_->{"gROWname"} =~ /fsch/i } @nplt_nMill;

	if ( scalar(@fsch) > 0 ) {
		@nplt_nMill = grep { $_->{"gROWname"} !~ /^f[0-9]*$/i } @nplt_nMill;
	}

	# add all @nplt_nDrill which has dir from top2bot
	my @nplt_nDrill_t2b = grep { $_->{"gROWdrl_dir"} ne "bot2top" } @nplt_nDrill;

	# Exception, if "fsch_d" layer is created. Remove "d" and use instead only "fsch_d" layer
	# fsch_d contain nplt drills from layer fsch
	if ( scalar( grep { $_->{"gROWname"} =~ /fsch_d/i } @nplt_nDrill_t2b ) > 0 ) {
		die "Layer \"d\" must exist if exist layer \"fsch_d\"" unless ( grep { $_->{"gROWname"} =~ /^d$/i } @nplt_nDrill_t2b );
		@nplt_nDrill_t2b = grep { $_->{"gROWname"} !~ /^d$/i } @nplt_nDrill_t2b;
	}

	my @layers1 = ( @nplt_nMill, @nplt_nDrill_t2b );

	$opManager->AddOperationDef( "fc", \@layers1, -1 );

	# 2) Operation name = fzc - can contain layer
	# - @nplt_bMillTop
	$opManager->AddOperationDef( "fzc", \@nplt_bMillTop, -1 );

	# 3) Operation name = fzs - can contain layer
	# - @nplt_bMillBot
	# - @nplt_nDrill

	# add all @nplt_nDrill which has dir from bot2top
	my @nplt_nDrill_b2t = grep { $_->{"gROWdrl_dir"} eq "bot2top" } @nplt_nDrill;

	# Exception, if "fsch_d" layer is created. Remove "d" and use instead only "fsch_d" layer
	# fsch_d contain nplt drills from layer fsch
	if ( scalar( grep { $_->{"gROWname"} =~ /fsch_d/i } @nplt_nDrill_b2t ) > 0 ) {
		die "Layer \"d\" must exist if exist layer \"fsch_d\"" unless ( grep { $_->{"gROWname"} =~ /^d$/i } @nplt_nDrill_b2t );
		@nplt_nDrill_b2t = grep { $_->{"gROWname"} !~ /^d$/i } @nplt_nDrill_b2t;
	}
	my @layers2 = ( @nplt_bMillBot, @nplt_nDrill_b2t );

	$opManager->AddOperationDef( "fzs", \@layers2, -1 );

	# 4) Operation name = rs - can contain layer
	# - @nplt_rsMill
	$opManager->AddOperationDef( "rs", \@nplt_rsMill, -1 );

	# 5) Operation name = fk - can contain layer
	# - @nplt_kMill
	$opManager->AddOperationDef( "fk", \@nplt_kMill, -1 );

	# 6) Operation name = flc - can contain layer
	# - @nplt_lcMill
	$opManager->AddOperationDef( "flc", \@nplt_lcMill, -1 );

	# 7) Operation name = fls - can contain layer
	# - @nplt_lsMill
	$opManager->AddOperationDef( "fls", \@nplt_lsMill, -1 );

	# 11) Operation name = fls - can contain layer
	$opManager->AddOperationDef( "coverlayc", \@nplt_cvrlycMill, -1 );

	# 11) Operation name = fls - can contain layer
	$opManager->AddOperationDef( "coverlays", \@nplt_cvrlysMill, -1 );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

