
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
use aliased 'Enums::EnumsDrill';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
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

	my $viaFill = CamDrilling->GetViaFillExists( $inCAM, $jobId );

	# comment
	$section->AddComment( "Vrtani skrz pred prokovem " . ( $viaFill ? "pred zalpnenim otvoru" : "" ) );
	my $lType = $viaFill ? EnumsGeneral->LAYERTYPE_plt_nFillDrill : EnumsGeneral->LAYERTYPE_plt_nDrill;

	#vrtani_pred (vrtani pred prokovem)
	if ( $self->_IsRequire("vrtani_pred") ) {

		my $exist = $self->__DrillExists( [ $lType, EnumsGeneral->LAYERTYPE_plt_fDrill ] );

		$section->AddRow( "vrtani_pred", $exist );
	}

	#stages_vrtani_pred
	if ( $self->_IsRequire("stages_vrtani_pred") ) {

		my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, [ $lType, EnumsGeneral->LAYERTYPE_plt_fDrill ] );

		my $maxCnt;
		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my $cnt = CamDrilling->GetStagesCnt( $jobId, $stepName, $layers[$i]->{"gROWname"}, $inCAM );
			$maxCnt = $cnt if ( !defined $maxCnt || $maxCnt < $cnt );
		}

		$section->AddRow( "stages_vrtani_pred", $maxCnt );
	}

	#otvory (vyelsedne / vrtane  => S/T)
	if ( $self->_IsRequire("otvory") ) {

		$section->AddRow( "otvory", $self->__GetHoleType( [ $lType, EnumsGeneral->LAYERTYPE_plt_fDrill ] ) );
	}

	#pocet_der
	if ( $self->_IsRequire("pocet_der") ) {
		$section->AddRow( "pocet_der", $self->__GetHoleCnt( [ $lType, EnumsGeneral->LAYERTYPE_plt_fDrill ] ) );
	}

	#min_vrtak
	if ( $self->_IsRequire("min_vrtak") ) {
		my $minTool = CamDrilling->GetMinHoleTool( $inCAM, $jobId, $stepName, [ $lType, EnumsGeneral->LAYERTYPE_plt_fDrill ], "c" );

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
		( $holesTypeNum, $aspectRatio ) = $self->__GetInfoDrill( $stepName, [ $lType, EnumsGeneral->LAYERTYPE_plt_fDrill ] );

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

			# Exist if exist through drill or blind drill from top

			my $throughExist = CamDrilling->NCLayerExists( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );
			my $blindExist = 0;

			if ( $self->{"layerCnt"} > 2 ) {
				my $stackupNC  = StackupNC->new( $inCAM, $jobId);
				my $lastPress  = $stackupNC->GetNCPressProduct( $stackupNC->GetPressCount() );
				my $blindExist = $lastPress->ExistNCLayers( StackEnums->SignalLayer_TOP, undef, EnumsGeneral->LAYERTYPE_plt_bDrillTop );
			}

			$section->AddRow( "vrtani_do_c", ( $throughExist || $blindExist ) ? "A" : "N" );
		}

		# stages_vrtani_pred
		if ( $self->_IsRequire("stages_do_c") ) {

			my @layers = CamDrilling->GetNCLayersByType( $inCAM, $jobId, EnumsGeneral->LAYERTYPE_plt_nDrill );

			my $maxCnt = 0;    # Layer plt drill (m) doesnt have to exists
			for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

				my $cnt = CamDrilling->GetStagesCnt( $jobId, $stepName, $layers[$i]->{"gROWname"}, $inCAM );
				$maxCnt = $cnt if ( $maxCnt < $cnt );
			}

			$section->AddRow( "stages_do_c", $maxCnt );
		}

		#pocet_der_D
		if ( $self->_IsRequire("pocet_der_do_c") ) {
			$section->AddRow( "pocet_der_do_c", $self->__GetHoleCnt( [ EnumsGeneral->LAYERTYPE_plt_nDrill ] ) );
		}

		#min_vrtak
		if ( $self->_IsRequire("min_vrtak_do_c") ) {
			my $minTool = CamDrilling->GetMinHoleTool( $inCAM, $jobId, $stepName, [ EnumsGeneral->LAYERTYPE_plt_nDrill ], "c" );

			if ( defined $minTool ) {
				$minTool = sprintf "%0.2f", ( $minTool / 1000 );
			}
			else {
				$minTool = "";
			}

			$section->AddRow( "min_vrtak_do_c", $minTool );
		}

		#get general information about drilling
		my ( $holesTypeNum, $aspectRatio ) = ( 0, 0 );

		if ( $self->_IsRequire("pocet_vrtaku_do_c") || $self->_IsRequire("min_vrtak_pomer_do_c") ) {
			( $holesTypeNum, $aspectRatio ) = $self->__GetInfoDrill( $stepName, [ EnumsGeneral->LAYERTYPE_plt_nDrill ] );

		}

		#pocet_vrtaku
		if ( $self->_IsRequire("pocet_vrtaku_do_c") ) {
			$section->AddRow( "pocet_vrtaku_do_c", $holesTypeNum );
		}

		#min_vrtak_pomer
		if ( $self->_IsRequire("min_vrtak_pomer_do_c") ) {
			$section->AddRow( "min_vrtak_pomer_do_c", $aspectRatio );
		}
	}

	#pocet_der_kus
	if ( $self->_IsRequire("pocet_der_kus") ) {

		# comment
		$section->AddComment("Pocet vsech otvoru (prokovene i neprokovene)");

		my $pocetDer = 0;

		my @drill = CamJob->GetLayerByType( $inCAM, $jobId, "drill" );
		my @rout  = CamJob->GetLayerByType( $inCAM, $jobId, "rout" );

		foreach my $step ( CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId ) ) {

			foreach my $l ( ( @drill, @rout ) ) {

				my %featHist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step->{"stepName"}, $l->{"gROWname"} );
				my %attHist = CamHistogram->GetAttCountHistogram( $inCAM, $jobId, $step->{"stepName"}, $l->{"gROWname"} );

				$pocetDer += ( $step->{"totalCnt"} * $featHist{"pad"} );

				$pocetDer -= ( $step->{"totalCnt"} * $attHist{".pilot_hole"}->{"_totalCnt"} )
				  if ( defined $attHist{".pilot_hole"} );    # pilot holes
				$pocetDer -= ( $step->{"totalCnt"} * $attHist{".extended"}->{"_totalCnt"} )
				  if ( defined $attHist{".extended"} );      # rout bridges zero pad
			}
		}

		my %multipl = JobDim->GetDimension( $inCAM, $jobId );    # multiple of panel
		$pocetDer = int( $pocetDer / $multipl{"nasobnost"} );

		$section->AddRow( "pocet_der_kus", $pocetDer );
	}

}

# Thrugh drilling before viafilling
sub __DrillExists {
	my $self   = shift;
	my $lTypes = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $lTypes );

	my $exist;
	if ( scalar(@layers) ) {
		$exist = "A";
	}
	else {
		$exist = "N";
	}

	return $exist;
}

sub __GetHoleType {
	my $self   = shift;
	my $lTypes = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $lTypes );

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

		# If no holess => ok
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
	my $self   = shift;
	my $lTypes = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $holeCnt = 0;

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $lTypes );
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

		my @childSteps = CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );
		for ( my $i = 0 ; $i < scalar(@layers) ; $i++ ) {

			my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, "panel", $layers[$i]->{"gROWname"} );

			$holeCnt += $hist{"pad"};
		}
	}

	return $holeCnt;
}

sub __GetInfoDrill {
	my $self     = shift;
	my $stepName = shift;
	my $lTypes   = shift;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $pcbThick = CamJob->GetFinalPcbThick($inCAM, $jobId);

	my @holeTypes = ();    # all holes type of layers

	my @layers = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $lTypes );

	#my @childSteps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueStepAndRepeat( $inCAM, $jobId );

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

