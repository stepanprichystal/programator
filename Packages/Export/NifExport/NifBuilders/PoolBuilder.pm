
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for pcb POOL
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifBuilders::PoolBuilder;
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
use aliased 'Packages::Export::NifExport::SectionBuilders::BuilderPayments';

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
	push(@req, "typ_dps");
	push(@req, "datum_pripravy");
	
	$nifMngr->AddSection("DPS-POOL", BuilderPcb->new(\@req));
	
	#Dimension section
	@req = ();
	push(@req, "single_x");
	push(@req, "single_y");

	$nifMngr->AddSection("Rozmery", BuilderDim->new(\@req));


	#Other section
	
	@req = ();
	push(@req, "poznamka");
	push(@req, "datacode");
	push(@req, "ul_logo");
	push(@req, "2814075"); #maska 0,1mm
	push(@req, "prerusovana_drazka");
		
	$nifMngr->AddSection("Ostatni", BuilderOther->new(\@req));

	
	 
	#Drill section
	@req = ();
	push(@req, "otvory");
	
	$nifMngr->AddSection("Vrtani", BuilderDrill->new(\@req));
	
	#Payments section
	@req = ();
	push(@req, "4007223"); #panelizace
	push(@req, "4010802"); #frezovani pred prokovem
	push(@req, "4115894"); #drazkovani
	push(@req, "4141429"); #vnitrni freza 2vv
	push(@req, "8364285"); #vnitrni freza 4vv
	push(@req, "8364286"); #vnitrni freza 6vv, 8vv
	push(@req, "4007227"); #jiny format dat
	push(@req, "4007224"); #jine nazvy souboru
	
	$nifMngr->AddSection("Priplatky", BuilderPayments->new(\@req));



}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

