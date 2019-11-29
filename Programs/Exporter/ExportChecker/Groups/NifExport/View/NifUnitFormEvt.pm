#-------------------------------------------------------------------------------------------#
# Description: This class define "outside" handlers and events, 
# which is possible cooperate with.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitFormEvt;
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
	my $ref = $wrapper->can('OnSCOGroupChangeCustomerJump');
	$self->_AddHandler( $ref , Enums->Event_sco_customerJump );
	
	my $ref2 = $wrapper->can('OnPREGroupTentingChangeHandler');
	$self->_AddHandler( $ref2 , Enums->Event_pre_etching );
	
	my $ref3 = $wrapper->can('OnPREGroupTechnologyChangeHandler');
	$self->_AddHandler( $ref3 , Enums->Event_pre_technology );
 
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

