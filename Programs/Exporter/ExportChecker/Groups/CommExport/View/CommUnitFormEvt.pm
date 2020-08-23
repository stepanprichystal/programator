#-------------------------------------------------------------------------------------------#
# Description: This class define "outside" handlers and events, 
# which is possible cooperate with.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::CommExport::View::CommUnitFormEvt;
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
	my $ref = $wrapper->can('OnOfferGrouAddSpecifToMail');
	$self->_AddHandler( $ref , Enums->Event_offer_specifToMail );
	
	my $ref2 = $wrapper->can('OnOfferGrouAddStackupToMail');
	$self->_AddHandler( $ref2 , Enums->Event_offer_stackupToMail );
 
	# Provided events
	$self->_AddEvent( $wrapper->{'exportEmailEvt'}, Enums->Event_comm_exportEmail );
 
	return $self;
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {


}

1;

