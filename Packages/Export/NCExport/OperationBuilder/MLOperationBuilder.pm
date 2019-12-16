
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
use List::Util qw(first);

#local library
use aliased 'Packages::Export::NCExport::Helpers::DrillingHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsDrill';

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

	my $stackup = Stackup->new( $self->{"inCAM"}, $self->{'jobId'} );
	$self->{'stackup'} = $stackup;                                                 #hash
	$self->{'stackupNC'} = StackupNC->new( $self->{"inCAM"}, $self->{'jobId'} );

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
	my $viaFillOuter = CamDrilling->GetViaFillExists( $self->{"inCAM"}, $self->{"jobId"}, EnumsDrill->ViaFill_OUTER );

	# 1) Create group FROM TOP depend on pressing order

	my %pressProducts = $stackup->GetPressProducts();

	foreach my $pressOrder ( keys %pressProducts ) {

		my $press = $pressProducts{$pressOrder};

		my @operations = ();
		my $name       = "";

		#group for last pressing
		if ( $pressOrder == $stackup->GetPressCount() ) {

			$name = "c" . $stackup->GetPressCount() . ( $viaFillOuter ? "_d" : "" );

			#if exist, add normal drill + blind from top
			my $operC = $opManager->GetOperationDef( "c" . $pressOrder . ( $viaFillOuter ? "_d" : "" ) );
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

	foreach my $pressOrder ( keys %pressProducts ) {

		my $press = $pressProducts{$pressOrder};

		my @operations = ();
		my $name       = "";

		#group for last pressing
		if ( $pressOrder == $stackup->GetPressCount() ) {

			$name = "s" . $stackup->GetPressCount() . ( $viaFillOuter ? "_d" : "" );

			#if exist, add normal drill + blind from top
			my $operS = $opManager->GetOperationDef( "s" . $pressOrder . ( $viaFillOuter ? "_d" : "" ) );
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
	my %pressProducts = $stackup->GetPressProducts();

	foreach my $pressOrder ( keys %pressProducts ) {

		my $press = $pressProducts{$pressOrder};

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
	my $pressCnt     = $stackupNC->GetPressCount();
	my $coreCnt      = $stackupNC->GetCoreCnt();
	my $viaFillOuter = CamDrilling->GetViaFillExists( $self->{"inCAM"}, $self->{"jobId"}, EnumsDrill->ViaFill_OUTER );

	#plated
	my @plt_nDrill        = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nDrill } };           #normall through holes plated
	my @plt_nFillDrill    = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nFillDrill } };       # normall filledthrough holes plated
	my @plt_cDrill        = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_cDrill } };           #core plated
	my @plt_cFillDrill    = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_cFillDrill } };       #filled core plated
	my @plt_bDrillTop     = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bDrillTop } };        #blind holes top
	my @plt_bDrillBot     = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bDrillBot } };        #blind holes bot
	my @plt_bFillDrillTop = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bFillDrillTop } };    # filled blind holes top
	my @plt_bFillDrillBot = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bFillDrillBot } };    # filled blind holes bot
	my @plt_fDrill        = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_fDrill } };           #frame drilling
	my @plt_fcDrill       = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_fcDrill } };          # coreframe drilling
	my @plt_nMill         = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_nMill } };            #normall mill slits
	my @plt_bMillTop      = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bMillTop } };         #z-axis top mill slits
	my @plt_bMillBot      = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_bMillBot } };         #z-axis bot mill slits
	my @plt_dcDrill       = @{ $pltDrillInfo{ EnumsGeneral->LAYERTYPE_plt_dcDrill } };          #drill crosses

	#Define operation:

	# 1) Operation name = p<semi-product>c<press order>, can contain layer
	# - @plt_nDrill
	# - @plt_fDrill
	# - @plt_bDrillTop
	# - @plt_nFillDrill
	# - @plt_bFillDrillTop

	my @NCInputPrdts = grep { $_->GetIProduct()->GetIsParent() } $stackupNC->GetNCInputProducts();

	foreach my $NCInputP (@NCInputPrdts) {

		my $pId = $NCInputP->GetIProduct()->GetId();

		my $outFile = "p" . $pId . "c1";
		my @layers  = ();

		my $startTop     = $NCInputP->GetTopCopperNum();
		my $startTopName = $NCInputP->GetTopCopperLayer();

		# plated normal drilling "m" start from top in layer <$drillStartTop>
		my @normalTop = $NCInputP->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nDrill, 1 );

		my @normalTopRes = ();
		foreach my $NCP (@normalTop) {
			push( @normalTopRes, first { $_->{"gROWname"} eq $NCP->{"gROWname"} } @plt_nDrill );
		}

		push( @layers, @normalTopRes ) if ( scalar(@normalTopRes) );

		# blind drilling start from top in layer <$drillStartTop>
		my @blindTop = $NCInputP->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bDrillTop, 1 );
		my @blindTopRes = ();
		foreach my $NCP (@blindTop) {
			push( @blindTopRes, first { $_->{"gROWname"} eq $NCP->{"gROWname"} } @plt_bDrillTop );
		}

		push( @layers, @blindTopRes ) if ( scalar(@blindTopRes) );

		# filled plated drilling "mfill" start from top in layer <$drillStartTop>
		my @normalFillTop = $NCInputP->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_nFillDrill, 1 );

		my @normalFillTopRes = ();
		foreach my $NCP (@normalFillTop) {
			push( @normalFillTopRes, first { $_->{"gROWname"} eq $NCP->{"gROWname"} } @plt_nFillDrill );
		}
		push( @layers, @normalFillTopRes ) if ( scalar(@normalFillTopRes) );

		# filled blind drilling "mfill" start from top in layer <$drillStartTop>
		my @blindFillTop = $NCInputP->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, 1 );

		my @blindFillTopRes = ();
		foreach my $NCP (@blindFillTop) {
			push( @blindFillTopRes, first { $_->{"gROWname"} eq $NCP->{"gROWname"} } @plt_bFillDrillTop );
		}
		push( @layers, @blindFillTopRes ) if ( scalar(@blindFillTopRes) );

		push( @layers, $plt_fcDrill[0] ) if ( scalar(@plt_fcDrill) == 1 );

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, "1" );
	}

	# 1) Operation name = p<semi-product>s<press order>, can contain layer
	# - @plt_bDrillBot
	# - @plt_bFillDrillBot

	foreach my $NCInputP (@NCInputPrdts) {

		my $pId = $NCInputP->GetIProduct()->GetId();

		my $outFile = "p" . $pId . "s1";
		my @layers  = ();

		my $startBot     = $NCInputP->GetBotCopperNum();
		my $startBotName = $NCInputP->GetBotCopperLayer();

		# blind drilling start from top in layer <$drillStartTop>
		my @blindBot = $NCInputP->GetNCLayers( StackEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bDrillBot, 1 );
		my @blindBotRes = ();
		foreach my $NCP (@blindBot) {
			push( @blindBotRes, first { $_->{"gROWname"} eq $NCP->{"gROWname"} } @plt_bDrillBot );
		}

		push( @layers, @blindBotRes ) if ( scalar(@blindBotRes) );

		# filled blind drilling "mfill" start from top in layer <$drillStartTop>
		my @blindFillBot = $NCInputP->GetNCLayers( StackEnums->SignalLayer_BOT, undef, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot, 1 );
		my @blindFillBotRes = ();
		foreach my $NCP (@blindFillBot) {
			push( @blindFillBotRes, first { $_->{"gROWname"} eq $NCP->{"gROWname"} } @plt_bFillDrillBot );
		}

		push( @layers, @blindFillBotRes ) if ( scalar(@blindFillBotRes) );

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, "1" );
	}

	#Define operation:

	# 1) Operation name = c/c_d<press order>, can contain layer
	# - @plt_nDrill
	# - @plt_fDrill
	# - @plt_bDrillTop
	# - @plt_nFillDrill
	# - @plt_bFillDrillTop

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;
		my $press      = $stackupNC->GetNCPressProduct($pressOrder);

		my $outFile = "c" . $pressOrder . ( $viaFillOuter && $pressOrder == $stackup->GetPressCount() ? "_d" : "" );    # Add "_d" if viafill
		my @layers = ();

		my $startTop     = $press->GetTopCopperNum();
		my $startTopName = $press->GetTopCopperLayer();

		# plated normal drilling "m" start from top in layer <$drillStartTop>
		my @normalTop = grep { $_->{"NCSigStartOrder"} == $startTop } @plt_nDrill;
		push( @layers, @normalTop );

		# blind drilling start from top in layer <$drillStartTop>
		my @blindTop = grep { $_->{"NCSigStartOrder"} == $startTop } @plt_bDrillTop;
		push( @layers, @blindTop );

	 
		# filled blind drilling "mfill" start from top in layer <$drillStartTop>
		push( @layers, grep { $_->{"NCSigStartOrder"} == $startTop } @plt_bFillDrillTop );

		if ( $pressOrder == $stackup->GetPressCount() && !$viaFillOuter ) {

			#when it is last pressing, add "v" frame

			push( @layers, $plt_fDrill[0] ) if ( scalar(@plt_fDrill) == 1 );

		}
		elsif ( $pressOrder != $stackup->GetPressCount() ) {

			#for each pressing except last, add "v1" frame drilling
			if ( !$press->ExistNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_cDrill ) ) {

				my $v1 = first { $_->{"gROWname"} eq "v1" } @plt_fcDrill;
				push( @layers, $v1 );
			}
		}

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, $pressOrder );

	}

	# 2) Operation name = s<press order>, can contain layer
	# - @plt_nDrill
	# - @plt_bDrillBot
	# - @plt_bFillDrillBot
	my %pressProducts = $stackup->GetPressProducts();

	foreach my $pressOrder ( keys %pressProducts ) {

		my $press = $pressProducts{$pressOrder};

		my $outFile = "s" . $pressOrder . ( $viaFillOuter && $pressOrder == $stackup->GetPressCount() ? "_d" : "" );    # Add "_d" if viafill
		my @layers = ();

		my $startBot     = $press->GetBotCopperNum();
		my $startBotName = $press->GetBotCopperLayer();

		#blind drilling start from bot in layer <$drillStartTop>
		my @blindBot = grep { $_->{"NCSigStartOrder"} == $startBot } @plt_bDrillBot;
		push( @layers, @blindBot );

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, $pressOrder );
	}

	# 3) Operation name = c<press order>, can contain layers:
	# - @plt_fDrill
	# - @plt_nFillDrill
	# - @plt_bFillDrillTop
	# Only if exist via fill outer
	# Via fill layer can start only from very top
	if ($viaFillOuter) {

		my $press = $pressProducts{ $stackup->GetPressCount() };

		my $outFile = "c" . $stackup->GetPressCount();
		my @layers  = ();

		my $startTop     = $press->GetTopCopperNum();
		my $startTopName = $press->GetTopCopperLayer();

		# frame drilling if viafill
		push( @layers, $plt_fDrill[0] );

		#normal filled drilling start from top
		push( @layers, grep { $_->{"NCSigStartOrder"} == $startTop } @plt_nFillDrill );

		#filled blind drilling start from top
		push( @layers, grep { $_->{"NCSigStartOrder"} == $startTop } @plt_bFillDrillTop );

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, $stackup->GetPressCount() );
	}

	# 4) Operation name = s<press order>, can contain layer
	# - @plt_bFillDrillBot
	# Only if exist via fill
	# Via fill layer can start only from very bot layer
	if ($viaFillOuter) {

		my $press = $pressProducts{ $stackup->GetPressCount() };

		my $outFile = "s" . $stackup->GetPressCount();
		my @layers  = ();

		my $startBot     = $press->GetBotCopperNum();
		my $startBotName = $press->GetBotCopperLayer();

		#filled blind drilling start from top
		push( @layers, grep { $_->{"NCSigStartOrder"} == $startBot } @plt_bFillDrillBot );

		my $oDef = $opManager->AddOperationDef( $outFile, \@layers, $stackup->GetPressCount() );
	}

	# 5) Operation name = r - can contain layer
	# - @plt_nMill
	$opManager->AddOperationDef( "r" . $stackup->GetPressCount(), \@plt_nMill, $stackup->GetPressCount() );

	# 6) Operation name = rzc - can contain layer
	# - @plt_bMillTop
	$opManager->AddOperationDef( "rzc" . $stackup->GetPressCount(), \@plt_bMillTop, $stackup->GetPressCount() );

	# 7) Operation name = rzs - can contain layer
	# - @plt_bMillBot
	$opManager->AddOperationDef( "rzs" . $stackup->GetPressCount(), \@plt_bMillBot, $stackup->GetPressCount() );

	# 8) Operation name = j<core number> - can contain layers from
	# - @plt_cDrill
	# - @plt_cFillDrill
	# - @plt_fcDrill
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $coreNum = $i + 1;
		my $core    = $stackupNC->GetNCCoreProduct($coreNum);

		my @layers = ();
		my @layersCore = $core->GetNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_cDrill );

		# if exist core drilling
		if ( scalar(@layersCore) ) {

			my @layersFiltr = ();

			foreach my $l ( @plt_cDrill, @plt_cFillDrill ) {

				my $exist = scalar( grep { $_->{"gROWname"} eq $l->{"gROWname"} } @layersCore );

				if ($exist) {
					push( @layers, $l );
				}

			}

			# Add frame
			# Get core frame drilling for this specific core (if not exist, tak default)
			my $vCore = first { $_->{"gROWname"} eq "v1j$coreNum" } @plt_fcDrill;
			unless ( defined $vCore ) {
				$vCore = first { $_->{"gROWname"} eq "v1" } @plt_fcDrill;
			}
			push( @layers, $vCore );

			$opManager->AddOperationDef( "j" . $core->GetIProduct()->GetCoreNumber(), \@layers, 0 );
		}
	}

	# 9) Operation name = ds, can contain layer
	# - @plt_dsDrill
	$opManager->AddOperationDef( "dc", \@plt_dcDrill, $stackup->GetPressCount() );

	# 10) Operation name = v1, can contain layer
	# - @plt_fcDrill

	# Find cores, which has not blind or core drilling
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $coreNum = $i + 1;
		my $coreNC  = $stackupNC->GetNCCoreProduct($coreNum);

		# start/stop plated NC layers in core
		my @ncLayers = ();
		if (!$coreNC->ExistNCLayers( undef, undef, undef, 1 ) ) {

			# Get core frame drilling for this specific core
			my $vCore = first { $_->{"gROWname"} eq "v1j$coreNum" } @plt_fcDrill;

			$opManager->AddOperationDef( "v$coreNum", [$vCore], $stackup->GetPressCount() ) if(defined $vCore);
		}
	}

	# If no specific core frame drilling, and no core drilling export universal v1
	if ( !scalar( grep { $_->{"gROWname"} =~ /v1j\d+/ } @plt_fcDrill ) && !scalar(@plt_cDrill) ) {

		my $v1 = first { $_->{"gROWname"} eq "v1" } @plt_fcDrill;

		$opManager->AddOperationDef( "v1", [$v1], $stackup->GetPressCount() );
	}

}

