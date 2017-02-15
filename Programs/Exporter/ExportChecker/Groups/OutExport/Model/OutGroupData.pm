
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::OutExport::Model::OutGroupData;

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
 
 
# export data kooperace
sub SetExportCooper {
	my $self  = shift;
	$self->{"data"}->{"exportCooper"} = shift;
} 


sub GetExportCooper {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportCooper"};
}

# Cooperation step
sub SetCooperStep {
	my $self  = shift;
	$self->{"data"}->{"cooperStep"} = shift;
} 

sub GetCooperStep {
	my $self  = shift;
	my $value = shift;
	
	return $self->{"data"}->{"cooperStep"};
} 
 
 
# export electric test for cooper
sub SetExportET {
	my $self  = shift;
	$self->{"data"}->{"exportET"} = shift;
} 

sub GetExportET {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportET"};
}


 
# export data control
sub SetExportControl {
	my $self  = shift;
	$self->{"data"}->{"exportControl"} = shift;
} 


sub GetExportControl {
	my $self  = shift;
	my $value = shift;
	return $self->{"data"}->{"exportControl"};
}

# Control data step
sub SetControlStep {
	my $self  = shift;
	$self->{"data"}->{"controlStep"} = shift;
} 

sub GetControlStep {
	my $self  = shift;
	my $value = shift;
	
	return $self->{"data"}->{"controlStep"};
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

