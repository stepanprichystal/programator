
#-------------------------------------------------------------------------------------------#
# Description: Class, allow build multilayer "operations" for technical procedure
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::OperationBuilder::MLOperationBuilder;

use Class::Interface;
&implements('Packages::Export::NCExport::OperationBuilder::IOperationBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Drilling::DrillingHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';

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

	my $stackup = Stackup->new( $self->{'jobId'} );
	$self->{'stackup'} = $stackup;                                         #hash
	$self->{'stackupNC'} = StackupNC->new( $self->{"inCAM"}, $stackup );

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

	my $stackup = $self->{'stackup'};    #info about press count, which layer are pressed, etc..

	# 1) Create group FROM TOP depend on pressing order

	foreach my $pressOrder ( keys $stackup->{"press"} ) {

		my $press = $stackup->{"press"}{$pressOrder};

		my @operations = ();
		my $name       = "";

		#group for last pressing
		if ( $pressOrder == $stackup->GetPressCount() ) {

			$name = "c" . $stackup->GetPressCount();

			#if exist, add normal drill + blind from top
			my $operC = $opManager->GetOperationDef( "c" . $pressOrder );
			if ($operC) {
				push( @operations, $operC );
			}

			#if exist, add normal drill + blind from top
			my $operR = $opManager->GetOperationDef( "r" . $pressOrder );
			if ($operR) {
				push( @operations, $operR );
			}

			#if exist, add normal drill + blind from top
			my $operRzc = $opManager->GetOperationDef( "rzc" . $pressOrder );
			if ($operRzc) {
				push( @operations, $operRzc );
			}
		}

		$opManager->AddGroupDef( $name, \@operations, $pressOrder );

	}

	# 2) Create group FROM BOT depend on pressing order

	foreach my $pressOrder ( keys $stackup->{"press"} ) {

		my $press = $stackup->{"press"}{$pressOrder};

		my @operations = ();
		my $name       = "";

		#group for last pressing
		if ( $pressOrder == $stackup->GetPressCount() ) {

			$name = "s" . $stackup->GetPressCount();

			#if exist, add normal drill + blind from top
			my $operS = $opManager->GetOperationDef( "s" . $pressOrder );
			if ($operS) {
				push( @operations, $operS );
			}

			#if exist, add normal drill + blind from top
			my $operRzs = $opManager->GetOperationDef( "rzs" . $pressOrder );
			if ($operRzs) {
				push( @operations, $operRzs );
			}
		}

		$opManager->AddGroupDef( $name, \@operations, $pressOrder );

	}
}

# Create groups from single operations
# Layer contaned in these operations will be merged to one nc file
sub __DefineNPlatedGroups {
	my $self      = shift;
	my $opManager = shift;

	my $stackup = $self->{'stackup'};    #info about press count, which layer are pressed, etc..

	# 1) Create group FROM TOP depend on pressing order

	foreach my $pressOrder ( keys $stackup->{"press"} ) {

		my $press = $stackup->{"press"}{$pressOrder};

		my @operations = ();
		my $name       = "";

		#group for last pressing
		if ( $pressOrder == $stackup->GetPressCount() ) {

			$name = "fc" . $stackup->GetPressCount();

			#if exist, add normal drill + blind from top
			my $opFc = $opManager->GetOperationDef( "fc" . $pressOrder );
			if ($opFc) {
				push( @operations, $opFc );
			}

			#if exist, add normal drill + blind from top
			my $opFzc = $opManager->GetOperationDef( "fzc" . $pressOrder );
			if ($opFzc) {
				push( @operations, $opFzc );
			}
		}

		$opManager->AddGroupDef( $name, \@operations );

	}
}

