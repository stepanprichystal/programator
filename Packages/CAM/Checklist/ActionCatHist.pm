
#-------------------------------------------------------------------------------------------#
# Description: Class which store histogram from action report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionCatHist;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Helpers::JobHelper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"layer"}  = shift;
	$self->{"values"} = [];

	return $self;
}

sub AddItem {
	my $self       = shift;
	my $from       = shift;
	my $to         = shift;
	my $count      = shift;
	my $reportLine = shift;

	push( @{ $self->{"values"} }, { "from" => $from, "to" => $to, "count" => $count, "reportLine" => $reportLine } );

}

# Each item contain kyes
# from - start of range
# to - end of range
# count - number of occurances values from range for specific layer
# report line - original line form InCAM report
sub GetHistValues {
	my $self = shift;

	return @{ $self->{"values"} };
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::Netlist::NetlistCompare';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f84934";

	my $nc = NetlistCompare->new( $inCAM, $jobId );

	my $report = $nc->ComparePanel("mpanel");

	#my $report = $nc->Compare1Up( "o+1", "o+1_panel" );

	print $report->Result();

}

1;

