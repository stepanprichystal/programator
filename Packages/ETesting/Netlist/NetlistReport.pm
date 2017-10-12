
#-------------------------------------------------------------------------------------------#
# Description: Represent netlist report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::ETesting::Netlist::NetlistReport;

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
 

	$self->{"jobId"}     = undef;
	$self->{"jobIdRef"} = undef;
	#$self->{"time"}      = undef;

	$self->{"step"}     = undef;
	$self->{"stepRef"} = undef;    #
	$self->{"brokens"}  = 0;
	$self->{"shorts"}   = 0;
 

	$self->__ParseReport();

	return $self;
}

# if no shorts and brokens, return 1, else 0
sub Result {
	my $self = shift;

	if ( $self->{"brokens"} + $self->{"shorts"} > 0 ) {

		return 0;
	}
	else {

		return 1;
	}

}

sub GetJobId{
	my $self = shift;
	
	return $self->{"jobId"};
	
}


sub GetJobIdRef{
	my $self = shift;
	
	return $self->{"jobIdRef"};
	
}

sub GetStep{
	my $self = shift;
	
	return $self->{"step"};
	
}

sub GetStepRef{
	my $self = shift;
	
	return $self->{"stepRef"};
}

sub GetBrokens{
	my $self = shift;
	
	return $self->{"brokens"};
}

sub GetShorts{
	my $self = shift;
	
	return $self->{"shorts"};
}


sub __ParseReport {
	my $self = shift;

	unless ( -e $self->{"reportPath"} ) {
		die "Netlist report: " . $self->{"reportPath"} . " doesn't exist";
	}

	my @lines = @{ FileHelper->ReadAsLines( $self->{"reportPath"} ) };

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		my $l = $lines[$i];
		
		next if($l =~ /^[\t\s]$/);

		if ( $l =~ m/Job\s*:\s*(\w\d+)\s*Job\s*:\s*(\w\d+)/i ) {

			$self->{"jobId"}     = $1;
			$self->{"jobIdRef"} = $2;
			next;
		}

		if ( $l =~ m/Step\s*:\s*(.*)\s*Step\s*:\s*(.*)/i ) {

			$self->{"step"}     = $1;
			$self->{"stepRef"} = $2;
			
			$self->{"step"} =~ s/\s//g;
			$self->{"stepRef"} =~ s/\s//g;
			
			next;
		}

		if ( $l =~ /Mismatch Type: Brokens/i ) {

			for ( ; $i < scalar(@lines) ; $i++ ) {
				$l = $lines[$i];
				if ( $l =~ /Total\s*:\s*(\d+)/i ) {

					$self->{"brokens"} = $1;
					last;
				}
			}
		}
		
		if ( $l =~ /Mismatch Type: Shorts/i ) {

			for ( ; $i < scalar(@lines) ; $i++ ) {
				$l = $lines[$i];
				if ( $l =~ /Total\s*:\s*(\d+)/i ) {

					$self->{"shorts"} = $1;
							last;
				}
			}
		}

		if ( $l =~ /Mismatch Type: Missings/i ) {
			last;

		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {
	
 
	use aliased 'Packages::ETesting::Netlist::NetlistReport';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52456";

	my $nr = NetlistReport->new('c:/Export/netlist');	
	
	print $nr; 

	 
	
	

}

1;

