#!/usr/bin/perl -w

#-------------------------------------------------------------------------------------------#
# Description: Temporary solution, move el tests from R:/El_test to user dir c:/Boards
# R:/El_test contain ipc exported on server computer
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::ETesting::MoveElTests;

#3th party library
use strict;
use warnings;
use File::Copy;

#loading of locale modules
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';

#3th party library
use strict;
use warnings;

use aliased 'Enums::EnumsPaths';

sub Move {

	my @files = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_ELTESTSIPC, "\.*" );

	@files = grep { $_ =~ /\w\d+t\.ipc/i } @files;
	if ( scalar(@files) ) {

		my $file = $files[0];
		my ($jobId) = $file =~ m/(\w\d+)t\.ipc/;
		my $dir = EnumsPaths->Client_ELTESTS .  $jobId . "t";

		unless ( -e $dir ) {

			mkdir($dir);
			move( $file, $dir . "\\$jobId" . "t.ipc" );
		}
	}
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#my $self             = shift;
	#	my $inCAM            = shift;

	use aliased 'Packages::ETesting::MoveElTests';

	MoveElTests->Move();

}

1;
