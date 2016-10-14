
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Connectors::HeliosConnector::HegMethods2;

#STATIC class

#3th party library
use utf8;
use strict;
use warnings;
use Try::Tiny;

#local library
#use lib qw(.. c:\Perl\site\lib\Programs\Test);
#use LoadLibrary;

use aliased 'Connectors::HeliosConnector::Helper2';
use aliased 'Connectors::SqlParameter';
use aliased 'Connectors::HeliosConnector::Enums';

 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

# Return if pcb is type Pool
# Function take this information from last ordered pcb/order
sub GetPcbIsPool {
	my $self  = shift;
	my $pcbId = shift;

	my @params = ( SqlParameter->new( "_PcbId", Enums->SqlDbType_VARCHAR, $pcbId ) );

	my $cmd = "select top 1
				 z.pooling
				 from lcs.desky_22 d with (nolock)
				 left outer join lcs.zakazky_dps_22_hlavicka z with (nolock) on z.deska=d.cislo_subjektu
				 where d.reference_subjektu=_PcbId and  z.cislo_poradace = 22050
				 order by z.reference_subjektu desc";

	my $res = Helper2->ExecuteScalar( $cmd, \@params);
	
	if($res && $res eq "A"){
		return 1;
	}else{
		return 0;
	}
}


#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

#	use aliased 'Connectors::HeliosConnector::HegMethods2';
#
#	my $nc_info = "test";
#
#	my $test = HegMethods2->GetPcbIsPool("F13609");
#
#	print $test;

}

1;

