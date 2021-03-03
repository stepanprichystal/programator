
#-------------------------------------------------------------------------------------------#
# Description: This is class, which represent "presenter"
#
# Every group in "export checker program" is composed from three layers:
# 1) Model - responsible for actual group data, which are displyed in group form
# 2) Presenter -  responsible for: edit/get goup data (model), build and refresh from for group
# 3) View - only display data, which are passed from model by presenter class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::PnlCreatorBase;

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

use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorable';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}      = shift;
	$self->{"jobId"}      = shift;
	$self->{"creatroKey"} = shift;

	$self->{"jsonStorable"} = JsonStorable->new();
	$self->{"settings"}     = {};

	return $self;    # Return the reference to the hash.
}

#
sub ExportSettings {
	my $self = shift;

	my $serialized = $self->{"jsonStorable"}->Encode( $self->{"settings"} );

	return $serialized;

}
#
sub ImportSettings {
	my $self       = shift;
	my $serialized = shift;

	die "Serialized data are empty" if ( !defined $serialized || $serialized eq "" );

	my $data = $self->{"jsonStorable"}->Decode($serialized);

	# Do check if some keys are not missing or if there are some extra
	my @newSettings = keys %{$data};
	my @oldSettings = keys %{ $self->{"settings"} };

	my %hash;
	$hash{$_}++ for ( @newSettings, @oldSettings );

	my @wrongKeys = grep { $hash{$_} != 2 } keys %hash;

	die "Import settings keys do not match with object setting keys (keys: " . join( "; ", @wrongKeys ) . " )" if (@wrongKeys);

	$self->{"settings"} = $data;

}

sub GetCreatorKey {
	my $self = shift;
	my $val  = shift;

	return $self->{"creatroKey"};

}

#
#sub CreatePanel;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

