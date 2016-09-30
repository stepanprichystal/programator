#-------------------------------------------------------------------------------------------#
# Description: Package contains helper function for getting, computing tool depth
# Author:SPR
#-------------------------------------------------------------------------------------------#
package CamHelpers::CamToolDepth;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#return formated depth for given size
sub PrepareToolDepth {
	my $self       = shift;
	my $toolSize   = shift;
	my @toolDepths = @{ shift(@_) };
	my $toolDepth  = shift;

	my $toolIdx;
	$toolIdx = ( grep { $toolDepths[$_]->{"drill_size"} == $toolSize } 0 .. $#toolDepths )[0];

	if ( defined $toolIdx ) {

		unless ( $toolDepths[$toolIdx]->{"depth"} ) {
			return 0;
		}

		my $tmp = $toolDepths[$toolIdx]->{"depth"};
		$tmp =~ s/,/\./;
		$tmp = sprintf( "%.2f", $tmp );

		# depth is in mm, so assume range > 0 and  < 10 mm

		if ( $tmp <= 0 || $tmp >= 10 || $tmp eq "" ) {
			return 0;
		}

		$$toolDepth = $tmp;
	}

	return 1;

}

#Return tools from Drill tool manager with
# - all user columns
# - and finish size columns
sub GetToolDepths {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	#	print STDERR $jobId. "\n";
	#	print $step. "\n";
	#	print $layer. "\n";

	my @res = ();

	#get drill tool information
	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'layer',
				  entity_path     => "$jobId/$stepName/$layerName",
				  data_type       => 'TOOL',
				  options         => "break_sr"
	);

	my @gTOOLdrill_size = @{ $inCAM->{doinfo}{gTOOLdrill_size} };

	my @arr = ();
	my $cnt = scalar(@gTOOLdrill_size);

	for ( my $i = 0 ; $i < $cnt ; $i++ ) {

		my %info = ();
		$info{"drill_size"} = $gTOOLdrill_size[$i];
		push( @arr, \%info );
	}

	#Add all user clmns to each tool
	my @userClmns = CamDTM->GetDTMUserColumns( $inCAM, $jobId, $stepName, $layerName );

	for ( my $i = 0 ; $i < scalar(@arr) ; $i++ ) {

		my %newInfo = ( %{ $arr[$i] }, %{ $userClmns[$i] } );
		push( @res, \%newInfo );
	}

	return @res;
}

# Function return max aspect ratio from all holes and their depths. For given layer
sub GetMaxAspectRatioByLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	#get depths for all diameter
	my @toolDepths = $self->GetToolDepths( $inCAM, $jobId, "panel", $layerName );

	$inCAM->INFO(
				  units       => 'mm',
				  entity_type => 'layer',
				  entity_path => "$jobId/$stepName/$layerName",
				  data_type   => 'TOOL',
				  parameters  => 'drill_size+shape',
				  options     => "break_sr"
	);
	my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

	my $aspectRatio;

	for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

		my $tSize = $toolSize[$i];
		my $s     = $toolShape[$i];

		if ( $s ne 'hole' ) {
			next;
		}

		#for each hole diameter, get depth (in mm)
		my $tDepth;

		my $prepareOk = $self->PrepareToolDepth( $tSize, \@toolDepths, \$tDepth );
		unless ($prepareOk) {
			next;
		}

		my $tmp = ( $tDepth * 1000 ) / $tSize;

		if ( !defined $aspectRatio || $tmp > $aspectRatio ) {

			$aspectRatio = $tmp;
		}

	}
	return $aspectRatio;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamToolDepth';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId     = "f49756";
	my $stepName  = "o+1";
	my $layerName = "fzs";

	my @depth = CamToolDepth->GetToolDepths( $inCAM, $jobId, $stepName, $layerName );

}
1;
