#-------------------------------------------------------------------------------------------#
# Description: Create single TableDrawing for every traveler page
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Traveler::UniTravelerTmpl::UniTravelerTmpl;

use Class::Interface;
&implements('Packages::CAMJob::Traveler::ITravelerBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Other::TableDrawing::DrawingBuilders::Enums' => 'EnumsDrawBldr';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::UniTravelerSingle';
use aliased 'Packages::CAMJob::Traveler::UniTravelerTmpl::TravelerMngr';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"}          = shift;
	$self->{"jobId"}          = shift;
	$self->{"ITravelerBldrs"} = shift;

	$self->{"step"}           = "panel";
	$self->{"travelerSingle"} = [];
	$self->{"travelerMngr"}   = TravelerMngr->new( $self->{"inCAM"}, $self->{"jobId"}, $self->{"step"} );

	return $self;
}

# Prepare table drawing for each laminations
sub Build {
	my $self       = shift;
	my $pageWidth  = shift // 210;    # A4 width mm
	my $pageHeight = shift // 290;    # A4 height mm

	my $result = 1;

	my $inCAM    = $self->{"inCAM"};
	my $jobId    = $self->{"jobId"};
	my $trvlMngr = $self->{"travelerMngr"};

	# 1) Init single travelers
	my @ITravelerBldrs = @{ $self->{"ITravelerBldrs"} };

	for ( my $i = 0 ; $i < scalar( scalar(@ITravelerBldrs) ) ; $i++ ) {

		my $tSngl = UniTravelerSingle->new( $inCAM, $jobId, $self->{"travelerMngr"}, $ITravelerBldrs[$i], $i + 1 );
		push( @{ $self->{"travelerSingle"} }, $tSngl );
	}

	# 2)Build travelers

	foreach my $tSngl ( @{ $self->{"travelerSingle"} } ) {

		unless ( $tSngl->Build( $pageWidth, $pageHeight ) ) {
			$result = 0;
		}
	}

	return $result;
}

# Return prepared table drawing
sub GetTblDrawings {
	my $self = shift;

	my @drawings = ();
	push( @drawings, $_->GetTblDrawing() ) foreach ( @{ $self->{"travelerSingle"} } );

	return @drawings;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

