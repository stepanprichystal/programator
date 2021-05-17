
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
use aliased 'CamHelpers::CamHistogram';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAM::UniRTM::UniRTM';

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

		my $rsExist = $self->__RoutExists( [EnumsGeneral->LAYERTYPE_nplt_rsMill ]);

		$section->AddRow( "freza_pred_leptanim", $rsExist );
	}

	# comment
	$section->AddComment(" Frezovani Pred Prokovem ");

	#freza_pred (freza pred prokovem)
	if ( $self->_IsRequire("frezovani_pred") ) {

		my $existPltMill = $self->__RoutExists( [EnumsGeneral->LAYERTYPE_plt_nMill] );
		$section->AddRow( "frezovani_pred", $existPltMill );
	}

	#freza_pred_delka
	if ( $self->_IsRequire("freza_pred_delka") ) {

		my $dist = $self->__GetRoutDistance( $stepName, [EnumsGeneral->LAYERTYPE_plt_nMill] );
		$section->AddRow( "freza_pred_delka", $dist );
	}

	#min_freza_pred
	if ( $self->_IsRequire("min_freza_pred") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, [EnumsGeneral->LAYERTYPE_plt_nMill] );

		$section->AddRow( "min_freza_pred", $minTool );
	}

	#comment*
	$section->AddComment("Frezovani Po Prokovu ");

	#freza_po (freza po prokovu)
	if ( $self->_IsRequire("frezovani_po") ) {

		my $existNPltMill = $self->__RoutExists( [EnumsGeneral->LAYERTYPE_nplt_nMill ]);

		$section->AddRow( "frezovani_po", $existNPltMill );
	}

	#freza_po_delka
	if ( $self->_IsRequire("freza_po_delka") ) {

		my $dist = $self->__GetRoutDistance( $stepName, [ EnumsGeneral->LAYERTYPE_nplt_nMill ]);
		$section->AddRow( "freza_po_delka", $dist );
	}

	#min_freza_po
	if ( $self->_IsRequire("min_freza_po") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, [EnumsGeneral->LAYERTYPE_nplt_nMill ]);

		$section->AddRow( "min_freza_po", $minTool );
	}

	# comment
	$section->AddComment(" HLOUBKOVE FREZOVANI ");

	# comment
	$section->AddComment(" Hloubkove Frezovani Pred Prokovem C ");

	#freza_hloubkova_pred_c
	if ( $self->_IsRequire("frezovani_hloubkove_pred_c") ) {

		my $exist = $self->__RoutExists( [EnumsGeneral->LAYERTYPE_plt_bMillTop] );
		$section->AddRow( "frezovani_hloubkove_pred_c", $exist );
	}

	#freza_hloubkova_pred_delka_c
	if ( $self->_IsRequire("freza_hloubkova_pred_delka_c") ) {

		my $dist = $self->__GetRoutDistance( $stepName, [EnumsGeneral->LAYERTYPE_plt_bMillTop] );
		$section->AddRow( "freza_hloubkova_pred_delka_c", $dist );
	}

	#min_freza_hloubkova_pred_c
	if ( $self->_IsRequire("min_freza_hloubkova_pred_c") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, [EnumsGeneral->LAYERTYPE_plt_bMillTop ]);
		$section->AddRow( "min_freza_hloubkova_pred_c", $minTool );
	}

	# comment
	$section->AddComment(" Hloubkove Frezovani Pred Prokovem S ");

	#freza_hloubkova_pred_s
	if ( $self->_IsRequire("frezovani_hloubkove_pred_s") ) {

		my $exist = $self->__RoutExists([ EnumsGeneral->LAYERTYPE_plt_bMillBot] );
		$section->AddRow( "frezovani_hloubkove_pred_s", $exist );
	}

	#freza_hloubkova_pred_delka_s
	if ( $self->_IsRequire("freza_hloubkova_pred_delka_s") ) {

		my $dist = $self->__GetRoutDistance( $stepName, [EnumsGeneral->LAYERTYPE_plt_bMillBot] );
		$section->AddRow( "freza_hloubkova_pred_delka_s", $dist );
	}

	#min_freza_hloubkova_pred_s
	if ( $self->_IsRequire("min_freza_hloubkova_pred_s") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, [ EnumsGeneral->LAYERTYPE_plt_bMillBot ]);
		$section->AddRow( "min_freza_hloubkova_pred_s", $minTool );
	}

	# comment
	$section->AddComment(" Hloubkove Frezovani Po Prokovu C ");

	#freza_hloubkova_po_c
	if ( $self->_IsRequire("frezovani_hloubkove_po_c") ) {

		my $exist = $self->__RoutExists( [ EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill ] );
		$section->AddRow( "frezovani_hloubkove_po_c", $exist );
	}

	#freza_hloubkova_po_delka_c
	if ( $self->_IsRequire("freza_hloubkova_po_delka_c") ) {

		my $dist = $self->__GetRoutDistance( $stepName, [ EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill ] );
		$section->AddRow( "freza_hloubkova_po_delka_c", $dist );
	}

	#min_freza_hloubkova_po_c
	if ( $self->_IsRequire("min_freza_hloubkova_po_c") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, [ EnumsGeneral->LAYERTYPE_nplt_bMillTop, EnumsGeneral->LAYERTYPE_nplt_bstiffcMill ] );
		$section->AddRow( "min_freza_hloubkova_po_c", $minTool );
	}

	# comment
	$section->AddComment(" Hloubkove Frezovani Po Prokovu S ");

	#freza_hloubkova_po_s
	if ( $self->_IsRequire("frezovani_hloubkove_po_s") ) {

		my $exist = $self->__RoutExists( [ EnumsGeneral->LAYERTYPE_nplt_bMillBot, EnumsGeneral->LAYERTYPE_nplt_bstiffsMill ] );
		$section->AddRow( "frezovani_hloubkove_po_s", $exist );
	}

	#freza_hloubkova_po_delka_s
	if ( $self->_IsRequire("freza_hloubkova_po_delka_s") ) {

		my $dist = $self->__GetRoutDistance( $stepName, [ EnumsGeneral->LAYERTYPE_nplt_bMillBot, EnumsGeneral->LAYERTYPE_nplt_bstiffsMill ] );
		$section->AddRow( "freza_hloubkova_po_delka_s", $dist );
	}

	#min_freza_hloubkova_po_s
	if ( $self->_IsRequire("min_freza_hloubkova_po_s") ) {

		my $minTool = $self->__GetMinSlotTool( $stepName, [ EnumsGeneral->LAYERTYPE_nplt_bMillBot, EnumsGeneral->LAYERTYPE_nplt_bstiffsMill ] );
		$section->AddRow( "min_freza_hloubkova_po_s", $minTool );
	}

}

