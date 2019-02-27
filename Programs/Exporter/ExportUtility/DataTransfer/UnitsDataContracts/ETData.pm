
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::ETData;
 
#3th party library
use strict;
use warnings;


#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self; 
}
 
 # stepToTest
sub SetStepToTest {
	my $self  = shift;
	$self->{"data"}->{"stepToTest"} = shift;
}

sub GetStepToTest {
	my $self  = shift;
	return $self->{"data"}->{"stepToTest"};
}


# If create et step
sub SetCreateEtStep {
	my $self  = shift;
	$self->{"data"}->{"createEtStep"} = shift;
}

sub GetCreateEtStep {
	my $self  = shift;
	return $self->{"data"}->{"createEtStep"};
}

# Keep sr profile of nested steps
sub SetKeepProfiles {
	my $self  = shift;
	$self->{"data"}->{"keepProfiles"} = shift;
}

sub GetKeepProfiles {
	my $self  = shift;
	return $self->{"data"}->{"keepProfiles"};
}

# Copy local ipc to file
sub SetLocalCopy {
	my $self  = shift;
	$self->{"data"}->{"localCopy"} = shift;
}

sub GetLocalCopy {
	my $self  = shift;
	return $self->{"data"}->{"localCopy"};
}

# Copy server ipc to file
sub SetServerCopy {
	my $self  = shift;
	$self->{"data"}->{"serverCopy"} = shift;
}

sub GetServerCopy {
	my $self  = shift;
	return $self->{"data"}->{"serverCopy"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

