
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewerMatrixItem;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES

	$self->{"name"} = shift;

	# InCAM job matrix property
	# Contain keys:
	#	"gROWname"
	#	"gROWlayer_polarity"
	#	"gROWlayer_type"
	$self->{"matrixProp"} = shift;

	# Signal layer attributes
	$self->{"copperName"} = shift;
	$self->{"outerCore"}  = shift;
	$self->{"plugging"}   = shift;

	# Reference to forms
	$self->{"rowCopperFrm"}  = shift;
	$self->{"subGroupFrm"} = shift;

	return $self;
}

sub GetLayerName {
	my $self = shift;

	return $self->{"name"};
}

sub GetLayerMatrixProp {
	my $self = shift;

	return $self->{"matrixProp"};
}

sub GetCopperName {
	my $self = shift;

	return $self->{"copperName"};
}

sub GetOuterCore {
	my $self = shift;

	return $self->{"outerCore"};
}

sub GetPlugging {
	my $self = shift;

	return $self->{"plugging"};
}

sub GetSubGroupFrm {
	my $self = shift;

	return $self->{"subGroupFrm"};
}

sub GetRowCopperFrm {
	my $self = shift;

	return $self->{"rowCopperFrm"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

