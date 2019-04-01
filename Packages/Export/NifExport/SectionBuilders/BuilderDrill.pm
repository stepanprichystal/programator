
#-------------------------------------------------------------------------------------------#
# Description: Build section about drill information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderDrill;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamRouting';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'CamHelpers::CamStepRepeatPnl';

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
	my $viaFill  = CamDrilling->GetViaFillExists( $inCAM, $jobId );

	# comment
	$section->AddComment( "Vrtani skrz pred prokovem " . ( $viaFill ? "(pred zalpnenim otvoru)" : "" ) );
	my $lType = !$viaFill ? EnumsGeneral->LAYERTYPE_plt_nDrill : EnumsGeneral->LAYERTYPE_plt_nFillDrill;

	#vrtani_pred (vrtani pred prokovem)
	if ( $self->_IsRequire("vrtani_pred") ) {

		my $exist = $self->__DrillExists($lType);
		$section->AddRow( "vrtani_pred", $exist );
	}

	#stages_vrtani_pred
	if ( $self->_IsRequire("stages_vrtani_pred") ) {

		my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $lType );

		my $maxCnt;
		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $cnt = CamDrilling->GetStagesCnt( $jobId, $stepName, $layers[$i]->{"gROWname"}, $inCAM );
			$maxCnt = $cnt if ( !defined $maxCnt || $maxCnt < $cnt );
		}

		$section->AddRow( "stages_vrtani_pred", $maxCnt );
	}

	#otvory (vyelsedne / vrtane  => S/T)
	if ( $self->_IsRequire("otvory") ) {

		$section->AddRow( "otvory", $self->__GetHoleType($lType) );
	}

	#pocet_der
	if ( $self->_IsRequire("pocet_der") ) {
		$section->AddRow( "pocet_der", $self->__GetHoleCnt($lType) );
	}

	#min_vrtak
	if ( $self->_IsRequire("min_vrtak") ) {
		my $minTool = CamDrilling->GetMinHoleTool( $inCAM, $jobId, $stepName, $lType, "c" );

		if ( defined $minTool ) {
			$minTool = sprintf "%0.2f", ( $minTool / 1000 );
		}
		else {
			$minTool = "";
		}

		$section->AddRow( "min_vrtak", $minTool );
	}

	#get general information about drilling
	my ( $holesTypeNum, $aspectRatio ) = ( 0, 0 );

	if ( $self->_IsRequire("pocet_vrtaku") || $self->_IsRequire("min_vrtak_pomer") ) {
		( $holesTypeNum, $aspectRatio ) = $self->__GetInfoDrill( $stepName, $lType );

	}

	#pocet_vrtaku
	if ( $self->_IsRequire("pocet_vrtaku") ) {
		$section->AddRow( "pocet_vrtaku", $holesTypeNum );
	}

	#min_vrtak_pomer
	if ( $self->_IsRequire("min_vrtak_pomer") ) {
		$section->AddRow( "min_vrtak_pomer", $aspectRatio );
	}

	if ($viaFill) {

		# comment
		$section->AddComment("Vrtani skrz pred prokovem po zalpneni otvoru");

		#vrtani_pred (vrtani pred prokovem)
		if ( $self->_IsRequire("vrtani_do_c") ) {

			my $exist = $self->__DrillExists( EnumsGeneral->LAYERTYPE_plt_nDrill );
			$section->AddRow( "vrtani_do_c", $exist );
		}

		#stages_vrtani_pred
		if ( $self->_IsRequire("stages_vrtani_pred_D") ) {

			my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );

			my $maxCnt;
			for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

				my $cnt = CamDrilling->GetStagesCnt( $jobId, $stepName, $layers[$i]->{"gROWname"}, $inCAM );
				$maxCnt = $cnt if ( !defined $maxCnt || $maxCnt < $cnt );
			}

			$section->AddRow( "stages_vrtani_pred_D", $maxCnt );
		}

		#otvory (vyelsedne / vrtane  => S/T)
		if ( $self->_IsRequire("otvory_D") ) {

			$section->AddRow( "otvory_D", $self->__GetHoleType( EnumsGeneral->LAYERTYPE_plt_nDrill ) );
		}

		#pocet_der_D
		if ( $self->_IsRequire("pocet_der_D") ) {
			$section->AddRow( "pocet_der_D", $self->__GetHoleCnt( EnumsGeneral->LAYERTYPE_plt_nDrill ) );
		}

		#min_vrtak
		if ( $self->_IsRequire("min_vrtak_D") ) {
			my $minTool = CamDrilling->GetMinHoleTool( $inCAM, $jobId, $stepName, EnumsGeneral->LAYERTYPE_plt_nDrill, "c" );

			if ( defined $minTool ) {
				$minTool = sprintf "%0.2f", ( $minTool / 1000 );
			}
			else {
				$minTool = "";
			}

			$section->AddRow( "min_vrtak_D", $minTool );
		}

		#get general information about drilling
		my ( $holesTypeNum, $aspectRatio ) = ( 0, 0 );

		if ( $self->_IsRequire("pocet_vrtaku_D") || $self->_IsRequire("pocet_der_D") || $self->_IsRequire("min_vrtak_pomer_D") ) {
			( $holesTypeNum, $aspectRatio ) = $self->__GetInfoDrill( $stepName, EnumsGeneral->LAYERTYPE_plt_nDrill );

		}

		#pocet_vrtaku
		if ( $self->_IsRequire("pocet_vrtaku_D") ) {
			$section->AddRow( "pocet_vrtaku_D", $holesTypeNum );
		}

		#min_vrtak_pomer
		if ( $self->_IsRequire("min_vrtak_pomer_D") ) {
			$section->AddRow( "min_vrtak_pomer_D", $aspectRatio );
		}
	}

}