# Create single operations, which represent operation on technical procedure
# Every operation containc name of exportin nc file, layers to merging
sub __DefineNPlatedOperations {
	my $self      = shift;
	my $opManager = shift;

	my %npltDrillInfo = %{ $self->{"npltDrillInfo"} };    #contain array of hashes of all NC layers with info (start/stop drill layer)
	my $stackup       = $self->{'stackup'};               #info about press count, which layer are pressed, etc..

	my $stackupNC = StackupNC->new( $self->{"inCAM"}, $self->{'jobId'} );
	my $coreCnt = $stackupNC->GetCoreCnt();

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

	my @nplt_stiffcMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_stiffcMill } };    # milling for stiffener from side c
	my @nplt_stiffsMill = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_stiffsMill } };    # milling for stiffener from side s
	my @nplt_soldcMill  = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_soldcMill } };     # milling of template for soldering coverlay from side c
	my @nplt_soldsMill  = @{ $npltDrillInfo{ EnumsGeneral->LAYERTYPE_nplt_soldsMill } };     # milling of template for soldering coverlay from side s

	#Define operation:
	my %pressProducts = $stackup->GetPressProducts();

	# 1) Operation name = fzc<press order>, can contain layer
	# - @nplt_bMillTop
	# - @nplt_nDrill

	foreach my $pressOrder ( keys %pressProducts ) {

		my $press   = $pressProducts{$pressOrder};
		my $outFile = "fzc" . $pressOrder;
		my @layers  = ();

		my $startTop     = $press->GetTopCopperNum();
		my $startTopName = $press->GetTopCopperLayer();

		#blind milling start from top in layer <$drillStartTop>
		my @blindTop = grep { $_->{"NCSigStartOrder"} == $startTop } @nplt_bMillTop;
		push( @layers, @blindTop );

		$opManager->AddOperationDef( $outFile, \@layers, $pressOrder );
	}

	# 2) Operation name = fzs<press order>, can contain layer
	# - @nplt_bMillBot
	# - @nplt_nDrill

	foreach my $pressOrder ( keys %pressProducts ) {

		my $press   = $pressProducts{$pressOrder};
		my $outFile = "fzs" . $pressOrder;
		my @layers  = ();

		my $startBot     = $press->GetBotCopperNum();
		my $startBotName = $press->GetBotCopperLayer();

		#blind milling start from top in layer <$drillStartTop>
		my @blindBot = grep { $_->{"NCSigStartOrder"} == $startBot } @nplt_bMillBot;
		push( @layers, @blindBot );

		# add all @nplt_nDrill which has dir from bot2top
		my @nplt_nDrill_b2t = grep { $_->{"gROWdrl_dir"} eq "bot2top" && $_->{"NCSigStartOrder"} == $startBot } @nplt_nDrill;

		# Exception, if "fsch_d" layer is created. Remove "d" and use instead only "fsch_d" layer
		# fsch_d contain nplt drills from layer fsch
		if ( scalar( grep { $_->{"gROWname"} =~ /fsch_d/i } @nplt_nDrill_b2t ) > 0 ) {

			die "Layer \"d\" must exist if exist layer \"fsch_d\"" unless ( grep { $_->{"gROWname"} =~ /^d$/i } @nplt_nDrill_b2t );
			@nplt_nDrill_b2t = grep { $_->{"gROWname"} !~ /^d$/i } @nplt_nDrill_b2t;
		}

		push( @layers, @nplt_nDrill_b2t );

		$opManager->AddOperationDef( $outFile, \@layers, $pressOrder );
	}

	# 4) Operation name = jfzc<core number> - can contain layer from @nplt_cbMillTop
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $core = $stackup->GetCore( $i + 1 );

		my @jLayers = grep { $_->{"NCSigStartOrder"} == $core->GetTopCopperLayer()->GetCopperNumber() } @nplt_cbMillTop;

		$opManager->AddOperationDef( "j" . $core->GetCoreNumber() . "fzc", \@jLayers, 0 );
	}

	# 5) Operation name = jfzs<core number> - can contain layer from @nplt_cbMillBot
	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $core = $stackup->GetCore( $i + 1 );

		my @jLayers = grep { $_->{"NCSigStartOrder"} == $core->GetBotCopperLayer()->GetCopperNumber() } @nplt_cbMillBot;

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

	# Exception, if "fsch_d" layer is created. Remove "d" and use instead only "fsch_d" layer
	# fsch_d contain nplt drills from layer fsch
	if ( scalar( grep { $_->{"gROWname"} =~ /fsch_d/i } @nplt_nDrill_t2b ) > 0 ) {
		die "Layer \"d\" must exist if exist layer \"fsch_d\"" unless ( grep { $_->{"gROWname"} =~ /^d$/i } @nplt_nDrill_t2b );
		@nplt_nDrill_t2b = grep { $_->{"gROWname"} !~ /^d$/i } @nplt_nDrill_t2b;
	}
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
	foreach my $l (@nplt_prepregMill) {

		my ($prepregNum) = $l->{"gROWname"} =~ /^fprepreg(\d)$/;

		$opManager->AddOperationDef( "prepreg" . $prepregNum, [$l], -1 );
	}

	# 12) Operation name = fstiffc - can contain layer
	# - @nplt_stiffcMill
	$opManager->AddOperationDef( "fstiffc", \@nplt_stiffcMill, -1 );

	# 13) Operation name = fstiffs - can contain layer
	# - @nplt_stiffcMill
	$opManager->AddOperationDef( "fstiffs", \@nplt_stiffsMill, -1 );

	# 14) Operation name = soldc - can contain layer
	# - @nplt_soldcMill
	$opManager->AddOperationDef( "soldc", \@nplt_soldcMill, -1 );

	# 15) Operation name = soldc - can contain layer
	# - @nplt_soldsMill
	$opManager->AddOperationDef( "solds", \@nplt_soldsMill, -1 );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

