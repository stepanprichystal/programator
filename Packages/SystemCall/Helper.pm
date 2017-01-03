
#-------------------------------------------------------------------------------------------#
# Description: Class provide function for loading / saving tif file
# TIF - technical info file - contain onformation important for produce, for technical list,
# another support script use this file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::SystemCall::Helper;

#3th party library
use strict;
use warnings;
use JSON;

#local library
 
use aliased "Helpers::FileHelper";
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
 

sub ParseParams {
	my $self        = shift;
	my $paramsFiles = shift;

	my @p = ();

	if ( defined $paramsFiles ) {

		foreach my $param ( @{$paramsFiles} ) {

			if ( -e $param ) {

				# read from disc
				# Load data from file
				my $serializeData = FileHelper->ReadAsString($param);

				my $json = JSON->new()->allow_nonref();

				my $d = $json->decode($serializeData);

				unlink($param);

				push( @p, $d );
			}

		}
	}

	return @p;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

