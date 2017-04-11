#-------------------------------------------------------------------------------------------#
# Description: Base class, keep ob task data for one job, 
# which fill be processed by "Exporter utility"
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::PoolMerge::Task::TaskData::TaskData;
use base("Managers::AbstractQueue::Task::TaskData::TaskData");

#3th party library
use strict;
use warnings;
use File::Copy;
use Wx;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_);

	bless($self);
 

	# EXPORT PROPERTIES
	 $self->{"settings"}->{"panelName"}    = undef;     
	$self->{"settings"}->{"poolType"}    = undef;     
	$self->{"settings"}->{"poolSurface"}    = undef;     
	$self->{"settings"}->{"poolExported"}    = undef;     

	return $self;                                     
}

sub GetPanelName {
	my $self = shift;

	return $self->{"settings"}->{"panelName"};
}

sub GetPoolType {
	my $self = shift;

	return $self->{"settings"}->{"poolType"};
}

sub GetPoolSurface {
	my $self = shift;

	return $self->{"settings"}->{"poolSurface"};
}

sub GetPoolExported {
	my $self = shift;

	return $self->{"settings"}->{"poolExported"};
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

