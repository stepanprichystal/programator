
#-------------------------------------------------------------------------------------------#
# Description:  Reorder app which check and proces reorders
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::ReorderApp::ReorderApp;

#3th party library
use strict;
use warnings;
use Wx;

#local library
use aliased 'Packages::Reorder::ReorderApp::Forms::ReorderFrm';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
 

# ================================================================================
# PUBLIC METHOD
# ================================================================================

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
 
 	$self->{"form"} = ReorderFrm->new(-1, "Reorder app - ".$self->{"jobId"});
 
	$self->__Init();
	$self->__Run();
	
	return $self;
}

sub __Init {
	my $self = shift;
 
	#set handlers for main app form
	$self->__SetHandlers();

}

sub __Run {
	my $self = shift;
	$self->{"form"}->{"mainFrm"}->Show(1);

	# When all succesinit, close waiting form
	#if ( $self->{"loadingFrmPid"} ) {
	#	Win32::Process::KillProcess( $self->{"loadingFrmPid"}, 0 );
	#}

	#Helper->ShowAbstractQueueWindow(0,"Loading Exporter Checker");

	$self->{"form"}->MainLoop();

}

# ================================================================================
# FORM HANDLERS
# ================================================================================
 
sub __OnErrIndicatorHandler{
	my $self = shift;
	
	print "Err ind click";
} 

sub __OnProcessLocallyHandler{
	my $self = shift;
	
	print "Err ind click";
} 
 
 
 sub __OnProcessServerHandler{
	my $self = shift;
	
	print "Err ind click";
} 
 
 
# ================================================================================
# PRIVATE METHODS
# ================================================================================
 
sub __DoChecks{
	my $self = shift;
	
	
	
	
	
	
} 
 

sub __SetHandlers {
	my $self = shift;
 
	$self->{"form"}->{"errIndClickEvent"}->Add( sub  { $self->__OnErrIndicatorHandler(@_) } );
	$self->{"form"}->{"processLocallyEvent"}->Add( sub { $self->__OnProcessLocallyHandler(@_) } );
	$self->{"form"}->{"processServerEvent"}->Add( sub       { $self->__OnProcessServerHandler(@_) } );
 
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::ReorderApp::ReorderApp';
	use aliased 'Packages::InCAM::InCAM';
	my $inCAM = InCAM->new();
	my $jobId = "f52457";

	my $form = ReorderApp->new($inCAM, $jobId);

}

1;

