#-------------------------------------------------------------------------------------------#
# Description: Function which solve rout duplicate issue
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Routing::RoutDuplicated::RoutDuplicated;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'Packages::TifFile::TifNCOperations';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return if rout should be duplicated
# It depands on if rout is outline and if is defined in "rout duplicate table"
sub GetDuplicateRout {
	my $self      = shift;
	my $jobId     = shift;
	my $toolSize  = shift;    # µm
	my $toolChain = shift;
	my $layer     = shift;
	my $step      = shift;

	my $toolDuplicated = 0;

	my $tif = TifNCOperations->new($jobId);

	return 0 unless ( $tif->TifFileExist() );

	# Check if tool is not outline (inly inside rout can be duplicated)
	my $tInfo = $tif->GetToolInfo( $toolChain, $layer, $step );

	if ( defined $tInfo && !$tInfo->{"isOutline"} ) {

		my $confPath = GeneralHelper->Root() . "\\Packages\\CAMJob\\Routing\\RoutDuplicated\\RoutDuplicated.txt";

		unless ( -e $confPath ) {
			die "Configuration file $confPath doesn't exists";
		}

		my @lines = @{ FileHelper->ReadAsLines($confPath) };

		@lines = grep { $_ !~ /^#/ && $_ =~ /\d+=\d\.?\d*/ } @lines;

		my $val = undef;

		foreach my $l (@lines) {
			my @arr = split( "=", $l );
			if ( $arr[0] == $toolSize ) {
				$toolDuplicated = 1;
				last;
			}
		}
	}

	return $toolDuplicated;
}

# Return speed for duplicate rout
sub GetRoutSpeed {
	my $self = shift;
	my $toolSize = shift;

	my $routSpeed = undef;

	my $confPath = GeneralHelper->Root() . "\\Packages\\CAMJob\\Routing\\RoutDuplicated\\RoutDuplicated.txt";

	unless ( -e $confPath ) {
		die "Configuration file $confPath doesn't exists";
	}

	my @lines = @{ FileHelper->ReadAsLines($confPath) };

	@lines = grep { $_ !~ /^#/ && $_ =~ /\d+=\d\.?\d*/ } @lines;

	my $val = undef;

	foreach my $l (@lines) {
		
		my @arr = split( "=", $l );
		chomp(@arr);
		if ( $arr[0] == $toolSize ) {
			$routSpeed = $arr[1];
			last;
		}
	}
	
	die "Rout speed is not defined for duplicated rout of drill size: $toolSize um" unless (defined $routSpeed) ;
	
	return $routSpeed;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	#use Data::Dump qw(dump);
	#
	#	use aliased 'Packages::CAMJob::Routing::RoutSpeed::RoutSpeed';
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $result = RoutSpeed->GetRoutSpeedTable( 1600, 1000, 8, ["f"] );
	#
	#	print STDERR "Result is: $result";

}

1;
