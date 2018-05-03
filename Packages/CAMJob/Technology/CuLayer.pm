#-------------------------------------------------------------------------------------------#
# Description: Silkscreen checks
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Technology::CuLayer;

#3th party library
use utf8;
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

# Return maximal value of cu layer by pcb class
sub GetMaxCuByClass {
	my $self  = shift;
	my $class = shift;
	my $inner = shift;
 	
	my $isolation = JobHelper->GetIsolationByClass($class);
	 

	my $p = GeneralHelper->Root() . "\\Resources\\CuClassRel";

	die "Table definiton: $p doesn't exist" unless ( -e $p );

	my @lines = grep { $_ =~ /^\d+\s*=/ } @{ FileHelper->ReadAsLines($p) };
	
	
	my %h = ();
	my %hInner = ();
	
	foreach my $l  (@lines){
		my ($isol, $cuThickness, $cuThicknessInner) = $l =~ /(\d+)\s*=\s*(\d+)\s*;\s*(\d+)/i;
		$h{$isol} = $cuThickness;
		$hInner{$isol} = $cuThicknessInner;
	}
	
	my $maxCu = undef;
	
	if($inner){
		$maxCu = $hInner{$isolation};
	}else{
		$maxCu = $h{$isolation};
	}
 
	die "Max Cu thiockness is not defined" if(!defined $maxCu || $maxCu eq "" || $maxCu == 0);
	
	return $maxCu;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Technology::CuLayer';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	my $mess = "";

	my $result = CuLayer->GetMaxCuByClass( 5, 1 );

	print STDERR "Result is: $result";

}

1;