# Create single operations, which represent operation on technical procedure
# Every operation containc name of exportin nc file, layers to merging
sub __DefinePlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my %pltDrillInfo = %{ $self->{"pltDrillInfo"} };    #contain array of hashes of all NC layers with info (start/stop drill layer)
	my $stackup      = $self->{'stackup'};              #info about press count, which layer are pressed, etc..
	my $stackupNC    = $self->{'stackupNC'};            #info about signal lyers, contain if contain blind, cor drilling etc:..
	my $pressCnt     = $stackupNC->GetPressCnt();
	my $coreCnt      = $stackupNC->GetCoreCnt();

	#plated
	my @plt_nDrill    = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nDrill } };       #normall through holes plated
	my @plt_cDrill    = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_cDrill } };       #core plated
	my @plt_bDrillTop = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } };    #blind holes top
	my @plt_bDrillBot = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } };    #blind holes bot
	my @plt_fDrill    = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_fDrill } };       #frame drilling
	my @plt_nMill     = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nMill } };        #normall mill slits
	my @plt_bMillTop  = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bMillTop } };     #z-axis top mill slits
	my @plt_bMillBot  = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bMillBot } };     #z-axis bot mill slits
	my @plt_dcDrill   = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_dcDrill } };      #drill crosses

	#Define operation:

	# 1) Operation name = c<press order>, can contain layer
	# - @plt_nDrill
	# - @plt_bDrillTop

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;
		my $press      = $stackupNC->GetPress($pressOrder);

		my $outFile = "c" . $pressOrder;
		my @layers  = ();

		my $topSignal    = $press->GetTopSigLayer();
		my $startTop     = $topSignal->GetNumber();
		my $startTopName = $topSignal->GetName();

		#plated normal drilling "m" start from top in layer <$drillStartTop>
		my @normalTop = grep { $_->{"gROWdrl_start"} == $startTop } @plt_nDrill;
		push( @layers, @normalTop );

		#blind drilling start from top in layer <$drillStartTop>
		my @blindTop = grep { $_->{"gROWdrl_start"} == $startTop } @plt_bDrillTop;
		push( @layers, @blindTop );

		#when it is last pressing, we don't add V1 frame
		if ( $pressOrder != $stackup->GetPressCount() ) {

			#for each pressing except last, add "v1" frame drilling
			if ( !$press->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill ) ) {

				#my @frameDrill = grep { $_->{"gROWname"} =~ /v1/ } @plt_bDrillBot;
				if ( scalar(@plt_fDrill) == 1 ) {
					push( @layers, $plt_fDrill[0] );
				}
			}
		}

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, $pressOrder );

		#$oDef->SetExtraInfo( "pressOrder", $pressOrder );
	}

	# 2) Operation name = s<press order>, can contain layer
	# - @plt_nDrill
	# - @plt_bDrillBot
	foreach my $pressOrder ( keys $stackup->{"press"} ) {

		my $press = $stackup->{"press"}{$pressOrder};

		my $outFile = "s" . $pressOrder;
		my @layers  = ();

		my $startBot     = $press->{"botNumber"};
		my $startBotName = $press->{"bot"};

		#plated normal drilling "m" start from bot in layer <$drillStartTop>
		my @normalBot = grep { $_->{"gROWdrl_start"} == $startBot } @plt_nDrill;
		push( @layers, @normalBot );

		#blind drilling start from bot in layer <$drillStartTop>
		my @blindBot = grep { $_->{"gROWdrl_start"} == $startBot } @plt_bDrillBot;
		push( @layers, @blindBot );

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, $pressOrder );

		#$oDef->SetExtraInfo( "pressOrder", $pressOrder );
	}

	# 3) Operation name = r - can contain layer
	# - @plt_nMill
	$opManager->AddOperationDef( "r" . $stackup->GetPressCount(), \@plt_nMill, $stackup->GetPressCount() );

	# 4) Operation name = rzc - can contain layer
	# - @plt_bMillTop
	$opManager->AddOperationDef( "rzc" . $stackup->GetPressCount(), \@plt_bMillTop, $stackup->GetPressCount() );

	# 5) Operation name = rzs - can contain layer
	# - @plt_bMillBot
	$opManager->AddOperationDef( "rzs" . $stackup->GetPressCount(), \@plt_bMillBot, $stackup->GetPressCount() );

	# 6) Operation name = j<core number> - can contain layers from
	# - @plt_cDrill
	# - @plt_fDrill
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $coreNum = $i + 1;
		my $core    = $stackupNC->GetCore($coreNum);

		my @layers = ();
		my @layersCore = $core->GetNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill );

		# if exist core drilling
		if ( scalar(@layersCore) ) {

			my @layersFiltr = ();

			foreach my $l (@plt_cDrill) {

				my $exist = scalar( grep { $_->{"gROWname"} eq $l->{"gROWname"} } @layersCore );

				if ($exist) {
					push( @layers, $l );
				}

			}

			# Add frame
			push( @layers, $plt_fDrill[0] );

			$opManager->AddOperationDef( "j" . $core->GetCoreNumber(), \@layers, 0 );
		}
	}

	# 7) Operation name = ds, can contain layer
	# - @plt_dsDrill
	$opManager->AddOperationDef( "dc", \@plt_dcDrill, $stackup->GetPressCount() );

	# 8) Operation name = v1, can contain layer
	# - @plt_fDrill

	# Find cores, which has not blind or core drilling

	my $noNCExist = 0;    # tell if  exist core, where is no plated NCoperation
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $coreNum = $i + 1;
		my $coreNC    = $stackupNC->GetCore($coreNum);

		# start/stop plated NC layers in core
		my @ncLayers = ();
		if ( $coreNC->ExistNCLayers( Enums->SignalLayer_TOP ) ) {
			push( @ncLayers, $coreNC->GetNCLayers( Enums->SignalLayer_TOP ) );
		}
		if ( $coreNC->ExistNCLayers( Enums->SignalLayer_BOT ) ) {
			push( @ncLayers, $coreNC->GetNCLayers( Enums->SignalLayer_BOT ) );
		}
		
		# outer core
		my $outer = 0;
 		if ( $coreNC->GetTopSigLayer()->GetName() eq "c" || $coreNC->GetBotSigLayer()->GetName() eq "s" ) {
			$outer = 1;
		}
		
		if ( scalar( grep { $_->{"plated"} } @ncLayers ) == 0 || $outer ) {
			$noNCExist = 1;
			last;
		}
	}

	if ($noNCExist) {
		$opManager->AddOperationDef( "v1", \@plt_fDrill, $stackup->GetPressCount(), "core" );
	}

}

