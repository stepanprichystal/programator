
#-------------------------------------------------------------------------------------------#
# Description: Class for testin modules
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Tests::Test;


require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Diag);

#3th party library
use strict;
use warnings;

#local library


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
 

# Print 
sub Diag {
	 my $text = shift;
	# my $text = shift;
	 
	 print STDERR $text."\n";
	 
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

