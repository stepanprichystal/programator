
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::RunExportChecker;

#3th party library
#use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';

use Config;
use Win32::Process;

sub new {
	my $self = shift;
	$self = {};
	bless($self);

	#$self->{"client"} = Client->new();
	$self->{"jobId"} = $ENV{"JOB"};

	# generate radom port between 2000-4000
	$self->{"port"} = 2000 + int( rand(2000) );
	print "\n\n == A H O J ====== =========\n\n";
	print "\n\n == A H O J ==================". $self->{"port"} ."=======================\n\n";
	

	#run exporter
	$self->__RunExportChecker( $self->{"jobId"}, $self->{"port"} );

	#run server
	$self->__RunServer($self->{"port"} );

	return $self;
}

sub __RunExportChecker {
	my $self  = shift;
	my $jobId = shift;
	
	#server port
	my $port  = shift;
	#server pid
	my $pid  = $$;

	my $processObj;
	my $perl = $Config{perlpath};
	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\ExportCheckerFormScript.pl $jobId $port $pid",
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create CloseZombie process.\n";
	 
}

sub __RunServer {
	my $self  = shift;
	my $port  = shift;

	#$self->__CloseZombie($port);

	#run server on specific port
	{
		#@_ = ($port);
		local @ARGV = ($port);
 
		require "Programs\\Exporter\\ExportChecker\\Server\\Server.pl";
	 
	};
}

#sub __CloseZombie {
#
#	my $self = shift;
#	my $port = shift;
#
#	my $processObj;
#	my $perl = $Config{perlpath};
#
#	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\Programs\\Exporter\\ExportChecker\\Server\\CloseZombie.pl -i $port",
#							1, NORMAL_PRIORITY_CLASS, "." )
#	  || die "Failed to create CloseZombie process.\n";
#
#	$processObj->Wait(INFINITE);
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print @INC;

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $app = Programs::Exporter::AsyncJobMngr->new();

	#$app->Test();

	#$app->MainLoop;

}

#my $app = MyApp2->new();

#my $worker = threads->create( \&work );
#print $worker->tid();

#
#sub work {
#	sleep(5);
#	print "METODA==========\n";
#
#	#!!! I would like send array OR hash insted of scalar here: my %result = ("key1" => 1, "key2" => 2 );
#	# !!! How to do that?
#
#}
#
#sub OnCreateThread {
#	my ( $self, $event ) = @_;
#	@_ = ();
#}

1;
