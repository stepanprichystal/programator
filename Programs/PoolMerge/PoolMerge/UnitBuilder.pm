
#-------------------------------------------------------------------------------------------#
# Description: Is responsible for saving/loading serialization group data to/from disc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::PoolMerge::UnitBuilder;

use Class::Interface;
&implements('Managers::AbstractQueue::AbstractQueue::IUnitBuilder');

#3th party library
use strict;
use warnings;
 

#local library
use aliased "Programs::PoolMerge::Task::TaskData::DataParser";
use aliased 'Programs::PoolMerge::Groups::MergeGroup::MergeWorkUnit';
use aliased 'Programs::PoolMerge::Groups::OutputGroup::OutputWorkUnit';
use aliased 'Programs::PoolMerge::Groups::RoutGroup::RoutWorkUnit';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	return $self;
}

sub GetUnits {
	my $self           = shift;
	my $stringUnitData = shift;
	my $stringFileName = shift;

	my $dataParser = DataParser->new();
	my $taskData   = $dataParser->GetTaskDataByString($stringUnitData, $stringFileName);
	
	return 
	
	

}


sub __InitWorkerUnits{
	my $self           = shift;
	my $taskData = shift;
	
	my @keys = $taskData->GetOrderedUnitKeys(1);
	my %allUnits = ();

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);
		$allUnits{$key} =  $unit;
	}

	return %allUnits;
}
 
sub __InitUnits {
	my $self = shift;
 
	my @keys = $self->{"taskData"}->GetOrderedUnitKeys(1);
	my @allUnits = ();

	foreach my $key (@keys) {

		my $unit = $self->__GetUnitClass($key);
		push( @allUnits, $unit );
	}

	$self->{"units"}->SetUnits(\@allUnits);

}
# Return initialized "unit" object by unitId
sub __GetUnitClass {
	my $self   = shift;
	my $unitId = shift;

	my $unit;
	my $jobId = $self->{"jobId"};
	
	my $title = UnitEnums->GetTitle($unitId);

	if ( $unitId eq UnitEnums->UnitId_MERGE ) {

		$unit = MergeWorkUnit->new($unitId);
		
	}
	elsif ( $unitId eq UnitEnums->UnitId_ROUT ) {

		$unit = RoutWorkUnit->new($unitId);

	}elsif ( $unitId eq UnitEnums->UnitId_OUTPUT ) {

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

