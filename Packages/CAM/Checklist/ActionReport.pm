
#-------------------------------------------------------------------------------------------#
# Description: Keep parsed information from InCAM action Report
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::Checklist::ActionReport;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library

use aliased 'Enums::EnumsChecklist';
use aliased 'Packages::CAM::Checklist::ActionCat';

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

	$self->{"categories"} = [];

	return $self;
}

sub GetCategory {
	my $self = shift;
	my $name = shift;

	my $cat = ( grep { $_->GetName() eq $name } @{ $self->{"categories"} } )[0];

	return $cat;
}

sub GetCategoryHists {
	my $self         = shift;
	my $categoryName = shift;
	my $layers       = shift // [];

	my $cat = $self->GetCategory($categoryName);

	die "Category: $categoryName was not found" unless ( defined $cat );

	unless ( defined $layers ) {
		@{$layers} = $cat->GetLayerNames();
	}

	my @hist = ();

	foreach my $l ( @{$layers} ) {

		push( @hist, $cat->GetCategoryHist($l) );
	}

	return @hist;
}

sub GetLayerNames {
	my $self = shift;

	my @layers = map { $_->GetLayerNames() } @{ $self->{"categories"} };

	@layers = uniq(@layers);

	return @layers;
}

sub AddCategory {
	my $self         = shift;
	my $categoryName = shift;
	my $categoryDesc = shift;

	my $cat = ActionCat->new( $categoryName, $categoryDesc );

	push( @{ $self->{"categories"} }, $cat );

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

