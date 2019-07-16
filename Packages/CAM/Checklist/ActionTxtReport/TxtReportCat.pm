
#-------------------------------------------------------------------------------------------#
# Description: Represent category of parser action InCAM report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionTxtReport::TxtReportCat;

#3th party library
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::Checklist::ActionTxtReport::TxtReportCatHist';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"name"}     = shift;    # action title
	$self->{"histDesc"} = shift;    # string legend for action histogram values
	$self->{"layers"}   = {};       # hash layer

	return $self;
}

sub GetName {
	my $self = shift;

	return $self->{"name"};
}

# Return all layer name occuring in this category
sub GetLayerNames {
	my $self = shift;

	return keys %{ $self->{"layers"} };
}

sub GetHistDescription {
	my $self = shift;

	return $self->{"histDesc"};
}

sub AddCategoryHist {
	my $self  = shift;
	my $lName = shift;

	$self->{"layers"}->{$lName} = TxtReportCatHist->new($lName);

	return $self->{"layers"}->{$lName};
}

sub GetCategoryHist {
	my $self  = shift;
	my $layer = shift;

	die "Category histogram doesn't exist for layer: $layer" unless ( defined $self->{"layers"}->{$layer} );

	return $self->{"layers"}->{$layer};
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

