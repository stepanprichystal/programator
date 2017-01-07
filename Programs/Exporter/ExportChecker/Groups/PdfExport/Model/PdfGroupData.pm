#-------------------------------------------------------------------------------------------#
# Description: Group data
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PdfExport::Model::PdfGroupData;

#use Class::Interface;
#&implements('Programs::Exporter::ExportChecker::Groups::IGroupData');

#3th party library
use strict;
use warnings;
use File::Copy;

#local library

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $self = shift;
	$self = {};
	bless $self;

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self;    # Return the reference to the hash.
}

# paste info, hash with info

sub GetData {
	my $self = shift;
	return %{ $self->{"data"} };
}

sub SetExportControl {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportControl"} = $value;
}

sub GetExportControl {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportControl"};
}

sub SetControlStep {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"controlStep"} = $value;
}

sub GetControlStep {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"controlStep"};
}

sub SetControlLang {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"controlLang"} = $value;
}

sub GetControlLang {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"controlLang"};
}

sub SetExportStackup {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportStackup"} = $value;
}

sub GetExportStackup {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportStackup"};
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::Export::NCExport::NCExportGroup';
	#
	#	my $jobId    = "F13608";
	#	my $stepName = "panel";
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $ncgroup = NCExportGroup->new( $inCAM, $jobId );
	#
	#	$ncgroup->Run();

	#print $test;

}

1;

