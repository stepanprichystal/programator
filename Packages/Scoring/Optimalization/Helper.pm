#-------------------------------------------------------------------------------------------#
# Description: Helper module contain methods for correct score line direction etc
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::Optimalization::Helper;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::Scoring::Optimalization::Enums';
use aliased 'Packages::Polygon::Features::ScoreFeatures::ScoreFeatures';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#We assume, score lines ares strictly vertical or horizontal!
#Remove all duplicate lines, which are in tolerance
sub RemoveDuplication {
	my $self    = shift;
	my @lines   = @{ shift(@_) };
	my $changes = shift;
	my $errors  = shift;

	my $actDir;
	my $investPoint;
	my $tolerance = 0.5;    #it means, test if score are overlapping +-0.1mm

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		$actDir = $lines[$i]->{"direction"};

		for ( my $j = 0 ; $j < scalar(@lines) ; $j++ ) {

			if (    $i != $j
				 && ( $lines[$i]->{"remove"} != 1 && $lines[$j]->{"remove"} != 1 )
				 && $lines[$j]->{"direction"} eq $actDir )
			{

				if ( $actDir eq "vertical" ) {
					$investPoint = "x1";
				}
				elsif ( $actDir eq "horizontal" ) {
					$investPoint = "y1";
				}

				if ( abs( $lines[$i]->{$investPoint} - $lines[$j]->{$investPoint} ) <= $tolerance ) {
					$lines[$j]->{"remove"} = 1;
					$$changes = 1;
				}
			}
		}
	}

	if ($$changes) {
		for ( my $i = scalar(@lines) - 1 ; $i >= 0 ; $i-- ) {

			if ( $lines[$i]->{"remove"} ) {
				splice @lines, $i, 1;    #remove duplicate line
			}
		}
	}

	return @lines;
}

#return 0 if distance of score from profile is wrong (too small/big), else return 1
sub CheckProfileDistance {
	my $self    = shift;
	my @lines   = @{ shift(@_) };
	my %profile = %{ shift(@_) };
	my $dist    = shift;
	my $errors  = shift;

	my $result    = Enums->ScoreLength_OK;
	my $tolerance = 0.1;

	#10mm, score can be max 10mm distance from profile, 
	# because score machine end scoring approx 10mm after end of line
	my $maxGap = 10;    

	my $p;

	@lines = $self->__MakeLineSameDir( \@lines );

	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {

		if ( $lines[$i]->{"direction"} eq "vertical" ) {

			#check if line is not too long
			if (    $lines[$i]->{"y1"} < $profile{"ymin"} + $dist
				 || $lines[$i]->{"y2"} > $profile{"ymax"} - $dist )
			{
				$result = Enums->ScoreLength_TOOLONG;
				last;
			}

			#check if line is not too short
			if (    ( ( $lines[$i]->{"y1"} - $profile{"ymin"} ) < 0 || ( $lines[$i]->{"y1"} - $profile{"ymin"} ) < $maxGap )
				 && ( ( $lines[$i]->{"y2"} - $profile{"ymax"} ) > 0 || ( $profile{"ymax"} - $lines[$i]->{"y2"} ) < $maxGap ) ) 
			  {

				  #ok
			}
			else {

				  $result = Enums->ScoreLength_TOOSHORT;
				  last;
			}

		}
		elsif ( $lines[$i]->{"direction"} eq "horizontal" ) {

			 #check if line is not too long
			if (    $lines[$i]->{"x1"} < $profile{"xmin"} + $dist
				 || $lines[$i]->{"x2"} > $profile{"xmax"} - $dist )
			{
				  $result = Enums->ScoreLength_TOOLONG;
				  last;
			  }

			  #check if line is not too short
			  if (    ( ( $lines[$i]->{"x1"} - $profile{"xmin"} ) < 0 || ( $lines[$i]->{"x1"} - $profile{"xmin"} ) < $maxGap )
				   && ( ( $lines[$i]->{"x2"} - $profile{"xmax"} ) > 0 || ( $profile{"xmax"} - $lines[$i]->{"x2"} ) < $maxGap ) ) 
				{

					#ok
			  }
			  else {

					$result = Enums->ScoreLength_TOOSHORT;
					last;
			  }
		}

	}

	return $result;

}

#return 0 if distance of score from profile is wrong (too small/big), else return 1
#sub CheckProfileDistance {
#	my $self    = shift;
#	my @lines   = @{ shift(@_) };
#	my %profile = %{ shift(@_) };
#	my $dist    = shift;
#	my $errors  = shift;
#
#	my $result    = Enums->ScoreLength_OK;
#	my $tolerance = 0.1;
#	my $p;
#
#	@lines = $self->__MakeLineSameDir( \@lines );
#
#	for ( my $i = 0 ; $i < scalar(@lines) ; $i++ ) {
#
#		if ( $lines[$i]->{"direction"} eq "vertical" ) {
#
#			#check if line is not too long
#			if (    $lines[$i]->{"y1"} - $dist < $profile{"ymin"}
#				 || $lines[$i]->{"y2"} + $dist > $profile{"ymax"} )
#			{
#				$result = Enums->ScoreLength_TOOLONG;
#				last;
#			}
#
#			#check if line is not too short
#			if (    $lines[$i]->{"y1"} - $dist < $profile{"ymin"}
#				 || $lines[$i]->{"y2"} + $dist < $profile{"ymax"} )
#			{
#				$result = Enums->ScoreLength_TOOSHORT;
#				last;
#			}
#
#		}
#		elsif ( $lines[$i]->{"direction"} eq "horizontal" ) {
#
#			#check if line is not too long
#			if (    $lines[$i]->{"x1"} - $dist < $profile{"xmin"}
#				 || $lines[$i]->{"x2"} + $dist > $profile{"xmax"} )
#			{
#				$result = Enums->ScoreLength_TOOLONG;
#				last;
#			}
#
#			#check if line is not too short
#			if (    $lines[$i]->{"x1"} - $dist + 4 > $profile{"xmin"}
#				 || $lines[$i]->{"x2"} + $dist + 4 > $profile{"xmax"} )
#			{
#				$result = Enums->ScoreLength_TOOSHORT;
#				last;
#			}
#		}
#
#	}
#
#	return $result;
#
#}

