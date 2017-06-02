
#-------------------------------------------------------------------------------------------#
# Description: Log errors and warning to tpv log db
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::LogService::Logger::DBLogger;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.

	my $appName = shift;
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	$self->{"appName"} = $appName;

	return $self;
}

sub Error {
	my $self  = shift;
	my $jobId = shift;
	my $mess  = shift;

	$self->__Log($jobId, "Error", $mess);

}

sub Warning {
	my $self  = shift;
	my $jobId = shift;
	my $mess  = shift;

	$self->__Log($jobId, "Error", $mess);
}

sub __Log{
	my $self  = shift;
	my $jobId = shift;
	my $type = shift;
	my $mess = shift;
	
	if ( !defined $type || $type eq "" ) {
		die "Log type is not defined\n";
	}
	
	if ( !defined $mess || $mess eq "" ) {
		die "Log message  is not defined\n";
	}

	TpvMethods->InsertAppLog( $self->{"appName"}, $type, $mess, $jobId );
}



1;

