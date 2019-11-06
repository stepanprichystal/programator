
#-------------------------------------------------------------------------------------------#
# Description: Builder of procedure for 1v +2v PCB
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilder2V;
use base('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderBase');

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::IProcBuilder');

#3th party library
use strict;
use warnings;

#local library
 


#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;
}


sub Build {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;


	$self->__BuildSemiProducts( $procViewerFrm, $signalLayers );

	#$self->__BuildPressing( $procViewerFrm, $signalLayers, $stackup );
}

sub __BuildSemiProducts {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;

}

sub __BuildPressing {
	my $self          = shift;
	my $procViewerFrm = shift;
	my $signalLayers  = shift;
	my $stackup       = shift;

}




 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

