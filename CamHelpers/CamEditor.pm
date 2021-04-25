#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains function working with InCAM editor
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamEditor;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return number of free editor license
sub GetFreeEditorLicense {
	my $self  = shift;
	my $inCAM = shift;

	my $free = 0;

	my $p = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();

	my $res = $inCAM->COM( "license", "op" => "Usage", "out_file" => $p );

	my @lines = @{ FileHelper->ReadAsLines($p) };

	if ( -e $p ) {
		unlink($p);
	}

	my ( $cur, $max ) = undef;

	foreach (@lines) {

		#		if ( $_ =~ m/gedit64\s*(\d+)\s*(\d+)/ ) {
		#			$cur = $1;
		#			$max = $2;
		#			last;
		#		}
		if ( $_ =~ m/incamfl\s*(\d+)\s*(\d+)/ ) {
			$cur = $1;
			$max = $2;
			last;
		}
	}

	if ( defined $cur && defined $max ) {

		$free = $max - $cur;
	}
	else {
		die "No license number defined\n";
	}

	return $free;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamEditor';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "f13608";
	my $stepName = "panel";

	my $num = CamEditor->GetFreeEditorLicense($inCAM);

	print $num;

}

1;
