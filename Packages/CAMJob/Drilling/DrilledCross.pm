#-------------------------------------------------------------------------------------------#
# Description:  Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Drilling::DrilledCross;

 

#3th party library
use strict;
use warnings;


#local library
use aliased 'Packages::Stackup::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Stackup::StackupBase::StackupBase';



#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub ComputeCrossDepths {
	my $self = shift;
	my $pcbId = shift;
	
	my $stackup = StackupBase->new($pcbId);
	my @thicks = $stackup->GetAllLayers();
	
	my @depths = ();

	for ( my $i = 0 ; $i < scalar(@thicks) ; $i++ ) {

		my $l         = $thicks[$i];
		my %depthInfo = ();

		if ( $i == 0 ) {
			$depthInfo{depth} = $l->GetThick() / 2;
			$depthInfo{thick} = $l->GetThick();

			push( @depths, \%depthInfo );
		}

		if ( GeneralHelper->RegexEquals( $l->{type}, Enums->MaterialType_PREPREG )
			|| GeneralHelper->RegexEquals( $l->{type}, Enums->MaterialType_CORE ))
		{

			#add actual prepreg thick
			my $th = $thicks[$i]->GetThick();

			#add both copper thicks. If actual prepreg is first in order, add 1/2 thicks of first of top copper
			$th +=
			  $thicks[ $i - 1 ]->GetThick() / 2 + $thicks[ $i + 1 ]->GetThick() / 2;

			if ( $i == 1 ) {
				$th += $thicks[ $i - 1 ]->GetThick() / 2;
			}

			#add previous computed depths
			if ( $i != 1 ) {
				$th += @depths[ scalar(@depths) - 1 ]->{depth};
			}

			#add complete depth to array
			$depthInfo{depth} = $th;

			#add info about copper thick
			if ( $i == 0 ) {
				$depthInfo{thick} = $thicks[$i]->GetThick();
			}
			else {
				$depthInfo{thick} = $thicks[ $i + 1 ]->GetThick();
			}

			push( @depths, \%depthInfo );
		}
	}

	#round depths to three digits. We add number 0.09 because of right rounding floats with one float number (example round(4.5) = 4. This is false)
	for ( my $i = 0 ; $i < scalar(@depths) ; $i++ ) {

		$depths[$i]->{depth} = sprintf( "%.0f", $depths[$i]->{depth} + 0.09 );
	}

	return @depths;
}


sub GetCrossDepthsHeader {
	my $self = shift;
	my @depths = @{ shift(@_) };
	my @newLines = ();
	
	#for right setting of "Q" number on each line
	my $qCounter = 0;
	my $lDepthsCnt = scalar(@depths);
	my $rNew    = "";


	for ( my $i = 0 ; $i < $lDepthsCnt ; $i++ ) {

		#we want to wtite only first and last three values
		if($i < 3 || $i >= $lDepthsCnt -3){

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

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

#print STDERR "You're running TESTS !!!\n";

# get stackup as hash
#my @stackup = StackupHelper->GetStackupThick("d9809");

#foreach my $l (@stackup){

# print $l->{type}.",".$l->{thick}." um\n";

#}

#my @depths = DrillCutScript->__ComputeDrillDepths(\@stackup);

#foreach my $l (@depths){

#	 print $l->{thick}." um, ".$l->{depth}." um\n";

#}

#DrillCutScript->SetDrillDeeps("d23909");

