
#-------------------------------------------------------------------------------------------#
# Description: Represent single measured value with info (position, severity, ref features)
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionFullReport::FullReportCatVal;

#3th party library
use strict;
use warnings;

#local library
 

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"layer"} = shift;

	# a) Distance in microns betwwen features
	# b) Diemension of single features in microns
	$self->{"value"} = shift;

	# First symbol dcode which the measurement relates (not empty)
	$self->{"symbol1"} = shift;

	# Second symbol dcode which the measurement relates (can by empty)
	$self->{"symbol2"} = shift;

	# Type of measurement definition: SG, LN, RC
	# SG - measurement defined by line with two positions
	# LN - measurement defined by line with two positions + margin arounf line in mm
	# RC - measurement defined by single point position + 2 margins (left + right; top + bot)

	$self->{"measType"} = shift;

	# Position of first defined symbol ("symbol1"). Hash with key:x;y
	$self->{"defPos1"} = shift;

	# Position of first defined symbol ("symbol2"). Hash with key:x;y
	$self->{"defPos2"} = shift;

	$self->{"defExtra1"} = shift;
	
	$self->{"defExtra2"} = shift;
 
	$self->{"severity"} = shift;


	return $self;
}

sub GetLayer{
	my $self = shift;
	
	return $self->{"layer"};
}

sub GetValue{
	my $self = shift;
	
	return $self->{"value"};
}

# Return first symbol code, which relates with measurement 
sub GetSymbol1{
	my $self = shift;
	
	return $self->{"symbol1"};
}

# Return seciond symbol code, which relates with measurement 
sub GetSymbol2{
	my $self = shift;
	
	return $self->{"symbol2"};
}

# Return severity of measurement 
sub GetSeverity{
	my $self = shift;
	
	return $self->{"severity"};
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

