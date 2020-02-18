
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb no copper
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Stackup::CustomerStackup::StackupBuilder::V1Builder;
use base('Packages::CAMJob::Stackup::CustomerStackup::StackupBuilder::StackupBuilderBase');

use Class::Interface;
&implements('Packages::CAMJob::Stackup::CustomerStackup::StackupBuilder::IStackupBuilder');

#3th party library
use strict;
use warnings;

#local library
 



#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

 
	return $self;
}



sub Build {
	my $self    = shift;
	my $stackupMngr = shift;

	#DPS section
	my @req = ();
 
	
	$stackupMngr->AddBlock( BuilderPcb->new(\@req));
	
	
	#Other section
	
	@req = ();
	push(@req, "poznamka");
	push(@req, "datacode");
	push(@req, "ul_logo");
	push(@req, "2814075"); # maska 0,1mm
	push(@req, "19031137"); # BGA
	push(@req, "mereni_tolerance_vrtani");
	push(@req, "prerusovana_drazka");
	push(@req, "srazeni_hran");
	push(@req, "zaplneni_otvoru");
	push(@req, "zaplneni_otvoru_STRANA");
	
	
	$nifMngr->AddSection("Ostatni", BuilderOther->new(\@req));	
	
	
	
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
	 
	#Cu Area section
	@req = ();

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
	push(@req, "pocet_der_kus");
	
	
	$nifMngr->AddSection("Vrtani", BuilderDrill->new(\@req));
	
	
	# NC operation duration
	@req = ();
 	
	$nifMngr->AddSection("Delka NC operaci", BuilderNCDuration->new(\@req));
	

}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

