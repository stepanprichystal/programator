
#-------------------------------------------------------------------------------------------#
# Description: Build section about extra pcb information
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderOther;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAMJob::Stackup::StackupCode';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Packages::Stackup::Enums' => "StackEnums";
use aliased 'Packages::CAMJob::Checklist::PCBSigLayer';

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

	my $inCAM   = $self->{"inCAM"};
	my $jobId   = $self->{"jobId"};
	my %nifData = %{ $self->{"nifData"} };

	#poznamka
	if ( $self->_IsRequire("poznamka") ) {

		# add quick notes too

		$section->AddRow( "poznamka", $self->__PrepareNote() );
	}

	#poznamka jadra
	# Temporary solution, wait for analzsis of HEG production module in Kubatronik
	if ( $self->_IsRequire("semiproducts") ) {

		# add quick notes too

		if ( CamJob->GetSignalLayerCnt( $inCAM, $jobId ) > 2 ) {

			my $stackup = Stackup->new( $inCAM, $jobId );

			# Check if exist semiproduct (resp semiproducts which is pressed before final press)
			my @semiProd = map { $_->GetData() } $stackup->GetLastPress()->GetLayers( StackEnums->ProductL_PRODUCT );

			# Stackup contains  semiproducts with pressing
			if ( !$stackup->GetSequentialLam() && scalar( grep { scalar( $_->GetLayers() ) > 1 } @semiProd ) ) {

				# Flag description

				# Flag contain core, which is pressed in semiproducts togehter with "main core"
				my $semiproduct_core = "semiproduct_core";

				# Flag contain core, which is in stackup semiproduct (core can be alone in semiproduct or togehter with another semiproduct_core)
				# but this core is main and  keep follow operations on technical procedure
				my $semiproduct_maincore = "semiproduct_maincore";

				# Flag contain core, which is "semiproduct_maincore" and should be drilled before final PCB pressing
				my $semiproduct_press_prepreg  = "semiproduct_press_prepreg";
				my $semiproduct_press_coverlay = "semiproduct_press_coverlay";

				# 1) Init note for each core
				my %noteCores = ();

				foreach my $c ( $stackup->GetAllCores() ) {

					$noteCores{ $c->GetCoreNumber() } = [];
				}

				foreach my $p (@semiProd) {

					my @layers = map { $_->GetData() } $p->GetLayers();
					my @layersMat = map { $_->GetData() } $p->GetLayers(StackEnums->ProductL_MATERIAL);
					my @cores  = map { $_->GetData() } $p->GetLayers( StackEnums->ProductL_PRODUCT );

					# a) If semiproduct contains more cores, set flag "main core" to specify core
					if ( scalar(@layers) == 1 ) {
						push( @{ $noteCores{ $cores[0]->GetCoreNumber() } }, $semiproduct_maincore );
					}

					# b) If semiproducts contain pressing, set flag pressing to all cores
					if ( scalar(@layers) > 1 ) {

						if ( scalar(@cores) == 1 ) {

							# Case when 1 flex core  + coverlay/prepreg OR 1 rigid core  +  prepreg

							push( @{ $noteCores{ $cores[0]->GetCoreNumber() } }, $semiproduct_maincore );

							if ( scalar( grep { $_->GetType() eq StackEnums->MaterialType_PREPREG }  @layersMat ) ) {
								push( @{ $noteCores{ $cores[0]->GetCoreNumber() } }, $semiproduct_press_prepreg );
							}
							elsif ( scalar( grep { $_->GetType() eq StackEnums->MaterialType_COVERLAY } @layersMat ) ) {
								push( @{ $noteCores{ $cores[0]->GetCoreNumber() } }, $semiproduct_press_coverlay );
							}

						}
						else {

							# Case when more rigid cores

							# Core depth milling determines "semiproduct_maincore"
							my @coreDepth = CamDrilling->GetNCLayersByTypes( $inCAM, $jobId,
																 [ EnumsGeneral->LAYERTYPE_nplt_cbMillTop, EnumsGeneral->LAYERTYPE_nplt_cbMillBot ] );
							CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@coreDepth );

							foreach my $c (@cores) {

								my @coreDepthStart =
								  grep { $_->{"gROWdrl_start"} eq $c->GetTopCopperLayer() || $_->{"gROWdrl_start"} eq $c->GetBotCopperLayer() }
								  @coreDepth;

								if ( scalar(@coreDepthStart) ) {

									push( @{ $noteCores{ $c->GetCoreNumber() } }, $semiproduct_maincore );

									if ( scalar( grep { $_->GetType() eq StackEnums->MaterialType_PREPREG } @layersMat ) ) {
										
										push( @{ $noteCores{ $c->GetCoreNumber() } }, $semiproduct_press_prepreg );
									}
									elsif ( scalar( grep { $_->GetType() eq StackEnums->MaterialType_COVERLAY } @layersMat ) ) {
										
										push( @{ $noteCores{ $c->GetCoreNumber() } }, $semiproduct_press_coverlay );
									}

									 
								}
								else {
									push( @{ $noteCores{ $c->GetCoreNumber() } }, $semiproduct_core );
								}

							}
						}

					}
				}

				foreach my $note ( keys %noteCores ) {

					my @notes = @{ $noteCores{$note} };

					if ( scalar(@notes) ) {

						$section->AddRow( "poznamka_${note}", join( "/", @notes ) );

					}

				}

			}
		}
	}

	# datacode
	if ( $self->_IsRequire("datacode") ) {

		$section->AddRow( "datacode", $nifData{"datacode"} );
	}

	#ul_logo
	if ( $self->_IsRequire("ul_logo") ) {

		$section->AddRow( "ul_logo", $nifData{"ul_logo"} );
	}

	# Maska 0,1 IS subject number: 2814075

	if ( $self->_IsRequire("2814075") ) {

		$section->AddComment("Maska 0,1");

		my $maska = "2814075";

		unless ( $nifData{"maska01"} ) {
			$maska = "-" . $maska;
		}

		$section->AddRow( "rel(22305,L)", $maska );
	}

	# BGA na desce IS subject number: 19031137
	if ( $self->_IsRequire("19031137") ) {

		$section->AddComment("BGA");

		my $bga = "-19031137";

		my @bgaLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId, 0, 1 );

		foreach my $s ( CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId ) ) {
			foreach my $l (@bgaLayers) {

				my %att = CamHistogram->GetAttHistogram( $inCAM, $jobId, $s->{"stepName"}, $l );
				if ( $att{".bga"} ) {
					$bga =~ s/-//;
					last;
				}
			}

			last unless ( $bga =~ /-/ );
		}

		$section->AddRow( "rel(22305,L)", $bga );
	}

	# Coverlay template. IS subject number: 19031138
	if ( $self->_IsRequire("19031138") ) {

		$section->AddComment("Coverlay template");

		my $templ = "-19031138";

		if ( CamHelper->LayerExists( $inCAM, $jobId, "cvrlpins" ) ) {

			$templ = "19031138";
		}

		$section->AddRow( "rel(22305,L)", $templ );
	}

	# Anular ring 75µm: 2814075

	if ( $self->_IsRequire("23524474") ) {

		$section->AddComment("Annular ring < 75um");

		my $ring = "-23524474";

		my $ringEexist = 0;
		my $verifyErrMess;

		foreach my $s ( CamStepRepeatPnl->GetUniqueDeepestSR( $inCAM, $jobId ) ) {

			my $res = PCBSigLayer->ExistAnularRingLess75( $inCAM, $jobId, $s->{"stepName"}, \$ringEexist, \$verifyErrMess );

			if ($res) {

				if ($ringEexist) {
					$ring =~ s/-//;
					last;
				}
			}

		}

		$section->AddRow( "rel(22305,L)", $ring );
	}

	# Z-axis coupon TOP + BOT

	if ( $self->_IsRequire("23978375") || $self->_IsRequire("23978376") ) {

		my $existTOP = "-23978375";
		my $existBOT = "-23978376";

		my $cpnEexist = 0;

		my $cpnName = EnumsGeneral->Coupon_ZAXIS;
		my @zAxisCpn =
		  grep { $_->{"stepName"} =~ /^$cpnName\d+$/i }
		  CamStepRepeatPnl->GetUniqueDeepestSR( $self->{"inCAM"}, $self->{"jobId"}, 1, [ EnumsGeneral->Coupon_ZAXIS ] );

		if ( scalar(@zAxisCpn) ) {

			# Take first and check if there are depth mill from TOP

			my @layers = CamDrilling->GetNCLayersByTypes(
				$inCAM, $jobId,
				[
				   EnumsGeneral->LAYERTYPE_nplt_bMillTop,
				   EnumsGeneral->LAYERTYPE_nplt_bMillBot,
				   EnumsGeneral->LAYERTYPE_nplt_bstiffcMill,
				   EnumsGeneral->LAYERTYPE_nplt_bstiffsMill,

				]
			);

			for ( my $i = scalar(@layers) - 1 ; $i >= 0 ; $i-- ) {
				my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $zAxisCpn[0]->{"stepName"}, $layers[$i]->{"gROWname"}, 0 );
				splice @layers, $i, 1 if ( $hist{"total"} == 0 );
			}

			CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

			foreach my $l (@layers) {

				if ( $l->{"gROWdrl_dir"} eq "top2bot" ) {
					$existTOP =~ s/-//;
				}

				if ( $l->{"gROWdrl_dir"} eq "bot2top" ) {
					$existBOT =~ s/-//;
				}
			}

			if ( $self->_IsRequire("23978375") ) {
				$section->AddComment("Z-axis coupon from TOP");
				$section->AddRow( "rel(22305,L)", $existTOP );
			}

			if ( $self->_IsRequire("23978376") ) {
				$section->AddComment("Z-axis coupon from BOT");
				$section->AddRow( "rel(22305,L)", $existBOT );
			}
		}
	}

	#mereni_presfittu
	if ( $self->_IsRequire("mereni_presfittu") ) {

		my $pressfit = "N";

		if ( $nifData{"mereni_presfittu"} ) {
			$pressfit = "A";
		}

		$section->AddRow( "mereni_presfittu", $pressfit );
	}

	#mereni_tolerance_vrtani
	if ( $self->_IsRequire("mereni_tolerance_vrtani") ) {

		my $toleranceHole = "N";

		if ( $nifData{"mereni_tolerance_vrtani"} ) {
			$toleranceHole = "A";
		}

		$section->AddRow( "mereni_tolerance_vrtani", $toleranceHole );
	}

	#mereni_tolerance_vrtani
	if ( $self->_IsRequire("srazeni_hran") ) {

		my $chamferEdge = "N";

		if ( $nifData{"srazeni_hran"} ) {
			$chamferEdge = "A";
		}

		$section->AddRow( "srazeni_hran", $chamferEdge );
	}

	#ul_logo
	if ( $self->_IsRequire("prerusovana_drazka") ) {
		my $jumpScore = "N";

		if ( $nifData{"prerusovana_drazka"} ) {
			$jumpScore = "A";
		}
		$section->AddRow( "prerusovana_drazka", $jumpScore );
	}

	#zaplneni_otvoru
	if ( $self->_IsRequire("zaplneni_otvoru") ) {
		my $res = "N";

		$section->AddComment("N - neni; B - vse; C - pouze vybrane");
		$section->AddRow( "zaplneni_otvoru", $self->__GetViaFillType() );
	}

	#zaplneni_otvoru
	if ( $self->_IsRequire("rizena_impedance") ) {
		my $res = "N";

		my @steps = CamStep->GetAllStepNames( $inCAM, $jobId );

		my $var = EnumsGeneral->Coupon_IMPEDANCE;
		my $imp = "N";
		if ( scalar( grep { $_ =~ /$var/ } @steps ) ) {
			$imp = "A";
		}

		$section->AddRow( "rizena_impedance", $imp );
	}

	if (    $self->_IsRequire("xri")
		 || $self->_IsRequire("yf")
		 || $self->_IsRequire("zri") )
	{

		my $stckpCode = StackupCode->new( $inCAM, $jobId );
		my %code = $stckpCode->GetStackupCodeParsed();

		$section->AddComment("Kod slozeni");

		# xri
		if ( $self->_IsRequire("xri") && defined $code{"xRi"} ) {

			$section->AddRow( "xri", $code{"xRi"} );
		}

		# yf
		if ( $self->_IsRequire("yf") && defined $code{"yF"} ) {

			$section->AddRow( "yf", $code{"yF"} );
		}

		# zri
		if ( $self->_IsRequire("zri") && defined $code{"zRi"} ) {

			$section->AddRow( "zri", $code{"zRi"} );
		}

	}

}

