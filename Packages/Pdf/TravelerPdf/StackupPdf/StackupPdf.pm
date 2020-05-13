
#-------------------------------------------------------------------------------------------#
# Description: Modul is responsible for creation pdf stackup from prepared xml definition
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Pdf::TravelerPdf::StackupPdf::StackupPdf;

#3th party library
use strict;
use warnings;
use English;


#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Pdf::TravelerPdf::StackupPdf::OutputPdf';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';


#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}   = shift;
	$self->{"jobId"}   = shift;
	 
	$self->{"outputPdf"} =  OutputPdf->new(  $self->{"jobId"});

	return $self;
}

sub Create {
	my $self = shift;
	my $addMatQuality = shift // 0;    # defaul no (IS 400, IS410,..)
	my $addMatTG      = shift // 0;    # defaul no (IS 400, IS410,..)
	my $addPressThick = shift // 0;    # defaul no (Thickness after each pressing)   
	
	
	
	
	# test if exist XML file
	unless(JobHelper->StackupExist($self->{"jobId"})){
		return 0;
	}
	

	my $stackup = Stackup->new($self->{"inCAM"}, $self->{"jobId"});
	my $stackupName = $self->__GetStackupName($stackup);

	$self->{"outputPdf"}->Output($stackupName, $stackup, $addMatQuality,$addMatTG, $addPressThick);
 
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


use aliased 'Packages::Pdf::TravelerPdf::StackupPdf::StackupPdf';

my $stackup      = StackupPdf->new("d113609");
my $resultCreate = $stackup->Create(1,1,0);
 
}

1;