sub __GetMinSlotTool {
	my $self       = shift;
	my $stepName   = shift;
	my $layerTypes = shift;
	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};

	my $minTool = undef;
	
	
	foreach my $layerType  (@{$layerTypes}){
	
		my $curTool = CamRouting->GetMinSlotTool( $inCAM, $jobId, $stepName, $layerType );
		
		if(!defined $minTool || $curTool < $minTool){
			
			$minTool = $curTool;
		}
	}
 

	if ( defined $minTool ) {
		$minTool = sprintf "%0.2f", ( $minTool / 1000 );
	}
	else {
		$minTool = "";
	}

	return $minTool;
}

sub __RoutExists {
	my $self       = shift;
	my $layerTypes = shift;
	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};

	my $exist = 0;

	foreach my $layerType ( @{$layerTypes} ) {

		if ( CamDrilling->NCLayerExists( $inCAM, $jobId, $layerType ) ) {
			$exist = 1;
			last;
		}
	}

	my $existRout = undef;
	if ($exist) {
		$existRout = "A";
	}
	else {
		$existRout = "N";
	}

	return $existRout;
}

sub __GetRoutDistance {
	my $self       = shift;
	my $stepName   = shift;
	my $layerTypes = shift;
	my $inCAM      = $self->{"inCAM"};
	my $jobId      = $self->{"jobId"};

	my $total = undef;

	my @res = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $layerTypes );

	# If Exist fsch, then compute only f length, not f + fsch
	@res = grep { $_->{"gROWname"} ne "fsch" } @res;

	# if there is no rout return
	unless ( scalar(@res) ) {

		$total = "";
		return $total;
	}

	foreach my $layer (@res) {
		$total = 0;
		$self->__GetStepRoutLen( $inCAM, $jobId, $stepName, $layer->{"gROWname"}, \$total );
	}

	if ($total) {
		$total = sprintf( "%.2f", $total );

		if ( $total == 0 ) {
			$total = "";
		}
	}

	return $total;
}