sub __PrepareNote {
	my $self = shift;

	my %nifData = %{ $self->{"nifData"} };

	my $note  = "";
	my @notes = ();

	# add customer note
	if ( $nifData{"poznamka"} ) {

		my @arr = split( ";", $nifData{"poznamka"} );

		push( @notes, @arr );
	}

	# add quick notes too
	if ( $nifData{"quickNotes"} ) {

		my @arr = @{ $nifData{"quickNotes"} };

		@arr = map { $_->{"text"} } @arr;

		push( @notes, @arr );
	}

	$note = join( ";", @notes );

	return $note;

}

# Return type of viafilling
# - N - no via fill
# - B - all holes are fileld
# - C - only specifiead holes are filled
sub __GetViaFillType {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	# 1) Default - no via fill
	my $type = "N";

	# 2)Test if anz via fill exist
	my $viaFill = CamDrilling->GetViaFillExists( $inCAM, $jobId );

	$type = "B" if ($viaFill);    # all via fill are filled

	# 3) Test if not all via hole are filed

	if ($viaFill) {
		my $l = [ EnumsGeneral->LAYERTYPE_plt_nDrill, EnumsGeneral->LAYERTYPE_plt_bDrillTop, EnumsGeneral->LAYERTYPE_plt_bDrillBot ];

		# if via fill layer exist and "standard not via fill" it means, not all via are filled
		if ( CamDrilling->GetNCLayersByTypes( $inCAM, $jobId, $l ) ) {

			$type = "C";
		}
	}

	return $type;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

