
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::OfferData;
 
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

	my %exportData = ();
	$self->{"data"} = \%exportData;

	return $self; 
}
 
 # Store  offer job specification to IS
sub SetSpecifToIS {
	my $self  = shift;
	$self->{"data"}->{"storeSpecToIS"} = shift;
}

sub GetSpecifToIS {
	my $self  = shift;
	return $self->{"data"}->{"storeSpecToIS"};
}


# Add pdf stackup to approval email
sub SetAddSpecifToEmail {
	my $self  = shift;
	$self->{"data"}->{"addSpecifToEmail"} = shift;
}

sub GetAddSpecifToEmail {
	my $self  = shift;
	return $self->{"data"}->{"addSpecifToEmail"};
}
 

# Add pdf stackup to approval email
sub SetAddStackupToEmail {
	my $self  = shift;
	$self->{"data"}->{"addStackupToEmail"} = shift;
}

sub GetAddStackupToEmail {
	my $self  = shift;
	return $self->{"data"}->{"addStackupToEmail"};
}
 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

 
}

1;

