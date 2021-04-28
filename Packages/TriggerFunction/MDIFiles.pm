#-------------------------------------------------------------------------------------------#
# Description: Contains trigger methods, which work with MDI files
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::TriggerFunction::MDIFiles;

#3th party library
use strict;
use warnings;
use Path::Tiny qw(path);
use Log::Log4perl qw(get_logger :levels);
use File::Copy qw(move);

#loading of locale modules
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';

#my $genesis = new Genesis;

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Function add value of tag <parts_total>, <parts_remaining> in each mdi-xml file of requested job
# parameter $orderId is eg: F12345-01
sub AddPartsNumber {
	my $self    = shift;
	my $orderId = shift;

	my $logger = get_logger("trigger");

	my $jobId = $orderId;
	$jobId =~ s/-.*$//;

	my $reg = $jobId . ".*_mdi.xml";

	my @xmlFiles = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_MDI, $reg );

	unless ( scalar(@xmlFiles) ) {

		$logger->debug("No xml files - $jobId found");
		return 1;
	}

	my $info = HegMethods->GetInfoAfterStartProduce($orderId);

	$logger->debug( "pocet_prirezu == " . $info->{'pocet_prirezu'} . ",  prirezu_navic == " . $info->{'prirezu_navic'} );

	$logger->debug("pocet_prirezu is not defined") if ( !defined $info->{'pocet_prirezu'} );
	$logger->debug("prirezu_navic is not defined") if ( !defined $info->{'prirezu_navic'} );

	if ( !defined $info->{'pocet_prirezu'} || !defined $info->{'prirezu_navic'} ) {
		return 0;
	}

	my $parts = $info->{'pocet_prirezu'} + $info->{'prirezu_navic'};

	$logger->debug("total parts =  $parts");

	foreach my $filename (@xmlFiles) {

		$logger->debug("update file: $filename");

		my $file = path($filename);

		my $data = $file->slurp_utf8;

		if ( $data =~ /(<parts_remaining>)(\d*)(<\/parts_remaining>)/ ) {
			$logger->debug("parts_remaining found ok");
		}

		$data =~ s/(<parts_remaining>)(\d*)(<\/parts_remaining>)/$1$parts$3/i;
		$data =~ s/(<parts_total>)(\d*)(<\/parts_total>)/$1$parts$3/i;
		$file->spew_utf8($data);

	}

	return 1;
}

sub AddPartsNumberMDITT {
	my $self    = shift;
	my $orderId = shift;

	my $logger = get_logger("trigger");

	my $jobId = $orderId;
	$jobId =~ s/-.*$//;

	my $reg = $jobId . ".*_mdi.jobconfig_uncomplete.xml";

	my @xmlFiles = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_PCBMDITT, $reg );

	unless ( scalar(@xmlFiles) ) {

		$logger->debug("No xml files - $jobId found");
		return 1;
	}

	my $info = HegMethods->GetInfoAfterStartProduce($orderId);

	$logger->debug( "pocet_prirezu == " . $info->{'pocet_prirezu'} . ",  prirezu_navic == " . $info->{'prirezu_navic'} );

	$logger->debug("pocet_prirezu is not defined") if ( !defined $info->{'pocet_prirezu'} );
	$logger->debug("prirezu_navic is not defined") if ( !defined $info->{'prirezu_navic'} );

	if ( !defined $info->{'pocet_prirezu'} || !defined $info->{'prirezu_navic'} ) {
		return 0;
	}

	my $parts = $info->{'pocet_prirezu'} + $info->{'prirezu_navic'};

	$logger->debug("total parts =  $parts");

	foreach my $filename (@xmlFiles) {

		$logger->debug("update file: $filename");

		my $file = path($filename);

		my $data = $file->slurp_utf8;

		if ( $data =~ /(<parts_remaining>)(\d*)(<\/parts_remaining>)/ ) {
			$logger->debug("parts_remaining found ok");

			$data =~ s/(<parts_remaining>)(\d*)(<\/parts_remaining>)/$1$parts$3/i;
			$data =~ s/(<parts_total>)(\d*)(<\/parts_total>)/$1$parts$3/i;
			$file->spew_utf8($data);

		}

		# Rename file to let JobEditor process xml
		my $newName = $filename;
		$newName =~ s/jobconfig_uncomplete/jobconfig/i;

		unless ( move( $filename, $newName ) ) {

			$logger->debug( "Error during rename file:" . $filename );
		
		}
		else {

			$logger->debug("Rename file to: $newName");

		}
	}

	return 1;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::TriggerFunction::MDIFiles';

	my $test = MDIFiles->AddPartsNumberMDITT("d318536-01");

	print $test;

}

1;
