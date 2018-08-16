
#-------------------------------------------------------------------------------------------#
# Description: Build section about routing cores
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderRoutCore;
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

	my $stackup = Stackup->new( $self->{'jobId'} );
	my $stackupNC = StackupNC->new($inCAM, $stackup);
	my $coreCnt = $stackupNC->GetCoreCnt();

	# comment
	$section->AddComment( " HLOUBKOVE FREZOVANI JADRA " );



	# comment
	$section->AddComment(" Frezovani Jadra Po Prokovu C ");

	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $coreNum = $i + 1;

		my $core = $stackupNC->GetCore($coreNum);
		my $existDrill = $core->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_nplt_cbMillTop );

		#if ( $self->_IsRequire( "frezovani_jadra_po_c_" . $coreNum ) ) {

			$section->AddRow( "frezovani_jadra_po_c_" . $coreNum, $existDrill  ? "A" : "N");
		#}
	}

	# comment
	$section->AddComment(" Frezovani Jadra Po Prokovu S ");

	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $coreNum = $i + 1;

		my $core = $stackupNC->GetCore($coreNum);
		my $existDrill = $core->ExistNCLayers( Enums->SignalLayer_BOT, EnumsGeneral->LAYERTYPE_nplt_cbMillBot );

		#if ( $self->_IsRequire( "frezovani_jadra_po_s_" . $coreNum ) ) {

			$section->AddRow( "frezovani_jadra_po_s_" . $coreNum, $existDrill  ? "A" : "N");
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

