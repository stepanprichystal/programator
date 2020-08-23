#-------------------------------------------------------------------------------------------#
# Description: This class define "outside" handlers and events,
# which is possible cooperate with.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::OfferExport::View::OfferUnitFormEvt;
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
	my $ref2 = $wrapper->can('OnCommGrouExportEmail');
	$self->_AddHandler( $ref2 , Enums->Event_comm_exportEmail );


	# Provided events
	$self->_AddEvent( $wrapper->{'addSpecifToMailEvt'}, Enums->Event_offer_specifToMail );
	$self->_AddEvent( $wrapper->{"addStackupToMailEvt"},    Enums->Event_offer_stackupToMail );

	
	return $self;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

