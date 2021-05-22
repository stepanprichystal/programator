
#-------------------------------------------------------------------------------------------#
# Description: Build section for  NC operation duration
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderOpEstimate;
use base('Packages::Export::NifExport::SectionBuilders::BuilderBase');

use Class::Interface;
&implements('Packages::Export::NifExport::SectionBuilders::ISectionBuilder');

#3th party library
use strict;
use warnings;
use Time::localtime;

#local library
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::TifFile::TifNCOperations';
use aliased 'Packages::CAMJob::Drilling::DrillDuration::DrillDuration';
use aliased 'Packages::CAMJob::Routing::RoutDuration::RoutDuration';
use aliased 'Packages::Export::NCExport::ExportPanelAllMngr';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'Packages::TifFile::TifET';

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

	$section->AddComment("Doba NC operace na jeden kus [min]");

	my $materialName = HegMethods->GetMaterialKind($jobId);
	my $export       = ExportPanelAllMngr->new( $inCAM, $jobId, $stepName );
	my @opItems      = ();

	my @oriOpitems = $export->GetOperationMngr()->GetOperationItems();

	foreach my $opItem (@oriOpitems) {

		if ( defined $opItem->GetOperationGroup() ) {

			push( @opItems, $opItem );
			next;
		}

		if ( !defined $opItem->GetOperationGroup() ) {

			# unless operation definition is defined at least in one operations in group operation items
			# process this operation

			my $o = ( $opItem->GetOperations() )[0];

			my $isInGroup = scalar( grep { $_->GetName() eq $o->GetName() }
									map { $_->GetOperations() } grep { defined $_->GetOperationGroup() } @oriOpitems );

			push( @opItems, $opItem ) if ( !$isInGroup );
		}
	}

	my %multipl = JobDim->GetDimension( $inCAM, $jobId );    # multiple of panel

	foreach my $ncOper (@opItems) {

		my $duration = 0;

		foreach my $l ( $ncOper->GetSortedLayers() ) {

			# dill hole duration (include all nested steps and tool changes)
			$duration += DrillDuration->GetDrillDuration( $inCAM, $jobId, $stepName, $l->{"gROWname"} );

			# rout paths duration (include all nested steps and tool changes)
			$duration += RoutDuration->GetRoutDuration( $inCAM, $jobId, $stepName, $l->{"gROWname"} ) if ( $l->{"gROWlayer_type"} eq "rout" );

		}

		# time for one pcb
		$duration = $duration / 60 / $multipl{"nasobnost"};

		$section->AddRow( "tac_vrtani_" . $jobId . "_" . $ncOper->GetName() . ".", sprintf( "%.2f", $duration ) );

	}

	# Comment
	$section->AddComment("Pocet TP (test point) na jeden kus");

	#tac_et
	if ( $self->_IsRequire("tac_et") ) {

		my $tif          = TifET->new($jobId);
		my $testPointCnt = ""; # This value will be during ET group exporting or from DIF file

		if ( $tif->TifFileExist() && defined $tif->GetTotalTestPoint() ) {
						
			$testPointCnt = $tif->GetTotalTestPoint();
		}

		$section->AddRow( "tac_et", $testPointCnt );
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

