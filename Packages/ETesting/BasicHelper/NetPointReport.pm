
#-------------------------------------------------------------------------------------------#
# Description: Parse information from net point report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ETesting::BasicHelper::NetPointReport;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::FileHelper';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"reportPath"} = shift;

	$self->{"jobId"}  = undef;
	$self->{"step"}   = undef;
	$self->{"optSet"} = undef;

	# Test point summary
	$self->{"topTestPointCnt"} = 0;
	$self->{"botTestPointCnt"} = 0;
	$self->{"midPointCnt"}     = 0;

	$self->__ParseReport();

	return $self;
}

sub GetJobId {
	my $self = shift;

	return $self->{"jobId"};

}

sub GetStep {
	my $self = shift;

	return $self->{"step"};

}

sub GetReportPath {
	my $self = shift;

	return $self->{"reportPath"};
}

sub GetTopTestPointCnt {
	my $self = shift;

	return $self->{"topTestPointCnt"};
}

sub GetBotTestPointCnt {
	my $self = shift;

	return $self->{"botTestPointCnt"};
}

sub GetMidPointCnt {
	my $self = shift;

	return $self->{"midPointCnt"};
}

sub __ParseReport {
	my $self = shift;

	unless ( -e $self->{"reportPath"} ) {
		die "Net point report: " . $self->{"reportPath"} . " doesn't exist";
	}

	my @lines = @{ FileHelper->ReadAsLines( $self->{"reportPath"} ) };

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];

		next if ( $l =~ /^[\t\s]$/ );

		if ( $l =~ m/Job\s*:\s*(.*)/i ) {

			$self->{"jobId"} = $1;
			next;
		}

		if ( $l =~ m/Step\s*:\s*(.*)/i ) {

			$self->{"step"} = $1;
			next;
		}

		if ( $l =~ m/Optimization set\s*:\s*(.*)/i ) {

			$self->{"optSet"} = $1;
			next;
		}

		if ( $l =~ /Test Points summary/i ) {
			$i += 2;    # Skip one line

			$l = $lines[$i];
			$self->{"topTestPointCnt"} = ( $l =~ m/:\s*(\d*)/i )[0];
			$i++;
			$l = $lines[$i];
			$self->{"botTestPointCnt"} = ( $l =~ m/:\s*(\d*)/i )[0];
			$i++;
			$l = $lines[$i];
			$self->{"midPointCnt"} = ( $l =~ m/:\s*(\d*)/i )[0];
			$i++;
			$l = $lines[$i];
		}

		if ( $l =~ /Board nets summary/i ) {

		}

	}

	# Do some control of parsing

	die "Top TP count is not defined" unless ( defined $self->{"topTestPointCnt"} );
	die "Bot TP count is not defined" unless ( defined $self->{"botTestPointCnt"} );
	die "MP count is not defined"     unless ( defined $self->{"midPointCnt"} );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::ETesting::BasicHelper::NetPointReport';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d283629";

	my $path = 'c:\Export\test\report.txt';

	$inCAM->COM("et_optimization_text_report","output" => "file","out_file" => $path);


	my $nr = NetPointReport->new($path);

	print $nr;

}

1;

