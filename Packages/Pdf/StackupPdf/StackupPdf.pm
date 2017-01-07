
#-------------------------------------------------------------------------------------------#
# Description: Modul is responsible for creation pdf stackup from prepared xml definition
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::StackupPdf::StackupPdf;

#3th party library
use strict;
use warnings;
use English;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::StackupPdf::OutputPdf';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	#$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	 
	$self->{"outputPdf"} =  OutputPdf->new(  $self->{"jobId"});

	return $self;
}

sub Create {
	my $self = shift;
 	 
	
	# test if exist XML file
	my $stcFile = FileHelper->GetFileNameByPattern( EnumsPaths->Jobs_STACKUPS, $self->{"jobId"} );
	
	unless($stcFile){
		return 0;
	}
	

	my $stackup = Stackup->new($self->{"jobId"});
	my $stackupName = $self->__GetStackupName($stackup);

	$self->{"outputPdf"}->Output($stackupName, $stackup);
 
	return 1;
}

sub GetStackupPath{
	my $self = shift;
	
	return $self->{"outputPdf"}->GetOutput();
}


sub __GetStackupName {
	my $self     = shift;
	my $stackup    = shift;
	
	my $lCount = $stackup->GetCuLayerCnt();
	my $pcbThick = $stackup->GetFinalThick();
	

	$pcbThick = sprintf( "%4.3f", ( $pcbThick / 1000 ) );
	$pcbThick =~ s/\./\,/g;

	my %customerInfo = %{HegMethods->GetCustomerInfo($self->{"jobId"})};

	my $customer = $customerInfo{"customer"};

	if ($customer) {
		$customer =~ s/\s//g;
		$customer = substr( $customer, 0, 8 );
	}
	else {
		$customer = "";
	}

	if ( $customer =~ /safiral/i )    #exception for safiral
	{
		$customer = "";
	}

	return $self->{"jobId"} . "_" . $lCount . "vv" . "_" . $pcbThick . "_" . $customer;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

