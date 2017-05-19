#! /sw/bin/perl
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
use aliased 'Packages::InCAMCall::Helper';
use aliased 'Packages::InCAM::InCAM';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

my $packageName = shift;
my $outputPath  = shift;
my $PIDFile     = shift;

  	my $f;
 	open($f, '+>', "c:\\tmp\\TpvService\\test5" );
	print $f "Su zde 1 \n";
	close $f;



my @files = ();
while ( my $p = shift ) {
	push( @files, $p );
}

# store PID of this script fo file

FileHelper->WriteString( $PIDFile, $$ );

my @parsed = Helper->ParseParams( \@files );

my %outputHash = ();    # output value, message
my $inCAM = undef;

my $result     = 1;

eval {

	print STDERR "Run.pl is running $packageName \n";

	# load custom package
	
	eval("use $packageName;");
	
	print STDERR "\nsu zde 1\n";
	
#	unless ( $packageName->can('new') ) {
#		die "bad object name: $packageName";
#	}
	print STDERR "\nsu zde 2\n";
  
	 print STDERR "\nsu zde 3\n";

	$inCAM = InCAM->new();
	
	print STDERR "\nsu zde 4\n";

	$outputHash{"__InCAMCallResult"} = 0;
	
	
	my $package = $packageName->new();
	$package->Run( $inCAM, \@parsed, \%outputHash );
	 
	
	print STDERR "\nsu zde 5\n";
	
	$outputHash{"__InCAMCallResult"} = 1;
 	
	print STDERR "\nsu zde 6\n";

	$result = 0;

};
if ($@) {

	$outputHash{"error"} = $_;    # id exception save it as output value

}

$inCAM->COM("close_toolkit");

# save result as JSON to outputpath
if ( defined $outputPath ) {
	
	print STDERR "\nsu zde 7\n";

	unlink($outputPath);

	my $json = JSON->new()->allow_nonref();

	my $serialized = $json->pretty->encode( \%outputHash );

	open( my $f, '>', $outputPath );
	print $f $serialized;
	close $f;
	
	print STDERR $serialized;

}

# return succes/fail
exit($result);