sub __GetStepRoutLen {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $exploreStep = shift;
	my $layer       = shift;
	my $totalLen    = shift;

	my @sr = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobId, $exploreStep );
	my @childs = CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, $exploreStep );

	die "Step $exploreStep doesn't contain Step and Repeat" unless ( scalar(@sr) );

	if ( scalar(@childs) ) {

		# recusive search another nested steps
		foreach my $ch (@childs) {

			my $childLen = 0;

			if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $ch->{"stepName"} ) ) {

				$self->__GetStepRoutLen( $inCAM, $jobId, $ch->{"stepName"}, $layer, \$childLen );

				my @chStepsInfo = grep { $_->{"gSRstep"} eq $ch->{"stepName"} } @sr;
				foreach my $chStepInfo (@chStepsInfo) {
					$$totalLen += $chStepInfo->{"gSRnx"} * $chStepInfo->{"gSRny"} * $childLen;
				}
			}
			else {

				# child rout layer
				my $chRoutLen = $self->__GetRoutLen( $inCAM, $jobId, $ch->{"stepName"}, $layer );

				# get number of this child in theses parent step
				my @chStepsInfo = grep { $_->{"gSRstep"} eq $ch->{"stepName"} } @sr;

				foreach my $chStepInfo (@chStepsInfo) {
					$$totalLen += $chStepInfo->{"gSRnx"} * $chStepInfo->{"gSRny"} * $chRoutLen;
				}
			}
		}

		# compute rout len in this step
		$$totalLen += $self->__GetRoutLen( $inCAM, $jobId, $exploreStep, $layer );

	}
}

sub __GetRoutLen {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my $layer    = shift;

	# if layer contain surfaces, do compensate
	my $comp  = 0;
	my $routL = $layer;

	my %fHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $stepName, $layer, 0 );

	if ( $fHist{"surf"} > 0 ) {

		$comp = 1;

	}

	# if layer contain SR, copy data to other layer first
	if ( $fHist{"surf"} > 0 ) {

		$comp = 1;
		CamHelper->SetStep( $inCAM, $stepName );

		if ( CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepName ) ) {

			my $tmp = GeneralHelper->GetGUID();
			$inCAM->COM( "merge_layers", "source_layer" => $layer, "dest_layer" => $tmp );
			$routL = GeneralHelper->GetGUID();
			$inCAM->COM( 'compensate_layer', "source_layer" => $tmp, "dest_layer" => $routL, "dest_layer_type" => 'rout' );
			CamMatrix->DeleteLayer( $inCAM, $jobId, $tmp );
		}
		else {

			CamHelper->SetStep( $inCAM, $stepName );
			$routL = GeneralHelper->GetGUID();
			$inCAM->COM( 'compensate_layer', "source_layer" => $layer, "dest_layer" => $routL, "dest_layer_type" => 'rout' );
		}

	}

	my $rtm = UniRTM->new( $inCAM, $jobId, $stepName, $routL );

	CamMatrix->DeleteLayer( $inCAM, $jobId, $routL ) if ($comp);

	# compute length of one step
	my $chTotal = 0;

	foreach my $seq ( $rtm->GetChainSequences() ) {
		foreach my $f ( $seq->GetFeatures() ) {

			die "No length defined for rout feature" unless ( defined $f->{"length"} );

			$chTotal += $f->{"length"};
		}
	}

	return $chTotal;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

