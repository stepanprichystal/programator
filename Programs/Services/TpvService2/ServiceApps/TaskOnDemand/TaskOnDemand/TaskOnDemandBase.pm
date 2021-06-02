
#-------------------------------------------------------------------------------------------#
# Description:Base class for for task on demand
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Services::TpvService2::ServiceApps::TaskOnDemand::TaskOnDemand::TaskOnDemandBase;

#3th party library
use strict;
use warnings;
use Log::Log4perl qw(get_logger);

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class   = shift;
	my $appName = shift;
	my $inCAM   = shift;
	my $jobId   = shift;

	my $self = {};
	bless $self;

	$self->{"appName"} = $appName;
	$self->{"inCAM"}   = $inCAM;
	$self->{"jobId"}   = $jobId;
	$self->{"logger"}  = get_logger($appName);

	return $self;
}

# Check if job is not open by another user, open job, check in job
sub _OpenJob {
	my $self = shift;
 
	my $usr = undef;
	if ( CamJob->IsJobOpen( $self->{"inCAM"}, $self->{"jobId"}, 1, \$usr ) ) {

		die "Unable to process job, because job " . $self->{"jobId"} . " is open by user: $usr";
	}

	$self->{"inCAM"}->COM( "open_job", job => $self->{"jobId"}, "open_win" => "yes" );
	$self->{"inCAM"}->COM( "check_inout", "job" => $self->{"jobId"}, "mode" => "out", "ent_type" => "job" );

}

# Check out, save and close job
sub _CloseJob {
	my $self  = shift;
 

	$self->{"inCAM"}->COM( "save_job",    "job" => $self->{"jobId"} );
	$self->{"inCAM"}->COM( "check_inout", "job" => $self->{"jobId"}, "mode" => "in", "ent_type" => "job" );
	$self->{"inCAM"}->COM( "close_job",   "job" => $self->{"jobId"} );
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

