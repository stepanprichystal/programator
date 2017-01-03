
#-------------------------------------------------------------------------------------------#
# Description: Class provide function for loading / saving tif file
# TIF - technical info file - contain onformation important for produce, for technical list,
# another support script use this file
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
	print STDERR "\n file: $outputPath\n";
}


print STDERR "\n Script path $scriptPath\n";
print STDERR "\n Output path $outputPath\n";
my @parsed = Helper->ParseParams( \@files );

my $output = undef;    # output value, message
my $result = 1;

eval {

	local @_ = (\$output, @parsed);
	require $scriptPath;

	$result = 0;

};
if ($@) {

	$output = $_;
	
	#print STDERR "vzjimka $@  $_\n\n";

}

# save result/output message
if ( -e $outputPath || $output) {

	unlink($outputPath);

	my $f;
	open( $f, '>', $outputPath );
	print $f $output;
	close $f;
}

#print STDERR "redul = $result\n\n";

# return succes/fail
exit($result);

