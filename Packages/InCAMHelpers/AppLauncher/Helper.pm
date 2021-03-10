
#-------------------------------------------------------------------------------------------#
# Description: Helper for AppLauncher class
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAMHelpers::AppLauncher::Helper;

#3th party library
use strict;
use warnings;
use JSON;
use Win32::Process;
use Config;

#local library

use aliased "Helpers::FileHelper";
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';

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

sub ShowWaitFrm {
	my $self  = shift;
	my $title = shift;
	my $text  = shift;

	my %inf = ( "title" => $title, "text" => $text );

	my $json       = JSON->new()->allow_nonref();
	my $serialized = $json->pretty->encode( \%inf );
	my $fileName   = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	open( my $f, '>', $fileName );
	print $f $serialized;
	close $f;

	my $perl = $Config{perlpath};
	my $processObj;
	Win32::Process::Create( $processObj, $perl, "perl " . GeneralHelper->Root() . "\\Packages\\InCAMHelpers\\AppLauncher\\RunWaitFrm.pl " . $fileName,
							1, NORMAL_PRIORITY_CLASS, "." )
	  || die "Failed to create run wait frm.\n";

	return $processObj->GetProcessID();
}

sub CloseWaitFrm {
	my $self = shift;
	my $pid  = shift;

	if ($pid) {

		Win32::Process::KillProcess( $pid, 0 );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

