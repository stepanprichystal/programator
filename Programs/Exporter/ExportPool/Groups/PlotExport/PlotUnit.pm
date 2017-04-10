
#-------------------------------------------------------------------------------------------#
# Description: Represent "Unit" class for PLOT
#
# Every group in "export utility program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form (GroupData class)
# 2) Presenter -  responsible for: build and refresh from group
# 3) View - only display data, which are passed from model by presenter class (GroupWrapperForm])
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportPool::Groups::PlotExport::PlotUnit;
use base 'Managers::AbstractQueue::Groups::UnitBase';

use Class::Interface;
&implements('Managers::AbstractQueue::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
 
use aliased 'Programs::Exporter::ExportPool::UnitEnums';
use aliased 'Programs::Exporter::ExportPool::Groups::PlotExport::PlotExport';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

 	# reference on class responsible for export
	$self->{"unitExport"} = PlotExport->new($self->{"unitId"});
 
	return $self; 
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