sub AdaptScoreToProfile {
	  my $self    = shift;
	  my @lines   = @{ shift(@_) };
	  my %profile = %{ shift(@_) };
	  my $dist    = shift;            #inner distance from profile
	  my $errors  = shift;

	  my $tolerance = 1.0;
	  my $p;

	  @lines = $self->__MakeLineSameDir( \@lines );

	  for ( my $i = 0 ;
			$i < scalar(@lines) ;
			$i++ )
	  {

		  if ( $lines[$i]->{"direction"} eq "vertical" ) {
			  $p = "y";
		  }
		  elsif ( $lines[$i]->{"direction"} eq "horizontal" ) {
			  $p = "x";
		  }

		  $lines[$i]->{ $p . "1" } = $profile{ $p . "min" } + $dist;
		  $lines[$i]->{ $p . "2" } = $profile{ $p . "max" } - $dist;
	  }

	  return @lines;
}

#make all lines with same way
#verticall line down-to-up
#horizontal line left-to-right
sub __MakeLineSameDir {
	  my $self  = shift;
	  my @lines = @{ shift(@_) };

	  my $v;

	  #sort start, end point
	  for ( my $i = 0 ;
			$i < scalar(@lines) ;
			$i++ )
	  {

		  #switch
		  if ( $lines[$i]->{"x1"} > $lines[$i]->{"x2"} ) {
			  $v                 = $lines[$i]->{"x1"};
			  $lines[$i]->{"x1"} = $lines[$i]->{"x2"};
			  $lines[$i]->{"x2"} = $v;
		  }
		  if ( $lines[$i]->{"y1"} > $lines[$i]->{"y2"} ) {
			  $v                 = $lines[$i]->{"y1"};
			  $lines[$i]->{"y1"} = $lines[$i]->{"y2"};
			  $lines[$i]->{"y2"} = $v;
		  }
	  }

	  return @lines;
}

#Check if all score line are strictly horizontal or vertical
sub GetStraightScore {
	  my $self    = shift;
	  my @lines   = @{ shift(@_) };
	  my $changes = shift;
	  my $errors  = shift;

	  unless (@lines) {
		  print STDERR "Array of score lines is empty";
	  }

	  for ( my $i = 0 ;
			$i < scalar(@lines) ;
			$i++ )
	  {

		  if ( $lines[$i]->{"direction"} eq "horizontal" ) {

			  my $dY = abs( $lines[$i]->{"y1"} - $lines[$i]->{"y2"} );

			  if ( $dY > 0 ) {

				  my $newY = sprintf( "%.4f", ( $lines[$i]->{"y1"} + $lines[$i]->{"y2"} ) / 2 );

				  $lines[$i]->{"y1"}        = $newY;
				  $lines[$i]->{"y2"}        = $newY;
				  $lines[$i]->{"corrected"} = 1;

				  $$changes = 1;
			  }
			  else { $lines[$i]->{"corrected"} = 0; }

		  }
		  elsif ( $lines[$i]->{"direction"} eq "vertical" ) {

			  my $dX = abs( $lines[$i]->{"x1"} - $lines[$i]->{"x2"} );

			  if ( $dX > 0 ) {

				  my $newX = sprintf( "%.4f", ( $lines[$i]->{"x1"} + $lines[$i]->{"x2"} ) / 2 );

				  $lines[$i]->{"x1"}        = $newX;
				  $lines[$i]->{"x2"}        = $newX;
				  $lines[$i]->{"corrected"} = 1;

				  $$changes = 1;
			  }
			  else { $lines[$i]->{"corrected"} = 0; }

		  }
		  else {
			  GeneralHelper->AddError( $errors, "Wrong score line. Score line id:" . $lines[$i]->{"id"} . " is diagonal" );
		  }
	  }
	  return @lines;
}

1;

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

	  #hybna oprava SCORE f14622, Nezkrati liny v o+1, pokud existuje o+1single f15590 . F16532, F16717 spatna oprava score u mpanelu

	  my $changes   = 0;
	  my %errors    = ( "errors" => undef, "warrings" => undef );
	  my $fFeatures = "o2.txt";

	  #my @scoreFeatures = ScoreOptimalizationHelper->GetFeatures($fFeatures);

	  #	my $frFeatures = ScoreFeatures->new();
	  #	$frFeatures->Parse($inCAM, $jobId, $etStep, "fr");
	  #
	  #	my @scoreFeatures = $frFeatures->GetFeatures();
	  #
	  #	my %profileLimts;
	  #
	  #	$profileLimts{'xmin'} = 0;
	  #	$profileLimts{'xmax'} = 310.189;
	  #	$profileLimts{'ymin'} = 0;
	  #	$profileLimts{'ymax'} = 299.99;
	  #
	  #	my $res =
	  #	  ScoreOptimalization->CheckProfileDistance( \@scoreFeatures, \%profileLimts, 4, \%errors );
	  #
	  #	@scoreFeatures =
	  #	  ScoreOptimalization->AdaptScoreToProfile( \@scoreFeatures, \%profileLimts, 4, \%errors );

	  print 1;

}

1;

