#-------------------------------------------------------------------------------------------#
# Description: Represent Universal Drill tool manager

# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::TpvService::ReOrder::ReOrder;

#3th party library
use strict;
use warnings;
use Mail::Sender;

#local library
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Enums::EnumsApp';
use aliased 'Programs::LogService::MailSender::AppStopCond::TestStopCond';
use aliased 'Packages::NifFile::NifFile';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# All controls
	my @controls = ();
	$self->{"controls"} = \@controls;

 
	return $self;
}


sub Run {
	my $self = shift;

 
}

sub __DoChecks {
	my $self         = shift;
	 
}

sub __SetState {
	my $self  = shift;
	 
}

sub __CreateCheckFile {
	my $self  = shift;

 
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::LogService::MailSender::MailSender';

	#	use aliased 'Packages::InCAM::InCAM';
	#

	my $sender = MailSender->new();

	$sender->Run();

	print "ee";
}

1;

