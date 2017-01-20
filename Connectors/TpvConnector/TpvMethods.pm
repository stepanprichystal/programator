

#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::TpvConnector::TpvMethods;
#STATIC class

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;

#local library
#use lib qw(.. c:\Perl\site\lib\Programs\Test);
#use LoadLibrary;

use aliased 'Connectors::TpvConnector::Helper';
use aliased 'Connectors::SqlParameter';
use aliased 'Connectors::TpvConnector::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetCustomerInfo {
	my $self  = shift;
	my $customerId = shift;
	my $childPcbId = shift;
	
	my @params = (SqlParameter->new( "_CustomerId", Enums->SqlDbType_VARCHAR, $customerId ));
	
	# if some value is empty, we want return null, we say by this, customer has no request for this attribut
	
	my $cmd    = "SELECT 

					IF(ExportPaste = '', null , ExportPaste) as ExportPaste,
					IF(ProfileToPaste = '', null , ProfileToPaste) as ProfileToPaste,
					IF(SingleProfileToPaste = '', null , SingleProfileToPaste) as SingleProfileToPaste,
					IF(FiducialsToPaste = '', null , FiducialsToPaste) as FiducialsToPaste,
					IF(NoTpvInfoPdf = '', null , NoTpvInfoPdf) as NoTpvInfoPdf
					
    				FROM customer_note 
    				WHERE CustomerId = _CustomerId
    				LIMIT 1";
		

	my @result = Helper->ExecuteDataSet( $cmd, \@params );
	
	if(scalar(@result)){
		
		return $result[0];
		
	}else{
		return 0;
	}

	return @result;
}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
 
 
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Connectors::TpvConnector::TpvMethods';
	
	my $info = TpvMethods->GetCustomerInfo("01982");
	
	print 1;
	
}
 

1;
 


