
#-------------------------------------------------------------------------------------------#
# Description: Build section about drilling of cores
# Section builder are responsible for content of section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderDrillCore;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;

#local library
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
	my %nifData  = %{ $self->{"nifData"} };
	my $stepName = "panel";

	my $stackup = Stackup->new( $self->{'jobId'} );
	my $stackupNC = StackupNC->new($self->{"inCAM"}, $stackup );
	my $coreCnt = $stackupNC->GetCoreCnt();

	# comment
	$section->AddComment(" VRTANI JADER PODLE CISLA JADRA ");



	for ( my $i = 0 ; $i < $coreCnt ; $i++ ) {

		my $coreNum = $i + 1;
		
		# comment
		$section->AddComment(" Vrtani Jadra ".$coreNum);

		my $coreNC = $stackupNC->GetCore($coreNum); 
		my $core = $stackup->GetCore($coreNum);
 
		my $drillVal = $coreNC->ExistNCLayers( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill )? "A" : "N";
		
		if(  $core->GetPlatingExists){
			$drillVal = "C"; # C means plating
		}
		
		$section->AddRow( "vrtani_" . $coreNum, $drillVal);

		my $stagesCnt = $coreNC->GetStageCnt( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill );
		$section->AddRow( "stages_vrtani_" . $coreNum, $stagesCnt );

		my $minTool = $coreNC->GetMinHoleTool( Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill );
		$section->AddRow( "min_vrtak_" . $coreNum, $self->__FormatTool($minTool) );

		my $maxAspectRatio = $coreNC->GetMaxAspectRatio(Enums->SignalLayer_TOP, EnumsGeneral->LAYERTYPE_plt_cDrill );
		$section->AddRow( "min_vrtak_pomer_" . $coreNum, $maxAspectRatio );

		#TODO - doplnit poznamku pro jadra

	}

}

sub __FormatTool {
	my $self    = shift;
	my $minTool = shift;
	
	if ( defined $minTool ) {
		$minTool = sprintf "%0.2f", ( $minTool / 1000 ) ;
	}
	else {
		$minTool = "";
	}
	return $minTool;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

