#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::DrilledCross;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Stackup::Enums' => "StackEnums";
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Stackup::Stackup::Stackup';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub ComputeCrossDepths {
	my $self  = shift;
	my $inCAM = shift;
	my $pcbId = shift;

	my $stackup = Stackup->new($inCAM, $pcbId);
	my @thicks  = $stackup->GetAllLayers();

	my @depths    = ();
	my $currDepth = 0;
	for ( my $i = 0 ; $i < scalar(@thicks) ; $i++ ) {

		my $l         = $thicks[$i];
		my %depthInfo = ();

		$currDepth += $l->GetThick();

		if ( $l->GetType() eq StackEnums->MaterialType_COPPER ) {

			$depthInfo{depth} = $currDepth - $l->GetThick() / 2 ;
			$depthInfo{thick} = $l->GetThick();

			push( @depths, \%depthInfo );
		}
	}

	return @depths;
}

sub GetCrossDepthsHeader {
	my $self     = shift;
	my @depths   = @{ shift(@_) };
	my @newLines = ();

	#for right setting of "Q" number on each line
	my $qCounter   = 0;
	my $lDepthsCnt = scalar(@depths);
	my $rNew       = "";

	for ( my $i = 0 ; $i < $lDepthsCnt ; $i++ ) {

		#we want to wtite only first and last three values
		if ( $i < 3 || $i >= $lDepthsCnt - 3 ) {

			$rNew = "M47,\\P:M1,Q" . sprintf( "%u", $qCounter + 1 ) . ",";
			$rNew .= "U" . sprintf( "%.3f", $depths[$i]->{depth} / 1000 ) . ",";
			$rNew .= "V" . sprintf( "%.3f", $depths[$i]->{thick} / 1000 );
			$rNew .= "\n";

			push( @newLines, $rNew );

			$qCounter++;
		}
	}
	return @newLines;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use Data::Dump qw(dump);

	use aliased 'Packages::CAMJob::Drilling::DrilledCross';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d152457";

	my $mess = "";

	my @l = ();
	my $result = NCLayerDir->CheckNpltDrillDir( $inCAM, $jobId, \@l );

	print STDERR "Result is: $result, error \n";

}

1;

