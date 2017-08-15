
#-------------------------------------------------------------------------------------------#
# Description: Helper for AppLauncher class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::Helper;

#3th party library
use strict;
use warnings;
use JSON;

#local library
 
use aliased "Helpers::FileHelper";
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
 
# Load app parameters from JSON files and return in array
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

