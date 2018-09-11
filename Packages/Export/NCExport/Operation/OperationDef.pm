
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::Operation::OperationDef;

#3th party library
use strict;
use warnings;

#use File::Copy;

#local library
#use aliased 'Packages::Export::NCExport::NCExportHelper';
#use aliased 'Packages::Stackup::StackupHelper';
#use aliased 'Packages::Stackup::Drilling::DrillingHelper';
#use aliased 'CamHelpers::CamJob';
#use aliased 'Enums::EnumsPaths';
#use aliased 'Helpers::JobHelper';
#use aliased 'Packages::InCAM::InCAM';
#use aliased 'Enums::EnumsMachines';
#use aliased 'Helpers::GeneralHelper';
#use aliased 'Packages::Export::NCExport::Parser';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;
	$self = {};
	bless $self;

	$self->{"name"}       = shift;
	$self->{"layers"}     = shift;
	$self->{"pressOrder"} = shift;  #if operation after pressing, order of pressing
	
	#my %extraInfo = ();
	#$self->{"extraInfo"} = \%extraInfo;

	return $self;
}

sub GetName {
	my $self = shift;

	return $self->{"name"};

}

sub GetLayers {
	my $self = shift;

	return $self->{"layers"};

}

#sub SetExtraInfo {
#	my $self  = shift;
#	my $name  = shift;
#	my $value = shift;
#
#	$self->{"extraInfo"}->{$name} = $value;
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

