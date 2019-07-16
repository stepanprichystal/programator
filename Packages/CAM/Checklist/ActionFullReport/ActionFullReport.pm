
#-------------------------------------------------------------------------------------------#
# Description: Keep parsed information from InCAM checklist action result
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionFullReport::ActionFullReport;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Enums::EnumsChecklist';
use aliased 'Packages::CAM::Checklist::ActionFullReport::FullReportCat';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"checklist"} = shift;    # Checklist name
	$self->{"action"}    = shift;    # action order in checklsit
	$self->{"datetime"}  = shift;    # date and time from last action run

	$self->{"categories"} = {};

	return $self;
}

sub GetCategory {
	my $self = shift;
	my $key  = shift; # EnumsChecklist->Cat_

	my $cat = $self->{"categories"}->{$key};

	return $cat;
}
 

sub AddCategory {
	my $self         = shift;
	my $catCode = shift;
	my $catTitle = shift;

	my $cat = FullReportCat->new($catCode, $catTitle);

	$self->{"categories"}->{$catCode} = $cat;

	return $cat;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::Netlist::NetlistReport';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "f52456";

	my $nr = NetlistReport->new('c:/Export/netlist');

	print $nr;
}

1;

