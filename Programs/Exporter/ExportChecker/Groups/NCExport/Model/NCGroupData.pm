
#-------------------------------------------------------------------------------------------#
# Description: Class contain state properties, used as model for group form
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::NCExport::Model::NCGroupData;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Exporter::ExportChecker::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# state data for gui controls
	my %exportData = ();
	$self->{"data"} = \%exportData;

	# state of whole group. Value is enum GroupState_xx
	$self->{"state"} = Enums->GroupState_DISABLE;

	return $self;
}

# exportSingle
sub SetExportSingle {
	my $self = shift;
	$self->{"data"}->{"exportSingle"} = shift;
}

sub GetExportSingle {
	my $self = shift;
	return $self->{"data"}->{"exportSingle"};
}

# All mode NC layers
sub SetAllModeLayers {
	my $self = shift;
	$self->{"data"}->{"allModeLayers"} = shift;
}

sub GetAllModeLayers {
	my $self = shift;
	return $self->{"data"}->{"allModeLayers"};
}

# Plt layers
sub SetSingleModePltLayers {
	my $self = shift;
	$self->{"data"}->{"singleModePltLayers"} = shift;
}

sub GetSingleModePltLayers {
	my $self = shift;
	return $self->{"data"}->{"singleModePltLayers"};
}

# NPlt layers
sub SetSingleModeNPltLayers {
	my $self = shift;
	$self->{"data"}->{"singleModeNpltLayers"} = shift;
}

sub GetSingleModeNPltLayers {
	my $self = shift;
	return $self->{"data"}->{"singleModeNpltLayers"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

