
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::Groups::NCUnit;
use base 'Programs::Exporter::ExportUtility::Groups::UnitBase';

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::ExportChecker::Unit::IUnit');

#3th party library
use strict;
use warnings;

#local library
 

#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::Model::NifDataMngr';
 
use aliased 'Programs::Exporter::UnitEnums';
use aliased 'Programs::Exporter::ExportUtility::ExportUtility::Forms::Group::GroupWrapperForm';
use aliased 'Programs::Exporter::ExportUtility::Groups::NifExport::NifExport';
use aliased 'Programs::Exporter::ExportUtility::Groups::GroupData';
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};

	$self = $class->SUPER::new(@_);
	bless $self;

	#uique key within all units
	$self->{"unitId"} = UnitEnums->UnitId_NC;
 
	$self->{"unitExport"} = NifExport->new($self->{"unitId"});
	
	$self->{"groupData"} = GroupData->new();

	return $self;    # Return the reference to the hash.
}

 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

