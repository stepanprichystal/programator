
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifBuilders::VVBuilder;
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
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderDrillVV';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderDrillCore';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderRoutVV';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderRoutCore';
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderOpEstimate';

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
	push( @req, "reference" );
	push( @req, "zpracoval" );
	push( @req, "kons_trida" );
	push( @req, "konstr_trida_vnitrni_vrstvy" );
	push( @req, "pocet_vrstev" );
	push( @req, "c_mask_colour" );
	push( @req, "s_mask_colour" );
	push( @req, "c_mask_colour2" );
	push( @req, "s_mask_colour2" );
	push( @req, "c_silk_screen_colour" );
	push( @req, "s_silk_screen_colour" );
	push( @req, "c_silk_screen_colour2" );
	push( @req, "s_silk_screen_colour2" );
	push( @req, "flexi_maska" );
	push( @req, "coverlay" );
	push( @req, "tenting" );
	push( @req, "lak_typ" );
	push( @req, "uhlik_typ" );
	push( @req, "film_konektoru" );
	push( @req, "technologie" );
	push( @req, "prokoveni" );
	push( @req, "datum_pripravy" );

	$nifMngr->AddSection( "DPS", BuilderPcb->new( \@req ) );

	#Dimension section
	@req = ();
	push( @req, "single_x" );
	push( @req, "single_y" );
	push( @req, "panel_x" );
	push( @req, "panel_y" );
	push( @req, "nasobnost_panelu" );
	push( @req, "nasobnost" );
	push( @req, "fr_rozmer_x" );
	push( @req, "fr_rozmer_y" );
	push( @req, "rozmer_x" );
	push( @req, "rozmer_y" );

	$nifMngr->AddSection( "Rozmery", BuilderDim->new( \@req ) );

	#Other section

	@req = ();
	push( @req, "poznamka" );
	push( @req, "datacode" );
	push( @req, "ul_logo" );
	push( @req, "2814075" );                   #maska 0,1mm
	push( @req, "19031137" );                  # BGA
	push( @req, "19031138" );                  # Coverlay template
	push( @req, "23524474" );                  # Annular ring < 75
	push( @req, "23978375" );                  # Z-axis coupon from TOP
	push( @req, "23978376" );                  # Z-axis coupon from BOT
	push( @req, "mereni_presfittu" );
	push( @req, "mereni_tolerance_vrtani" );
	push( @req, "prerusovana_drazka" );
	push( @req, "srazeni_hran" );
	push( @req, "zaplneni_otvoru" );
	push( @req, "rizena_impedance" );
	push( @req, "xri" );
	push( @req, "yf" );
	push( @req, "zri" );
	push( @req, "semiproducts" );

	$nifMngr->AddSection( "Ostatni", BuilderOther->new( \@req ) );

	#Cu Area section
	@req = ();
	push( @req, "g_plocha_c" );
	push( @req, "g_plocha_s" );
	push( @req, "gold_c" );
	push( @req, "gold_s" );
	push( @req, "plg_plocha" );
	push( @req, "plg_plocha" );
	push( @req, "pocet_ponoru" );
	push( @req, "zlacena_plocha" );
	push( @req, "imersni_plocha" );
	push( @req, "pattern" );
	push( @req, "flash" );
	push( @req, "prog_tenting" );

	$nifMngr->AddSection( "PlochaCu", BuilderCuArea->new( \@req ) );

	#Score section
	@req = ();
	push( @req, "drazkovani" );
	push( @req, "delka_drazky" );

	$nifMngr->AddSection( "Drazkovani", BuilderScore->new( \@req ) );

	#Rout section
	@req = ();
	push( @req, "freza_pred_leptanim" );
	push( @req, "frezovani_pred" );
	push( @req, "freza_pred_delka" );
	push( @req, "min_freza_pred" );
	push( @req, "frezovani_po" );
	push( @req, "min_freza_po" );
	push( @req, "freza_po_delka" );
	push( @req, "min_freza_po" );
	push( @req, "frezovani_hloubkove_pred_c" );
	push( @req, "freza_hloubkova_pred_delka_c" );
	push( @req, "min_freza_hloubkova_pred_c" );
	push( @req, "frezovani_hloubkove_pred_s" );
	push( @req, "freza_hloubkova_pred_delka_s" );
	push( @req, "min_freza_hloubkova_pred_s" );
	push( @req, "frezovani_hloubkove_po_c" );
	push( @req, "freza_hloubkova_po_delka_c" );
	push( @req, "min_freza_hloubkova_po_c" );
	push( @req, "frezovani_hloubkove_po_s" );
	push( @req, "freza_hloubkova_po_delka_s" );
	push( @req, "min_freza_hloubkova_po_s" );

	$nifMngr->AddSection( "Frezovani", BuilderRout->new( \@req ) );

	#RoutVV section
	@req = ();

	$nifMngr->AddSection( "Frezovani vicevrstve", BuilderRoutVV->new( \@req ) );

	#Rout Core section
	@req = ();

	$nifMngr->AddSection( "Frezovani jader", BuilderRoutCore->new( \@req ) );

	#Drill section
	@req = ();
	push( @req, "vrtani_pred" );
	push( @req, "stages_vrtani_pred" );
	push( @req, "min_vrtak" );
	push( @req, "min_vrtak_pomer" );
	push( @req, "otvory" );
	push( @req, "pocet_vrtaku" );
	push( @req, "pocet_der" );
	push( @req, "pocet_der_kus" );

	push( @req, "vrtani_do_c" );
	push( @req, "stages_do_c" );
	push( @req, "min_vrtak_do_c" );
	push( @req, "pocet_vrtaku_do_c" );
	push( @req, "pocet_der_do_c" );
	push( @req, "min_vrtak_pomer_do_c" );

	$nifMngr->AddSection( "Vrtani", BuilderDrill->new( \@req ) );

	#DrillVV section
	@req = ();

	$nifMngr->AddSection( "Vrtani vicevrstve", BuilderDrillVV->new( \@req ) );

	#Drill Core section
	@req = ();

	$nifMngr->AddSection( "Vrtani jader", BuilderDrillCore->new( \@req ) );

	# Process operation estimate
	@req = ("tac_et");

	$nifMngr->AddSection( "Odhad delky operaci", BuilderOpEstimate->new( \@req ) );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

