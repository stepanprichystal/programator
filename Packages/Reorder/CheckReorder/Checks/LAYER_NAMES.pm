#-------------------------------------------------------------------------------------------#
# Description:  Class responsible for determine pcb reorder check
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Reorder::CheckReorder::Checks::LAYER_NAMES;
use base('Packages::Reorder::CheckReorder::Checks::CheckBase');

use Class::Interface;
&implements('Packages::Reorder::CheckReorder::Checks::ICheck');

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamJob';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless($self);

	return $self;
}

# Check if mask is not negative in matrix
sub NeedChange {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $jobExist = shift;    # (in InCAM db)
	my $isPool   = shift;
	my $detail   = shift;    # reference on detail message (manual task)
	my $data     = shift;    # reference on data for process automatic task

	unless ($jobExist) {
		return 1;
	}

	my $needChange = 0;

	my @layers = CamJob->GetAllLayers( $inCAM, $jobId );

	# Check if there are wron layer names

	# old format of paste files sa_ori, sb_ori
	if ( scalar( grep { $_->{"gROWname"} =~ /^s[ab]_(ori)|(made)$/ } @layers ) ) {
		$needChange = 1;
	}

	return $needChange;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::Reorder::CheckReorder::Checks::LAYER_NAMES' => "Change";
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f00873";

	my $check = Change->new();

	print "Need change: " . $check->NeedChange( $inCAM, $jobId, 1 );
}

1;

