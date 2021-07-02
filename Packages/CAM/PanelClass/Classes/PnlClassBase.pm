
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::PanelClass::Classes::PnlClassBase;

#3th party library
use strict;
use warnings;

#local library
#use aliased 'Programs::Exporter::ExportChecker::Groups::NifExport::View::NifUnitForm';

#use aliased 'Programs::Exporter::ExportChecker::Groups::GroupDataMngr';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpCheckData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpPrepareData';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::Model::ImpExportData';
#use aliased 'Programs::Exporter::ExportUtility::UnitEnums';
#use aliased 'Programs::Exporter::ExportChecker::Groups::ImpExport::View::ImpUnitForm';

#use aliased 'Programs::Panelisation::PnlWizard::Enums';

use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStep';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $name  = shift;
	my $self  = {};
	bless $self;

	$self->{"name"} = $name;

	$self->{"__CLASS__"} = caller();

	return $self;               # Return the reference to the hash.
}

sub SetName {
	my $self = shift;
	my $val  = shift;

	$self->{"name"} = $val;
}

sub GetName {
	my $self = shift;

	return $self->{"name"};
}

# Important because of serialize class
sub TO_JSON { return { %{ shift() } }; }

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

