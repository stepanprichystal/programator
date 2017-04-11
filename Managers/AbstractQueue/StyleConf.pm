#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Managers::AbstractQueue::StyleConf;

#3th party library
use strict;
use warnings;
use Wx;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return base cu thick by layer
sub GetColor {
	my $self = shift;
	my $key  = shift;

	my $val = $self->__GetVal($key);
	
	my @rgb = split(",", $val);
	
	chomp @rgb;
	
	for(my $i = 0; $i < scalar(@rgb); $i++){
		$rgb[$i] =~ s/\s//g;	
	} 
	 	
 
	my $clr =  Wx::Colour->new( $rgb[0], $rgb[1], $rgb[2] );
	
	return $clr;
}


sub __GetVal{
	my $self = shift;
	my $key  = shift;
	
	print STDERR $main::stylePath;
	
	unless ( -e $main::stylePath ) {
		die "Configuration style file doesn't exist";
	}

	my @lines = @{ FileHelper->ReadAsLines($main::stylePath) };
 
	foreach my $l (@lines){
		my @arr = split("=", $l);
		if($arr[0] =~ /$key/){
			return $arr[1];
		}
	}
 
}

sub CheckRunningInstance {
	my $self       = shift;
	my $scriptName = shift;                                        # name of running script

	my $exist = 0;

	my $procName;
	my $args;
	my $p    = Win32::Process::List->new();
	my $pi   = Win32::Process::Info->new();
	my %list = $p->GetProcesses();

	foreach my $pid ( sort { $a <=> $b } keys %list ) {
		$procName = $list{$pid};

		if ( $procName =~ /^perl.exe/i ) {

			my $procInfo = $pi->GetProcInfo($pid);
			if ( defined $procInfo && scalar( @{$procInfo} ) ) {

				$args = @{$procInfo}[0]->{"CommandLine"};

				if ( defined $args && $args =~ /RunAbstractQueueScript.pl/ ) {

					$exist = 1;
					last;
				}
			}
		}

	}

	return $exist;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Helpers::JobHelper';

	#print JobHelper->GetBaseCuThick("F13608", "v3");

	#print "\n1";
}

1;