# Create single operations, which represent operation on technical procedure
# Every operation containc name of exportin nc file, layers to merging
sub __DefineNPlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my %npltDrillInfo = %{ $self->{"npltDrillInfo"} };    #contain array of hashes of all NC layers with info (start/stop drill layer)
	my $stackup       = $self->{'stackup'};               #info about press count, which layer are pressed, etc..

	my $stackupNC = StackupNC->new( $self->{"inCAM"}, $stackup );
	my $coreCnt      = $stackupNC->GetCoreCnt();

	#non plated
	my @nplt_nDrill    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nDrill } };       #normall nplt drill
	my @nplt_nMill     = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_nMill } };        #normall mill slits
	my @nplt_bMillTop  = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillTop } };     #z-axis top mill
	my @nplt_bMillBot  = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_bMillBot } };     #z-axis bot mill
	my @nplt_rsMill    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_rsMill } };       #rs mill before plating
	my @nplt_frMill    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_frMill } };       #milling frame
	my @nplt_cbMillTop = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_cbMillTop } };    #z-axis Top mill of core
	my @nplt_cbMillBot = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_cbMillBot } };    #z-axis bot mill of core
	my @nplt_lcMill    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_lcMill } };       #milling template snim lak c
	my @nplt_lsMill    = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_lsMill } };       #milling template snim lak s
	my @nplt_kMill     = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_kMill } };        #milling conneector

	my @nplt_cvrlycMill  = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_cvrlycMill } };     #top coverlay mill
	my @nplt_cvrlysMill  = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_cvrlysMill } };     #bot coverlay mill
	my @nplt_prepregMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_prepregMill } };    #prepreg mill

	#Define operation:

	# 1) Operation name = fzc<press order>, can contain layer
	# - @nplt_bMillTop
	# - @nplt_nDrill

	foreach my $pressOrder ( keys $stackup->{"press"} ) {

		my $press   = $stackup->{"press"}{$pressOrder};
		my $outFile = "fzc" . $pressOrder;
		my @layers  = ();

		my $startTop     = $press->{"topNumber"};
		my $startTopName = $press->{"top"};

		#blind milling start from top in layer <$drillStartTop>
		my @blindTop = grep { $_->{"gROWdrl_start"} == $startTop } @nplt_bMillTop;
		push( @layers, @blindTop );

		$opManager->AddOperationDef( $outFile, \@layers, $pressOrder );
	}

	# 2) Operation name = fzs<press order>, can contain layer
	# - @nplt_bMillBot
	# - @nplt_nDrill

	foreach my $pressOrder ( keys $stackup->{"press"} ) {

		my $press   = $stackup->{"press"}{$pressOrder};
		my $outFile = "fzs" . $pressOrder;
		my @layers  = ();

		my $startBot     = $press->{"botNumber"};
		my $startBotName = $press->{"bot"};

		#blind milling start from top in layer <$drillStartTop>
		my @blindBot = grep { $_->{"gROWdrl_start"} == $startBot } @nplt_bMillBot;
		push( @layers, @blindBot );

		# add all @nplt_nDrill which has dir from bot2top
		my @nplt_nDrill_b2t = grep { $_->{"gROWdrl_dir"} eq "bot2top" && $_->{"gROWdrl_start"} == $startBot } @nplt_nDrill;
		push( @layers, @nplt_nDrill_b2t );

		$opManager->AddOperationDef( $outFile, \@layers, $pressOrder );
	}

	# 1) Operation name = fzc<press order>, can contain layer
	# - @nplt_bMillTop

	foreach my $pressOrder ( keys $stackup->{"press"} ) {

		my $press   = $stackup->{"press"}{$pressOrder};
		my $outFile = "fzc" . $pressOrder;
		my @layers  = ();

		my $startTop     = $press->{"topNumber"};
		my $startTopName = $press->{"top"};

		#blind milling start from top in layer <$drillStartTop>
		my @blindTop = grep { $_->{"gROWdrl_start"} == $startTop } @nplt_bMillTop;
		push( @layers, @blindTop );

		$opManager->AddOperationDef( $outFile, \@layers, $pressOrder );
	}

	# 4) Operation name = jfzc<core number> - can contain layer from @nplt_cbMillTop
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {
 
		my $core    = $stackup->GetCore($i + 1);

		my @jLayers = grep { $_->{"gROWdrl_start"} == $core->GetTopCopperLayer()->GetCopperNumber() } @nplt_cbMillTop;

		$opManager->AddOperationDef( "j" . $core->GetCoreNumber() . "fzc", \@jLayers, 0 );
	}

	# 5) Operation name = jfzs<core number> - can contain layer from @nplt_cbMillBot
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {
 
		my $core    = $stackup->GetCore($i + 1);

		my @jLayers = grep { $_->{"gROWdrl_start"} == $core->GetBotCopperLayer()->GetCopperNumber() } @nplt_cbMillBot;

		$opManager->AddOperationDef( "j" . $core->GetCoreNumber() . "fzs", \@jLayers, 0 );
	}

	# 6) Operation name = f - can contain layer
	# - @nplt_nMill

	# Exception, if "fsch" layer is created. Thus remove "f" and use instead onlz "fch" layer
	# "f_sch" contains final rout, which have right set footdown
	my @fsch = grep { $_->{"gROWname"} =~ /fsch/i } @nplt_nMill;

	if ( scalar(@fsch) > 0 ) {
		@nplt_nMill = grep { $_->{"gROWname"} !~ /^f[0-9]*$/i } @nplt_nMill;
	}

	# add all @nplt_nDrill which has dir from top2bot
	my @nplt_nDrill_t2b = grep { $_->{"gROWdrl_dir"} ne "bot2top" } @nplt_nDrill;
	my @layers = ( @nplt_nMill, @nplt_nDrill_t2b );

	$opManager->AddOperationDef( "fc" . $stackup->GetPressCount(), \@layers, $stackup->GetPressCount() );

	# 7) Operation name = rs - can contain layer
	# - @nplt_rsMill
	$opManager->AddOperationDef( "rs", \@nplt_rsMill, $stackup->GetPressCount() );

	# 8) Operation name = fr - can contain layer
	# - @nplt_frMill
	$opManager->AddOperationDef( "fr", \@nplt_frMill, $stackup->GetPressCount() );

	# 9) Operation name = k - can contain layer
	# - @nplt_kMill
	$opManager->AddOperationDef( "fk", \@nplt_kMill, $stackup->GetPressCount() );

	# 10) Operation name = flc - can contain layer
	# - @nplt_lcMill
	$opManager->AddOperationDef( "flc", \@nplt_lcMill, -1 );

	# 11) Operation name = fls - can contain layer
	# - @nplt_lsMill
	$opManager->AddOperationDef( "fls", \@nplt_lsMill, -1 );

	# 11) Operation name = fls - can contain layer
	$opManager->AddOperationDef( "coverlayc", \@nplt_cvrlycMill, -1 );

	# 11) Operation name = fls - can contain layer
	$opManager->AddOperationDef( "coverlays", \@nplt_cvrlysMill, -1 );

	# 11) Operation name = fls - can contain layer
	$opManager->AddOperationDef( "prepreg", \@nplt_prepregMill, -1 );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

