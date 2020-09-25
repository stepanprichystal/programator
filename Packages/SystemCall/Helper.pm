
#-------------------------------------------------------------------------------------------#
# Description: Helper for SystemCall class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::SystemCall::Helper;

#3th party library
use strict;
use warnings;
use JSON::XS;

#local library
 
use aliased "Helpers::FileHelper";
 

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
 

sub ParseParams {
	my $self        = shift;
	my $paramsFiles = shift;

	my $json = JSON::XS->new->ascii->pretty->allow_nonref;

	my @p = ();

	if ( defined $paramsFiles ) {

		foreach my $param ( @{$paramsFiles} ) {

			if ( -e $param ) {

				# read from disc
				# Load data from file
				my $serializeData = FileHelper->ReadAsString($param);
 
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

