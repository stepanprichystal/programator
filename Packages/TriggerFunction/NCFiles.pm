#-------------------------------------------------------------------------------------------#
# Description: Contains trigger methods, which work with NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::TriggerFunction::NCFiles;

#3th party library
use strict;
use warnings;
use Path::Tiny qw(path);

#loading of locale modules
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Packages::CAMJob::Routing::RoutSpeed::RoutSpeed';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Function replace pcb order number in all NC files placed in archive, which contains this number
# Example if dps is second ordered: M97,F12345 => M97,F12345-2
# parameter $orderId is eg: F12345-01
sub ChangePcbOrderNumber {
	my $self    = shift;
	my $orderId = shift;

	my $jobId = $orderId;
	$jobId =~ s/-.*$//;

	my ($orderNum) = $orderId =~ m/^\w\d+-(\d*)$/;
	$orderNum = int($orderNum);

	my $ncPath = JobHelper->GetJobArchive($jobId) . "nc\\";

	my @ncFiles = ();

	#filter only files, which include pcb number
	my $dir;
	if ( opendir( $dir, $ncPath ) ) {
		while ( my $file = readdir($dir) ) {

			next if ( $file =~ /^\.$/ );
			next if ( $file =~ /^\.\.$/ );

			if (    $file =~ /^($jobId)_c[0-9]*\.[\D]$/i
				 || $file =~ /^($jobId)_j[0-9]+\.[\D]$/i
				 || $file =~ /^($jobId)_v1\.[\D]$/i )
			{
				push( @ncFiles, $ncPath . $file );
			}
		}

		closedir($dir);
	}

	#replace number of order

	#legend for drilled number is (F12345-01D J1):
	#	 ??slo pds
	#	 -Tlou??ka m?di
	#		  < 18  => "/"
	#		  < 35=> "-"
	#		  < 70=> ":"
	#		  < 105=> "+"
	#		   ostatn?=> "++"
	#	 Po?adov? ??slo objedn?vky
	#	 ??slo stroje na kter? se zak?zka vrt? (A-F)
	#	 ??slo vrtan?ho j?dra

	foreach my $filename (@ncFiles) {

		my $file = path($filename);

		my $data = $file->slurp_utf8;

		if ( $data =~ m/(m97,[a-f][\d]+)([\/\-\:\+\s]{0,2})\d*/i ) {

			my $jobIdTxt = $1;
			my $cuTxt    = $2;

			if ( !defined $cuTxt || $cuTxt eq "" ) {
				$cuTxt = " ";
			}

			$data =~ s/(m97,[a-f][\d]+[\/\-\:\+\s]{0,2})\d*/$jobIdTxt$cuTxt$orderNum/i;
			$file->spew_utf8($data);

		}

	}

	return 1;
}

# Put rout feed speed to all rout tool calling in all NC programs
sub CompleteRoutFeed {
	my $self    = shift;
	my $orderId = shift;

	my $jobId = $orderId;
	$jobId =~ s/-.*$//;

	my $info = HegMethods->GetInfoAfterStartProduce($orderId);

	die "pocet_prirezu is no defined in HEG for orderid: $orderId" if ( !defined $info->{'pocet_prirezu'} || !defined $info->{'prirezu_navic'} );
	my $totalPnlCnt = $info->{'pocet_prirezu'} + $info->{'prirezu_navic'};

	my $mess = "";
	unless ( RoutSpeed->CompleteRoutSpeed( $jobId, $totalPnlCnt, \$mess ) ) {
		die "Error during set rout speed: $mess";
	}

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::TriggerFunction::NCFiles';

	NCFiles->CompleteRoutFeed("d248468-02");

	print STDERR "ttt";

}

1;

