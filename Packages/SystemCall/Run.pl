
#-------------------------------------------------------------------------------------------#
# Description: This script deserialize and prepare parameters
# Than do "require" of "working" script
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use threads;
use strict;
use warnings;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#local library
use aliased 'Packages::SystemCall::Helper';

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $scriptPath = shift;
my $outputPath = shift;

my @files = ();
while ( my $p = shift ) {
	push( @files, $p );
}

my @parsed = Helper->ParseParams( \@files );

my $output = undef;    # output value, message
my $result = 1;

eval {

	local @_ = (\$output, @parsed);
	require $scriptPath;

	$result = 0;

};
if ($@) {

	$output = $_; # id exception save it as output value
	
}

# save result/output message
if ( -e $outputPath || $output) {

	unlink($outputPath);

	my $f;
	open( $f, '>', $outputPath );
	print $f $output;
	close $f;
}


# return succes/fail
exit($result);

