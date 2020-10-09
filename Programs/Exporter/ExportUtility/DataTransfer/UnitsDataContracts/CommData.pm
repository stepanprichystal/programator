
#-------------------------------------------------------------------------------------------#
# Description: Data definition for group. This data struct are used  as data transfer
# between ExportChecker and ExportUtility
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportUtility::DataTransfer::UnitsDataContracts::CommData;

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

sub GetData {
	my $self = shift;
	return %{ $self->{"data"} };
}

# Approval type
sub SetApprovalType {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"approvalType"} = $value;
}

sub GetApprovalType {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"approvalType"};
}


# Change status of order in CAM department

sub SetChangeOrderStatus {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"changeOrderStatus"} = $value;
}

sub GetChangeOrderStatus {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"changeOrderStatus"};
}

# Value of new order status

sub SetOrderStatus {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"orderStatus"} = $value;
}

sub GetOrderStatus {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"orderStatus"};
}

# Indicate if export email with comments

sub SetExportEmail {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"exportEmail"} = $value;
}

sub GetExportEmail {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"exportEmail"};
}

# Action after create email: Open/Sent

sub SetEmailAction {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"emailAction"} = $value;
}

sub GetEmailAction {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"emailAction"};
}

# Email adresses
sub SetEmailToAddress {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"emailToAdress"} = $value;
}

sub GetEmailToAddress {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"emailToAdress"};
}

# Email copy adresses
sub SetEmailCCAddress {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"emailCCAdress"} = $value;
}

sub GetEmailCCAddress {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"emailCCAdress"};
}

# Email subjects
sub SetEmailSubject {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"emailSubject"} = $value;
}

sub GetEmailSubject {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"emailSubject"};
}

# Email introduction
sub SetEmailIntro {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"emailIntro"} = $value;
}

sub GetEmailIntro {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"emailIntro"};
}


# Include offer inf like stackup, class etc..
sub SetIncludeOfferInf {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"includeOfferInf"} = $value;
}

sub GetIncludeOfferInf {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"includeOfferInf"};
}


# Include offer pdf stackup
sub SetIncludeOfferStckp {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"includeOfferStckp"} = $value;
}

sub GetIncludeOfferStckp {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"includeOfferStckp"};
}

# Clear comments
sub SetClearComments {
	my $self  = shift;
	my $value = shift;
	$self->{"data"}->{"clearComments"} = $value;
}

sub GetClearComments {
	my $self  = shift;
	my $value = shift;

	return $self->{"data"}->{"clearComments"};
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

