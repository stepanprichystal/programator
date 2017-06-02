
#-------------------------------------------------------------------------------------------#
# Description: This script deserialize and prepare parameters
# Than do "require" of "working" script
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use threads;
use strict;
use warnings;
use JSON;

#necessary for load pall packages
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#local library
use aliased 'Packages::SystemCall::Helper' => "SystemCallHelper";

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $scriptPath = shift;
my $outputPath = shift;

my @files = ();
while ( my $p = shift ) {
	push( @files, $p );
}

my @parsed = SystemCallHelper->ParseParams( \@files );

my %outputHash = ();    # output value, message
my $result = 1;

eval {

	$outputHash{"__SystemCallResult"} = 0;

	local @_ = (\%outputHash, @parsed);
	require $scriptPath;
	
	$outputHash{"__SystemCallResult"} = 1;

	$result = 0;

};
if ($@) {

	 
	$outputHash{"__SystemCallResult"} = $@; # id exception save it as output value
	
}

# save result/output message
if ( defined $outputPath  ) {
 

	unlink($outputPath);

	my $json = JSON->new()->allow_nonref();

	my $serialized = $json->pretty->encode( \%outputHash );

	open( my $f, '>', $outputPath );
	print $f $serialized;
	close $f;
}


# return succes/fail
exit($result);

