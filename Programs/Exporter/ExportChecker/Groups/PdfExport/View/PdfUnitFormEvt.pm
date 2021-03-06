#-------------------------------------------------------------------------------------------#
# Description: This class define "outside" handlers and events,
# which is possible cooperate with.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PdfExport::View::PdfUnitFormEvt;
use base ("Programs::Exporter::ExportChecker::Groups::UnitFormEvtBase");

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Groups::Enums';
use aliased 'Packages::Events::Event';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	my $wrapper = $self->{"wrapper"};

	# Provided handlers
	 

	# Provided events

	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

