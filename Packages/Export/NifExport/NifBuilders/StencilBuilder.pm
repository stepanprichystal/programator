
#-------------------------------------------------------------------------------------------#
# Description: Nif Builder is responsible for creation nif file depend on pcb type
# Builder for stencils
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::NifBuilders::StencilBuilder;
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
	push(@req, "typ_dps");
	push(@req, "datum_pripravy");
	
	$nifMngr->AddSection("DPS", BuilderPcb->new(\@req));
	
	#Dimension section
	@req = ();
	push(@req, "single_x");
	push(@req, "single_y");
	push(@req, "nasobnost");
	push(@req, "rozmer_x");
	push(@req, "rozmer_y");
	push(@req, "tloustka");

	$nifMngr->AddSection("Rozmery", BuilderDim->new(\@req));

 

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

