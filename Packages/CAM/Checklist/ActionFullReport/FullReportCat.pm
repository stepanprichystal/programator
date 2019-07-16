
#-------------------------------------------------------------------------------------------#
# Description: Represent category of parser action InCAM report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionFullReport::FullReportCat;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::Checklist::ActionFullReport::FullReportCatVal';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"categoryKey"}   = shift;    # category key
	$self->{"categoryTitle"} = shift;
	$self->{"values"}        = [];       # hash layer

	return $self;
}

sub GetCatKey {
	my $self = shift;

	return $self->{"name"};
}

sub GetCatTitle {
	my $self = shift;

	return $self->{"categoryTitle"};
}

sub GetCatValues {
	my $self     = shift;
	my $layer    = shift;
	my $severity = shift; # EnumsChecklist->Sev_xxx

	my @vals = @{ $self->{"values"} };

	@vals = grep { $_->GetLayer() eq $layer } @vals       if ( defined $layer );
	@vals = grep { $_->GetSeverity() eq $severity } @vals if ( defined $severity );

	return @vals;
}

sub AddActionCatVal {
	my $self      = shift;
	my $layer     = shift;
	my $value     = shift;
	my $symbol1   = shift;
	my $symbol2   = shift;
	my $measType  = shift;
	my $defPos1   = shift;
	my $defPos2   = shift;
	my $defExtra1 = shift;
	my $defExtra2 = shift;
	my $severity  = shift;

	my $val = FullReportCatVal->new( $layer, $value, $symbol1, $symbol2, $measType, $defPos1, $defPos2, $defExtra1, $defExtra2, $severity );

	push( @{ $self->{"values"} }, $val );

	return $val;
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

