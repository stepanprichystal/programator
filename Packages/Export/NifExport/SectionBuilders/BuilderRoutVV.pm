
#-------------------------------------------------------------------------------------------#
# Description: Build section about routing multilayer pcb
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderRoutVV;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Stackup::Enums';
use aliased 'Packages::Stackup::Stackup::Stackup';
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
	my $stepName = "panel";
	my %nifData  = %{ $self->{"nifData"} };

	my $stackup   = Stackup->new( $self->{'jobId'} );
	my $stackupNC = StackupNC->new($self->{'jobId'}, $inCAM);
	my $pressCnt  = $stackupNC->GetPressCnt();

	# comment
	$section->AddComment(" HLOUBKOVE FREZOVANI MEZI LISOVANIM ");

	# From C

	# comment
	$section->AddComment( " Hloubkove Frezovani Pred Prokovem C" );
	
	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;



		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_bMillTop );

		#if ( $self->_IsRequire( "frezovani_vv_pred_c_" . $pressOrder ) ) {
			$section->AddRow( "frezovani_vv_pred_c_" . $pressOrder, $existDrill  ? "A" : "N");
		#}
	}

	# From S

	# comment
	$section->AddComment( "Hloubkove Frezovani Pred Prokovem S");

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;

		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_plt_bMillBot );

		#if ( $self->_IsRequire( "frezovani_vv_pred_s_" . $pressOrder ) ) {
			$section->AddRow( "frezovani_vv_pred_s_" . $pressOrder, $existDrill ? "A" : "N" );
		#}
	}

	# From TOP
	# comment
	$section->AddComment( "Hloubkove Frezovani Po Prokovu C");

	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;

		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_nplt_bMillTop );

		#if ( $self->_IsRequire( "frezovani_vv_po_c_" . $pressOrder ) ) {
			$section->AddRow( "frezovani_vv_po_c_" . $pressOrder, $existDrill  ? "A" : "N");
		#}
	}

	# From BOT
	
	# comment
	$section->AddComment( " Hloubkove Frezovani Po Prokovu S");
	
	for ( my $i = 0 ; $i < $pressCnt ; $i++ ) {

		my $pressOrder = $i + 1;

		my $press = $stackupNC->GetPress($pressOrder);

		my $existDrill = $press->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_nplt_bMillBot );

		#if ( $self->_IsRequire( "frezovani_vv_po_s_" . $pressOrder ) ) {
			$section->AddRow( "frezovani_vv_po_s_" . $pressOrder, $existDrill  ? "A" : "N");
		#}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