# Thrugh drilling before viafilling
sub __DrillExists {
	my $self  = shift;
	my $lType = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $exist = CamDrilling->NCLayerExists( $inCAM, $jobId, $lType );

	if ($exist) {
		$exist = "A";
	}
	else {
		$exist = "N";
	}

	return $exist;
}

sub __GetHoleType {
	my $self  = shift;
	my $lType = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $lType );

	my $holeType = "";

	# Take informarion from first layer (all layers should have same type: vysledne or vrtane)
	if ( scalar(@layers) ) {

		$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$jobId/o+1/" . $layers[0]->{"gROWname"}, data_type => 'TOOL_USER' );
		if ( $inCAM->{doinfo}{gTOOL_USER} eq "vysledne" ) {
			$holeType = 'S';
		}
		elsif ( $inCAM->{doinfo}{gTOOL_USER} eq "vrtane" ) {
			$holeType = 'T';
		}

		# If exist "m" and has no holes => ok
		unless ($holeType) {

			#nuber of holes
			$inCAM->INFO(
						  units       => 'mm',
						  entity_type => 'layer',
						  entity_path => "$jobId/o+1/" . $layers[0]->{"gROWname"},
						  data_type   => 'FEAT_HIST',
						  options     => "break_sr"
			);
			my $holeCnt = $inCAM->{doinfo}{gFEAT_HISTpad};

			unless ($holeCnt) {
				$holeType = "";
			}
		}
	}

	return $holeType;
}

sub __GetHoleCnt {
	my $self  = shift;
	my $lType = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $holeCnt = 0;

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $lType );
	my %dim = JobDim->GetDimension( $inCAM, $jobId );

	# If pool, total count of one piece
	if ( !CamHelper->StepExists( $inCAM, $jobId, "panel" ) ) {

		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $lName = $layers[$i]->{"gROWname"};

			$inCAM->INFO(
						  units       => 'mm',
						  entity_type => 'layer',
						  entity_path => "$jobId/o+1/$lName",
						  data_type   => 'FEAT_HIST'
			);

			$holeCnt += $inCAM->{doinfo}{gFEAT_HISTpad};
		}

		$holeCnt = int( $holeCnt / $dim{"nasobnost_panelu"} ) if ( defined $dim{"nasobnost_panelu"} && $dim{"nasobnost_panelu"} ne "" );

	}
	else {

		# total hole cnt of layers on one piece (technical frame and coupons are not count)

		my @childSteps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );
		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $lName = $layers[$i]->{"gROWname"};

			foreach my $step (@childSteps) {

				$inCAM->INFO(
							  units       => 'mm',
							  entity_type => 'layer',
							  entity_path => "$jobId/$step/$lName",
							  data_type   => 'FEAT_HIST'
				);

				die if ( !defined $step->{"totalCnt"} );
				$holeCnt += $inCAM->{doinfo}{gFEAT_HISTpad} * $step->{"totalCnt"};
			}

		}

		$holeCnt = int( $holeCnt / $dim{"nasobnost"} );
	}

	return $holeCnt;
}

sub __GetInfoDrill {
	my $self     = shift;
	my $stepName = shift;
	my $lType    = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $pcbThick = JobHelper->GetFinalPcbThick($jobId);

	my @holeTypes = ();    # all holes type of layers

	my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, $lType );
	my @childSteps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

	for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

		my $lName = $layers[$i]->{"gROWname"};

		#nuber of hole types
		$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$jobId/$stepName/$lName", data_type => 'TOOL', options => "break_sr" );
		my @drillSizes = @{ $inCAM->{doinfo}{gTOOLdrill_size} };

		foreach my $t (@drillSizes) {
			unless ( scalar( grep { $_ == $t } @holeTypes ) ) {
				push( @holeTypes, $t );
			}
		}

	}

	#sort ASC
	@holeTypes = sort { $a <=> $b } @holeTypes;

	#min aspect ratio
	my $aspectRatio = "";
	if ( scalar(@holeTypes) ) {

		$aspectRatio = sprintf "%0.2f", ( $pcbThick / $holeTypes[0] );
	}

	return ( scalar(@holeTypes), $aspectRatio );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

