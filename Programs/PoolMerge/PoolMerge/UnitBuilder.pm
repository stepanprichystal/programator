
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::UnitBuilder;
use base("Managers::AbstractQueue::AbstractQueue::UnitBuilderBase");

use Class::Interface;
&implements('Managers::AbstractQueue::AbstractQueue::IUnitBuilder');

#3th party library
use strict;
use warnings;
use JSON;

#local library
use aliased "Programs::PoolMerge::Task::TaskData::DataParser";
use aliased 'Programs::PoolMerge::Groups::MergeGroup::MergeWorkUnit';
use aliased 'Programs::PoolMerge::Groups::OutputGroup::OutputWorkUnit';
use aliased 'Programs::PoolMerge::Groups::RoutGroup::RoutWorkUnit';
use aliased 'Programs::PoolMerge::UnitEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	my $json     = JSON->new();
	my $hashData = $json->decode( $self->{"jobStrData"} );

	my $dataParser = DataParser->new();
	$self->{"taskData"} = $dataParser->GetTaskDataByString( $hashData->{"xmlData"}, $hashData->{"fileName"} );

	return $self;
}

sub GetTaskData {
	my $self     = shift;
	
	return  $self->{"taskData"};
}

sub GetUnits {
	my $self     = shift;
	
	my $taskData = $self->{"taskData"};

	my @keys     = $taskData->GetOrderedUnitKeys(1);
	my %allUnits = ();

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);

		my $unitTaskData = $taskData->GetUnitData($key);

		$unit->Init( $self->{"inCAM"}, $self->{"jobId"}, $unitTaskData );

		$allUnits{$key} = $unit;
	}

	return %allUnits;
}

# Return initialized "unit" object by unitId
sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;

	my $unit;
	my $jobId = $self->{"jobId"};

	if ( $unitId eq UnitEnums->UnitId_MERGE ) {

		$unit = MergeWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_ROUT ) {

		$unit = RoutWorkUnit->new($unitId);

	}
	elsif ( $unitId eq UnitEnums->UnitId_OUTPUT ) {

		$unit = OutputWorkUnit->new($unitId);

	}

	return $unit;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Programs::Exporter::ExportChecker::ExportChecker::StorageMngr';

	#my $id

	#my $form = StorageMngr->new();

}

1;

