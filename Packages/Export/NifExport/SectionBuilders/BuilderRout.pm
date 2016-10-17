
#-------------------------------------------------------------------------------------------#
# Description: Build section about rout information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderRout;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamRouting';

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
	my $stepName = "panel";
	my %nifData  = %{ $self->{"nifData"} };

	# comment
	$section->AddComment(" Frezovani skrz ");

	# comment
	$section->AddComment(" Frezovani Pred Leptanim ");

	#freza_pred_leptanim
	if ( $self->_IsRequire("freza_pred_leptanim") ) {

		my $rsExist = $self->__RoutExists( EnumsGeneral->LAYERTYPE_nplt_rsMill );

		$section->AddRow( "freza_pred_leptanim", $rsExist );
	}

	# comment
	$section->AddComment(" Frezovani Pred Prokovem ");

	#freza_pred (freza pred prokovem)
	if ( $self->_IsRequire("frezovani_pred") ) {

		my $existPltMill = $self->__RoutExists( EnumsGeneral->LAYERTYPE_plt_nMill );
		$section->AddRow( "frezovani_pred", $existPltMill );
	}

	#freza_pred_delka
	if ( $self->_IsRequire("freza_pred_delka") ) {

		my $dist = $self->__GetRoutDistance( $stepName, EnumsGeneral->LAYERTYPE_plt_nMill );
		$section->AddRow( "freza_pred_delka", $dist );
	}

	#min_freza_pred
	if ( $self->_IsRequire("min_freza_pred") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, EnumsGeneral->LAYERTYPE_plt_nMill );

		$section->AddRow( "min_freza_pred", $minTool );
	}

	#comment*
	$section->AddComment("Frezovani Po Prokovu ");

	#freza_po (freza po prokovu)
	if ( $self->_IsRequire("frezovani_po") ) {

		my $existNPltMill = $self->__RoutExists( EnumsGeneral->LAYERTYPE_nplt_nMill );

		$section->AddRow( "frezovani_po", $existNPltMill );
	}

	#freza_po_delka
	if ( $self->_IsRequire("freza_po_delka") ) {

		my $dist = $self->__GetRoutDistance( $stepName, EnumsGeneral->LAYERTYPE_nplt_nMill );
		$section->AddRow( "freza_po_delka", $dist );
	}

	#min_freza_po
	if ( $self->_IsRequire("min_freza_po") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, EnumsGeneral->LAYERTYPE_nplt_nMill );

		$section->AddRow( "min_freza_po", $minTool );
	}

	# comment
	$section->AddComment(" HLOUBKOVE FREZOVANI ");

	# comment
	$section->AddComment(" Hloubkove Frezovani Pred Prokovem C ");

	#freza_hloubkova_pred_c
	if ( $self->_IsRequire("frezovani_hloubkove_pred_c") ) {

		my $exist = $self->__RoutExists( EnumsGeneral->LAYERTYPE_plt_bMillTop );
		$section->AddRow( "frezovani_hloubkove_pred_c", $exist );
	}

	#freza_hloubkova_pred_delka_c
	if ( $self->_IsRequire("freza_hloubkova_pred_delka_c") ) {

		my $dist = $self->__GetRoutDistance( $stepName, EnumsGeneral->LAYERTYPE_plt_bMillTop );
		$section->AddRow( "freza_hloubkova_pred_delka_c", $dist );
	}

	#min_freza_hloubkova_pred_c
	if ( $self->_IsRequire("min_freza_hloubkova_pred_c") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, EnumsGeneral->LAYERTYPE_plt_bMillTop );
		$section->AddRow( "min_freza_hloubkova_pred_c", $minTool );
	}

	# comment
	$section->AddComment(" Hloubkove Frezovani Pred Prokovem S ");

	#freza_hloubkova_pred_s
	if ( $self->_IsRequire("frezovani_hloubkove_pred_s") ) {

		my $exist = $self->__RoutExists( EnumsGeneral->LAYERTYPE_plt_bMillBot );
		$section->AddRow( "frezovani_hloubkove_pred_s", $exist );
	}

	#freza_hloubkova_pred_delka_s
	if ( $self->_IsRequire("freza_hloubkova_pred_delka_s") ) {

		my $dist = $self->__GetRoutDistance( $stepName, EnumsGeneral->LAYERTYPE_plt_bMillBot );
		$section->AddRow( "freza_hloubkova_pred_delka_s", $dist );
	}

	#min_freza_hloubkova_pred_s
	if ( $self->_IsRequire("min_freza_hloubkova_pred_s") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, EnumsGeneral->LAYERTYPE_plt_bMillBot );
		$section->AddRow( "min_freza_hloubkova_pred_s", $minTool );
	}

	# comment
	$section->AddComment(" Hloubkove Frezovani Po Prokovu C ");

	#freza_hloubkova_po_c
	if ( $self->_IsRequire("frezovani_hloubkove_po_c") ) {

		my $exist = $self->__RoutExists( EnumsGeneral->LAYERTYPE_nplt_bMillTop );
		$section->AddRow( "frezovani_hloubkove_po_c", $exist );
	}

	#freza_hloubkova_po_delka_c
	if ( $self->_IsRequire("freza_hloubkova_po_delka_c") ) {

		my $dist = $self->__GetRoutDistance( $stepName, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
		$section->AddRow( "freza_hloubkova_po_delka_c", $dist );
	}

	#min_freza_hloubkova_po_c
	if ( $self->_IsRequire("min_freza_hloubkova_po_c") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, EnumsGeneral->LAYERTYPE_nplt_bMillTop );
		$section->AddRow( "min_freza_hloubkova_po_c", $minTool );
	}

	# comment
	$section->AddComment(" Hloubkove Frezovani Po Prokovu S ");

	#freza_hloubkova_po_s
	if ( $self->_IsRequire("frezovani_hloubkove_po_s") ) {

		my $exist = $self->__RoutExists( EnumsGeneral->LAYERTYPE_nplt_bMillBot );
		$section->AddRow( "frezovani_hloubkove_po_s", $exist );
	}

	#freza_hloubkova_po_delka_s
	if ( $self->_IsRequire("freza_hloubkova_po_delka_s") ) {

		my $dist = $self->__GetRoutDistance( $stepName, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
		$section->AddRow( "freza_hloubkova_po_delka_s", $dist );
	}

	#min_freza_hloubkova_po_s
	if ( $self->_IsRequire("min_freza_hloubkova_po_s") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, EnumsGeneral->LAYERTYPE_nplt_bMillBot );
		$section->AddRow( "min_freza_hloubkova_po_s", $minTool );
	}

}

