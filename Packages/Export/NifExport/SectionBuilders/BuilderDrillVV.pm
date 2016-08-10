
#-------------------------------------------------------------------------------------------#
# Description: Build section about drill multilayer pcb
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderDrillVV;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';

use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::StackupNC::StackupNC';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	return $self;
}

sub Build {

	my $self    = shift;
	my $section = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my %nifData  = %{ $self->{"nifData"} };
	my $stepName = "panel";

	my $stackup   = Stackup->new( $self->{'jobId'} );
	my $stackupNC = StackupNC->new( $inCAM, $stackup );
	my $pressCnt  = $stackupNC->GetPressCnt();

	# comment
	$section->AddComment(" SLEPE VRTANI SKRZ MEZI LISOVANIM ");

	# "-1" number tell, we don't want last pressing, 
	# because it's same as normal drilling, which implement builder BuilderDrill
	for ( my $i = 0 ; $i < $pressCnt - 1 ; $i++ ) {

		my $pressOrder = $i + 1;

		# comment
		$section->AddComment( "Vrtani Pred Prokovem C" . $pressOrder );

		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_nDrill );

		#if ( $self->_IsRequire( "slepe_vrtani_" . $pressOrder . "c" ) ) {
		$section->AddRow( "slepe_vrtani_" . $pressOrder . "c", $existDrill ? "A" : "N" );

		#}

		my $stagesCnt = $press->GetStageCnt( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_nDrill );

		#if ( $self->_IsRequire( "stages_slepe_vrtani_c_" . $pressOrder ) ) {
		$section->AddRow( "stages_slepe_vrtani_c_" . $pressOrder, $stagesCnt );

		#}

		my $minTool = $press->GetMinHoleTool( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_nDrill );

		#if ( $self->_IsRequire( "min_vrtak_c_" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_c_" . $pressOrder, $self->__FormatTool($minTool) );

		#}

		my $maxAspectRatio = $press->GetMaxAspectRatio(Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_nDrill);

		#if ( $self->_IsRequire( "min_vrtak_pomer_c_" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_pomer_c_" . $pressOrder, $maxAspectRatio );

		#}
	}

	# "-1" number tell, we don't want last pressing, 
	# because it's same as normal drilling, which implement builder BuilderDrill
	for ( my $i = 0 ; $i < $pressCnt -1 ; $i++ ) {

		my $pressOrder = $i + 1;

		# comment
		$section->AddComment( "Vrtani Pred Prokovem S" . $pressOrder );

		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_nDrill );

		#if ( $self->_IsRequire( "slepe_vrtani_" . $pressOrder . "s" ) ) {
		$section->AddRow( "slepe_vrtani_" . $pressOrder . "s", $existDrill ? "A" : "N" );

		#}

		my $stagesCnt = $press->GetStageCnt( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_nDrill );

		#if ( $self->_IsRequire( "stages_slepe_vrtani_s_" . $pressOrder ) ) {
		$section->AddRow( "stages_slepe_vrtani_s_" . $pressOrder, $stagesCnt );

		#}

		my $minTool = $press->GetMinHoleTool( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_nDrill );

		#if ( $self->_IsRequire( "min_vrtak_s_" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_s_" . $pressOrder, $self->__FormatTool($minTool) );

		#}

		my $maxAspectRatio = $press->GetMaxAspectRatio(Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_nDrill);

		#if ( $self->_IsRequire( "min_vrtak_pomer_s_" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_pomer_s_" . $pressOrder, $maxAspectRatio );

		#}
	}

	# comment
	$section->AddComment(" SLEPE VRTANI MEZI LISOVANIM ");

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;

		# comment
		$section->AddComment( "Slepe Vrtani C" . $pressOrder );

		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop );

		#if ( $self->_IsRequire( "slepe_otvory_c_" . $pressOrder ) ) {
		$section->AddRow( "slepe_otvory_c_" . $pressOrder, $existDrill ? "A" : "N" );

		#}

		my $minTool = $press->GetMinHoleTool( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop );

		#if ( $self->_IsRequire( "min_vrtak_sl_c_" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_sl_c_" . $pressOrder, $self->__FormatTool($minTool) );

		#}

		my $maxAspectRatio = $press->GetMaxBlindAspectRatio(Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bDrillTop );

		#if ( $self->_IsRequire( "min_vrtak_pomer_sl_c_" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_pomer_sl_c_" . $pressOrder, $maxAspectRatio );

		#}
	}

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;

		# comment
		$section->AddComment( "Slepe Vrtani S" . $pressOrder );

		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot );

		#if ( $self->_IsRequire( "slepe_otvory_s_" . $pressOrder ) ) {
		$section->AddRow( "slepe_otvory_s_" . $pressOrder, $existDrill ? "A" : "N" );

		#}

		my $minTool = $press->GetMinHoleTool( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot );

		#if ( $self->_IsRequire( "min_vrtak_sl_s_" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_sl_s_" . $pressOrder, $self->__FormatTool($minTool) );

		#}

		my $maxAspectRatio = $press->GetMaxBlindAspectRatio(Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bDrillBot );

		#if ( $self->_IsRequire( "min_vrtak_pomer_sl_s_1" . $pressOrder ) ) {
		$section->AddRow( "min_vrtak_pomer_sl_s_" . $pressOrder, $maxAspectRatio );

		#}
	}

}

sub __FormatTool {
	my $self    = shift;
	my $minTool = shift;
	
	if ( defined $minTool ) {
		$minTool =  sprintf "%0.2f", ( $minTool / 1000 );
	}
	else {
		$minTool = "";
	}
	return $minTool;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

