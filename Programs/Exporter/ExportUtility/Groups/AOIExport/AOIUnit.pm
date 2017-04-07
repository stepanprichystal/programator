
#-------------------------------------------------------------------------------------------#
# Description: Represent "Unit" class for AOI
#
# Every group in "export utility program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form (GroupData class)
# 2) Presenter -  responsible for: build and refresh from group
# 3) View - only display data, which are passed from model by presenter class (GroupWrapperForm])
# Author:SPR
#--------------------------------------------------------------------------------------------
package Programs::Exporter::ExportUtility::Groups::AOIExport::AOIUnit;
use base 'Managers::AbstractQueue::Groups::UnitBase';

use Class::Interface;
&implements('Managers::AbstractQueue::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
 

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifDataMngr';
 
use aliased 'Programs::Exporter::ExporterUtility::UnitEnums';
use aliased 'Managers::AbstractQueue::AbstractQueue::Forms::Group::GroupWrapperForm';
use aliased 'Programs::Exporter::ExportUtility::Groups::AOIExport::AOIExport';
use aliased 'Managers::AbstractQueue::Groups::GroupData';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;
 
  	# reference on class responsible for export
	$self->{"unitExport"} = AOIExport->new($self->{"unitId"}, UnitEnums->GetTitle($self->{"unitId"}));
 
	return $self;    # Return the reference to the hash.
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