sub __GetMinSlotTool {
	my $self      = shift;
	my $stepName  = shift;
	my $layerType = shift;
	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};

	my $minTool = CamRouting->GetMinSlotTool( $inCAM, $jobId, $stepName, $layerType );

	if ( defined $minTool ) {
		$minTool = sprintf "%0.2f", ( $minTool / 1000 );
	}
	else {
		$minTool = "";
	}

	return $minTool;
}

sub __RoutExists {
	my $self      = shift;
	my $layerType = shift;
	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};

	my $existRout = CamDrilling->NCLayerExists( $inCAM, $jobId, $layerType );
	if ($existRout) {
		$existRout = "A";
	}
	else {
		$existRout = "N";
	}

	return $existRout;
}

sub __GetRoutDistance {
	my $self      = shift;
	my $stepName  = shift;
	my $layerType = shift;
	my $inCAM     = $self->{"inCAM"};
	my $jobId     = $self->{"jobId"};

	my $total = undef;

	my @res = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $layerType );
	
	
	# If Exist fsch, then compute only f length, not f + fsch
	@res = grep { $_->{"gROWname"} ne "fsch"} @res;
	

	# if there is no rout return
	unless ( scalar(@res) ) {

		$total = "";
		return $total;
	}

	foreach my $layer (@res) {

		my $tmpL = GeneralHelper->GetGUID();

		CamHelper->SetStep( $inCAM, $stepName );

		#$inCAM->COM( 'tools_reload');
		#$inCAM->COM( 'tools_tab_reset');
		$inCAM->COM( 'compensate_layer', source_layer => $layer->{"gROWname"}, dest_layer => $tmpL, dest_layer_type => 'rout' );
		$inCAM->COM( 'tools_set', layer => $tmpL, thickness => '0', user_params => ' ', slots => 'by_length' );
		$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$jobId/$stepName/$tmpL", data_type => 'TOOL' );
		my @length = @{ $inCAM->{doinfo}{gTOOLslot_len} };
		my @count  = @{ $inCAM->{doinfo}{gTOOLcount} };

		if ( scalar(@length) && !defined $total ) {
			$total = 0;
		}

		for ( my $i = 0 ; $i < scalar(@length) ; $i++ ) {
			$total += ( $count[$i] * $length[$i] );
		}

		$inCAM->COM( 'delete_layer', layer => $tmpL );
	}

	if ($total) {
		$total = sprintf "%.2f", ( $total / 1000 );

		if ( $total == 0 ) {
			$total = "";
		}
	}

	return $total;
}

#sub __ExistNpthHoles {
#	my $self      = shift;
#	my $stepName  = shift;
#	my $layerType = shift;
#	my $inCAM     = $self->{"inCAM"};
#	my $jobId     = $self->{"jobId"};
#
#	my $exist = 0;
#
#	my @fLayers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $layerType );
#
#	foreach my $layer (@fLayers) {
#
#		$inCAM->INFO(
#					  units       => 'mm',
#					  entity_type => 'layer',
#					  entity_path => "$jobId/$stepName/".$layer->{"gROWname"},
#					  data_type   => 'FEAT_HIST',
#					  options     => "break_sr"
#		);
#		if ( $inCAM->{doinfo}{gFEAT_HISTpad} > 0 )
#		{
#			$exist = 1;
#			last;
#		}
#	}
#
#	if ($exist) {
#		return "A";
#	}
#	else {
#		return "N";
#	}
#}
#
#
#
#sub __GetDepthMillExist {
#	my $self         = shift;
#	my $stepName     = shift;
#	my $layerTypeTop = shift;
#	my $layerTypeBot = shift;
#
#	my $inCAM = $self->{"inCAM"};
#	my $jobId = $self->{"jobId"};
#
#	my $res;
#
#	my $existTop = CamDrilling->NCLayerExists( $inCAM, $jobId, $layerTypeTop );
#	my $existBot = CamDrilling->NCLayerExists( $inCAM, $jobId, $layerTypeTop );
#
#	if ( $existTop && $existBot ) {
#		$res = "2";
#	}
#	elsif ($existTop) {
#		$res = "C";
#	}
#	elsif($existBot) {
#		$res = "S";
#
#	}else{
#		$res = "";
#	}
#
#	return $res;
#}
#
#

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

