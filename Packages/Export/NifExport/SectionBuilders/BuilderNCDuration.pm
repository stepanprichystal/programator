
#-------------------------------------------------------------------------------------------#
# Description: Build section for sotring NC duration
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NifExport::SectionBuilders::BuilderNCDuration;
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
use aliased 'Packages::Export::NCExport::ExportMngr';
use aliased 'Packages::CAMJob::Dim::JobDim';

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
 

	$section->AddComment("Doba vrtani na jeden kus [mm]");

	my $export = ExportMngr->new( $inCAM, $jobId, $stepName );
	my @opItems = ();
	foreach my $opItem ( $export->GetOperationMngr()->GetOperationItems() ) {

		if ( defined $opItem->GetOperationGroup() ) {

			push( @opItems, $opItem );
			next;
		}

		if ( !defined $opItem->GetOperationGroup() ) {

			# unless operation definition is defined at least in one operations in group operation items
			# process this operation

			my $o = ( $opItem->GetOperations() )[0];

			my $isInGroup = scalar(
							   grep { $_->GetName() eq $o->GetName() }
							   map { $_->GetOperations() } grep { defined $_->GetOperationGroup() } $export->GetOperationMngr()->GetOperationItems()
			);

			push( @opItems, $opItem ) if ( !$isInGroup );
		}
	}
 
 	my %dim =  JobDim->GetDimension($inCAM, $jobId);

	foreach my $ncOper (@opItems) {

		my @layers = grep { $_->{"gROWlayer_type"} eq "drill" } $ncOper->GetSortedLayers();

		if (@layers) {

			my $duration = 0;

			foreach my $l (@layers) {

				$duration += DrillDuration->GetDrillDuration( $inCAM, $jobId, $stepName, $l->{"gROWname"} );
			}
			
			$duration = $duration /60 /  $dim{"nasobnost"};
 
			$section->AddRow( "tac_vrtani_".$jobId."_".$ncOper->GetName().".", sprintf("%.2f", $duration));
		}
		
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

