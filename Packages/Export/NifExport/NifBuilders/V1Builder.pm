
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for one layer
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifBuilders::V1Builder;
use base('Packages::Export::NifExport::NifBuilders::NifBuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::NifBuilders::INifBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderPcb';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderDim';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderCuArea';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderScore';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderRout';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderDrill';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderOther';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderFlexiTmp';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderNCDuration';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	$self->{"nifData"} = shift;

	return $self;
}



sub Build {
	my $self    = shift;
	my $nifMngr = shift;

	#DPS section
	my @req = ();
	push(@req, "reference");
	push(@req, "zpracoval");
	push(@req, "kons_trida");
	push(@req, "pocet_vrstev");
	push(@req, "c_mask_colour");
	push(@req, "s_mask_colour");
	push(@req, "c_silk_screen_colour");
	push(@req, "s_silk_screen_colour");
	push(@req, "lak_typ");
	push(@req, "uhlik_typ");
	push(@req, "film_konektoru");
	push(@req, "prokoveni");
	push(@req, "datum_pripravy");
	
	$nifMngr->AddSection("DPS", BuilderPcb->new(\@req));
	
	
	#Dimension section
	@req = ();
	push(@req, "single_x");
	push(@req, "single_y");
	push(@req, "panel_x");
	push(@req, "panel_y");
	push(@req, "nasobnost_panelu");
	push(@req, "nasobnost");
	push(@req, "rozmer_x");
	push(@req, "rozmer_y");

	$nifMngr->AddSection("Rozmery", BuilderDim->new(\@req));
	
	#Other section
	
	@req = ();
	push(@req, "poznamka");
	push(@req, "datacode");
	push(@req, "ul_logo");
	push(@req, "2814075"); #maska 0,1mm
	push(@req, "mereni_tolerance_vrtani");
	push(@req, "prerusovana_drazka");
	push(@req, "srazeni_hran");
	push(@req, "zaplneni_otvoru");
	push(@req, "zaplneni_otvoru_STRANA");
	
	$nifMngr->AddSection("Ostatni", BuilderOther->new(\@req));
	 
	#Cu Area section
	@req = ();
	push(@req, "g_plocha_c");
	push(@req, "gold_c");
	push(@req, "pocet_ponoru");
	push(@req, "zlacena_plocha");
	push(@req, "imersni_plocha");


	$nifMngr->AddSection("PlochaCu", BuilderCuArea->new(\@req));

	#Score section
	@req = ();
	push(@req, "drazkovani");
	push(@req, "delka_drazky");

	$nifMngr->AddSection("Drazkovani", BuilderScore->new(\@req));

	#Rout section
	@req = ();
	push(@req, "frezovani_po");
	push(@req, "min_freza_po");
	push(@req, "freza_po_delka");
	push(@req, "min_freza_po");
	push(@req, "frezovani_hloubkove_po_c");
	push(@req, "freza_hloubkova_po_delka_c");
	push(@req, "min_freza_hloubkova_po_c");
	push(@req, "frezovani_hloubkove_po_s");
	push(@req, "freza_hloubkova_po_delka_s");
	push(@req, "min_freza_hloubkova_po_s");
	
	$nifMngr->AddSection("Frezovani", BuilderRout->new(\@req));


	#Drill section
	@req = ();
	push(@req, "min_vrtak");
	push(@req, "otvory");
	push(@req, "pocet_vrtaku");
	push(@req, "pocet_der");
	push(@req, "min_vrtak_pomer");
	
	push(@req, "min_vrtak_D");
	push(@req, "otvory_D");
	push(@req, "pocet_vrtaku_D");
	push(@req, "pocet_der_D");
	push(@req, "min_vrtak_pomer_D");
	
	$nifMngr->AddSection("Vrtani", BuilderDrill->new(\@req));


	# NC operation duration
	@req = ();
 	
	$nifMngr->AddSection("Delka NC operaci", BuilderNCDuration->new(\@req));

	# Flexi section
	$nifMngr->AddSection("DOCASNE - FLEXI PARAMETRY PRO POSTUP", BuilderFlexiTmp->new([]));

}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

