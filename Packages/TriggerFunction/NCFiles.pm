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
use aliased 'Packages::TifFile::TifNCOperations';
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
	#	 »Ìslo pds
	#	 -Tlouöùka mÏdi
	#		  < 18  => "/"
	#		  < 35=> "-"
	#		  < 70=> ":"
	#		  < 105=> "+"
	#		   ostatnÌ=> "++"
	#	 Po¯adovÈ ËÌslo objedn·vky
	#	 »Ìslo stroje na kterÈ se zak·zka vrt· (A-F)
	#	 »Ìslo vrtanÈho j·dra

	foreach my $filename (@ncFiles) {

		my $file = path($filename);

		my $data = $file->slurp_utf8;
		$data =~ s/(m97,[a-f][\d]+[\/\-\:\+]{0,2})\d*/$1$orderNum/i;
		$file->spew_utf8($data);

	}

	return 1;
}

# Put rout feed speed to all rout tool calling in all programs
sub CompleteRoutFeed {
	my $self    = shift;
	my $orderId = shift;

	my $jobId = $orderId;
	$jobId =~ s/-.*$//;

	my $tif = TifNCOperations->new($jobId);

	return 0 unless ( $tif->TifFileExist() );
	
	my $info = HegMethods->GetInfoAfterStartProduce($orderId);
 	
	die "pocet_prirezu is no defined in HEG for orderid: $orderId" if ( !defined $info->{'pocet_prirezu'} || !defined $info->{'prirezu_navic'} );
 	my $totalPnlCnt = $info->{'pocet_prirezu'} + $info->{'prirezu_navic'};
 
	my $ncPath = JobHelper->GetJobArchive($jobId) . "nc\\";
 

	#filter only files, which include pcb number

	my @ncOperations = $tif->GetNCOperations();

	foreach my $ncOper (@ncOperations) {
		
		my %routSpeedTab = RoutSpeed->GetRoutSpeedTable( 1600, 1000, 8, ["f"] );
	 
		next unless ( $ncOper->{"isRout"} );

		foreach my $m ( keys %{ $ncOper->{"machines"} } ) {

			my $ncFile = $ncPath . $jobId . "_" . $ncOper->{"opName"} . "." . $m;

			die "NCFile doesn't exist $ncFile" unless ( -e $ncFile );

			

				my $file = path($ncFile);

				my $data = $file->slurp_utf8;
				
				foreach my $toolKey  ( keys %{$ncOper->{"machines"}->{$m}}){
				
				
				
 

				

	 
				
				}
				
				$data =~ s/(m97,[a-f][\d]+[\/\-\:\+]{0,2})\d*/$1$orderNum/i;
				
				
				
				$file->spew_utf8($data);

			}

		}

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::TriggerFunction::NCFiles';

	NCFiles->ChangePcbOrderNumber("f52456-01");

	print STDERR "ttt";

}

1;

