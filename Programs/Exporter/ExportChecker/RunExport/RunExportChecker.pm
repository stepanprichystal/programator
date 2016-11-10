
#-------------------------------------------------------------------------------------------#
# Description: This package run exporter checker
# 1) run single window app as single perl program
# 2) run server.pl from this script
# 3) Export checker will be communicate with this server, after export, this server is killed
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::RunExport::RunExportChecker;

#3th party library
#use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Enums::EnumsGeneral';


use Config;
use Win32::Process;

sub new {
	my $self = shift;
	$self = {};
	bless($self);

	#$self->{"client"} = Client->new();
	$self->{"jobId"} = $ENV{"JOB"};

	unless ( $self->{"jobId"} ) {

		$self->{"jobId"} = shift;
	}


	unless($self->__IsJobOpen($self->{"jobId"})){
		
		return 0;
	}


	# generate radom port between 2000-4000
	$self->{"port"} = 2000 + int( rand(2000) );
	 

	#run exporter
	$self->__RunExportChecker( $self->{"jobId"}, $self->{"port"} );

	#run server
	$self->__RunServer( $self->{"port"} );


	return $self;
}


sub __IsJobOpen {
	my $self = shift;
	my $jobId = shift;
	 

	unless ($jobId) {

		my $messMngr = MessageMngr->new("Exporter utility");
		my @mess1    = ("You have to run sript in open job.");
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_ERROR, \@mess1 );

		return 0;
 
	}
	
	return 1;

}



sub __RunExportChecker {
	my $self  = shift;
	my $jobId = shift;

	#server port
	my $port = shift;

	#server pid
	my $pid = $$;

	#my $processObj;
	my $perl = $Config{perlpath};
	my $processObj2;
	Win32::Process::Create( $processObj2, $perl, "perl " . GeneralHelper->Root() . "\\Programs\\Exporter\\ExportChecker\\RunExport\\RunWaitingForm.pl ",
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create CloseZombie process.\n";

	my $loadingFrmId = $processObj2->GetProcessID();
	my $processObj;
	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\Programs\\Exporter\\ExportChecker\\RunExport\\ExportCheckerFormScript.pl $jobId $port $pid $loadingFrmId",
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create CloseZombie process.\n";

}

sub __RunServer {
	my $self = shift;
	my $port = shift;

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
