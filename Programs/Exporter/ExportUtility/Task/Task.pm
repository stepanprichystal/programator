
#-------------------------------------------------------------------------------------------#
# Description: Prostrednik mezi formularem jednotky a buildere,
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Task::Task;

 
#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::Presenter::NifUnit';
#use aliased 'Programs::Exporter::ExportUtility::Groups::NCExport::Presenter::NCUnit';
#-------------------------------------------------------------------------------------------#
#  Package methods, requested by IUnit interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	$self->{"taskId"} = shift;
	$self->{"jobId"} = shift;
	$self->{"exportData"} = shift;
	
	my @units = ();
	$self->{"units"} = \@units;

	 

	#$self->{"onCheckEvent"} = Event->new();
	
	$self->__InitUnit();

	return $self;    # Return the reference to the hash.
}
 
 sub GetTaskId{
 		my $self = shift;
 	 
 		
 		return $self->{"taskId"};
 }
 
 sub GetJobId{
 		my $self = shift;
 	 
 		
 		return $self->{"jobId"};
 }
 
 # Init groups by exported data
sub __InitUnit{
	my $self = shift;
	
	my $exportedData = $self->{"exportData"};
	
	my %unitsData = $exportedData->GetAllUnitData();
	
	foreach my $key (keys %unitsData){
		
		my $unit = $self->__GetUnit($key);
		
		push(@{$self->{"units"}}, $unit);

	}
}


sub GetAllUnits{
	my $self = shift;	
	return @{$self->{"units"}};
}


sub __GetUnit{
	my $self = shift;
	my $unitId = shift;
	
	my $unit;
	
	if($unitId eq UnitEnums->UnitId_NIF){
		
		$unit = NifUnit->new();
		
	}elsif($unitId eq UnitEnums->UnitId_NC){
		
		$unit = NifUnit->new();
		#$unit = NCUnit-new();
		
	}
	
	return $unit;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

