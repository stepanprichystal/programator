
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::RunExportUtility;

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


	#run exporter
	$self->__RunExportUtility();

	return $self;
}

sub __RunExportUtility {
	my $self  = shift;


	my $processObj;
	my $perl = $Config{perlpath};
	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\ExportUtilityScript.pl",
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create ExportUtility process.\n";
 
}

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
