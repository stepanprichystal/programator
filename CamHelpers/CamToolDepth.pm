#-------------------------------------------------------------------------------------------#
# Description: Package contains helper function fworking with tool depth
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
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Function return max aspect ratio from all holes and their depths. For given layer
sub GetMaxAspectRatioByLayer {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;

	my $uniDTM = UniDTM->new( $inCAM, $jobId, $stepName, $layerName, 1 );

	# check if depths are ok
	my $mess = "";
	unless ( $uniDTM->GetChecks()->CheckToolDepthSet( \$mess ) ) {
		die $mess;
	}

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

	my @tools = $uniDTM->GetUniqueTools();
	for ( my $i = 0 ; $i < scalar(@tools) ; $i++ ) {

		my $t = $tools[$i];

		if ( $t->GetTypeProcess() ne EnumsDrill->TypeProc_HOLE ) {
			next;
		}

		#for each hole diameter, get depth (in mm)
		my $tDepth = $t->GetDepth();

		my $tmp = ( $t->GetDepth() * 1000 ) / $t->GetDrillSize();

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

	my $jobId     = "f52456";
	my $stepName  = "o+1";
	my $layerName = "fzc";

	my $ratio = CamToolDepth->GetMaxAspectRatioByLayer( $inCAM, $jobId, $stepName, $layerName );

	print STDERR $ratio;
}
1;
