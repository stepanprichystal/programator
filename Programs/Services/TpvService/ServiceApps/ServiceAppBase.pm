
#-------------------------------------------------------------------------------------------#
# Description: Base section builder. Section builder are responsible for content of section
# Allow add new rows to section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService::ServiceApps::ServiceAppBase;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Programs::Services::LogService::Logger::DBLogger';
use aliased 'Packages::InCAMHelpers::InCAMServer::Client::InCAMServer';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $appName = shift;
	my $self  = {};
	bless $self;
 
	$self->{"appName"} = $appName;
#	
#	print STDERR $appName;
#  
	$self->{"loggerDB"} = DBLogger->new($appName); # logger which send log to tpv db

	
	$self->{"inCAMServer"} = InCAMServer->new();


	return $self;
}
 
sub DESTROY {
	my $self = shift;
	
	$self->{"inCAMServer"}->JobDone();
	
	
	$self->{"logger"}->debug("Callin job done");
}
  
 
 
sub GetAppName{
	my $self = shift;
	
	return $self->{"appName"};
} 


# return prepared InCAM library 
sub _GetInCAM{
	my $self = shift;
	
	return $self->{"inCAMServer"}->GetInCAM();
	
}

# Check if job is not open by another user, open job, check in job
sub _OpenJob{
	my $self = shift;
	my $jobId = shift;
	my $supressDie = shift;
	
	my $usr = undef;
	if ( CamJob->IsJobOpen( $self->{"inCAM"}, $jobId, 1, \$usr ) ) {

		die "Unable to process reorder, because job $jobId is open by user: $usr";
	}
	
	$self->{"inCAM"}->COM( "open_job", job => "$jobId", "open_win" => "yes" );
	$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "out", "ent_type" => "job" );
	
}

# Check out, save and close job
sub _CloseJob{
	my $self = shift;
	my $jobId = shift;
	
	$self->{"inCAM"}->COM( "save_job",    "job" => "$jobId" );
	$self->{"inCAM"}->COM( "check_inout", "job" => "$jobId", "mode" => "in", "ent_type" => "job" );
	$self->{"inCAM"}->COM( "close_job",   "job" => "$jobId" );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

