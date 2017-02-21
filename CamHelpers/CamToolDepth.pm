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
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Enums::EnumsDrill';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";

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

	# 1) Get drill tool information  from DTM (slot and holes)
	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'layer',
				  entity_path     => "$jobId/$stepName/$layerName",
				  data_type       => 'TOOL',
				  options         => "break_sr"
	);

	my @gTOOLdrill_size = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
	my @gTOOLshape      = @{ $inCAM->{doinfo}{gTOOLshape} };

	my @arr = ();
	my $cnt = scalar(@gTOOLdrill_size);

	for ( my $i = 0 ; $i < $cnt ; $i++ ) {

		my %info = ();
		$info{"drill_size"} = $gTOOLdrill_size[$i];
		$info{"gTOOLshape"} = $gTOOLshape[$i];
		push( @arr, \%info );
	}

	#Add all user clmns to each tool
	my @userClmns = CamDTM->GetDTMUserColumns( $inCAM, $jobId, $stepName, $layerName, 1 );

	for ( my $i = 0 ; $i < scalar(@arr) ; $i++ ) {

		my %newInfo = ( %{ $arr[$i] }, %{ $userClmns[$i] } );
		push( @res, \%newInfo );
	}

	# 2) Add tool information from DTM surfaces
	# heach of all tools has to have same keys, convert them
	my @surfTools = CamDTMSurf->GetDTMTools( $inCAM, $jobId, $stepName, $layerName, 1 );

	foreach my $t (@surfTools) {

		my %tInfo = ();

		$tInfo{"drill_size"}                = $t->{".rout_tool"};
		$tInfo{ EnumsDrill->DTMclmn_DEPTH } = $t->{ EnumsDrill->DTMatt_DEPTH };
		$tInfo{"gTOOLshape"}                = "slot";

		push( @res, \%tInfo );
	}

	#	# 3) Check if there is no more chain tool with same diameter..
	#	my $mess = "";
	#	unless($self->CheckToolDepth($inCAM, $jobId, $stepName, $layerName, \$mess)){
	#
	#		die $mess;
	#	}

	return @res;
}

#sub CheckToolDepth {
#	my $self  = shift;
#	my $inCAM     = shift;
#	my $jobId     = shift;
#	my $stepName  = shift;
#	my $layerName = shift;
#	my $mess  = shift;
#
#
#	 my $result = 1;
#
#	my @tools = $self->GetToolDepths($inCAM, $jobId, $stepName, $layerName);
#
#	unless(CamDTMSurf->CheckDTM($inCAM, $jobId, $stepName, $layerName, 1, $mess)){
#		$result = 0;
#	}
#
#	# 1) check chains
#
#	my @chains = grep { $_->{"gTOOLshape"} eq "slot" } @tools;
#
#	for ( my $i = 0 ; $i < scalar(@chains) ; $i++ ) {
#
#		for ( my $j = $i ; $j < scalar(@chains) ; $j++ ) {
#
#			# if tools equal, check if all attributes are same
#			if ( $chains[$i]->{"drill_size"} == $chains[$j]->{"drill_size"} ) {
#
#				if ( $chains[$i]->{ EnumsDrill->DTMclmn_DEPTH } != $chains[$j]->{ EnumsDrill->DTMclmn_DEPTH } ) {
#					$result = 1;
#					$$mess .= "Same chain tool " . $chains[$i]->{"drill_size"} . " has different depth.";
#				}
#			}
#		}
#	}
#
#	# 2) check holes
#	my @holes = grep { $_->{"gTOOLshape"} eq "hole" } @tools;
#
#	for ( my $i = 0 ; $i < scalar(@holes) ; $i++ ) {
#
#		for ( my $j = $i ; $j < scalar(@holes) ; $j++ ) {
#
#			# if tools equal, check if all attributes are same
#			if ( $holes[$i]->{"drill_size"} == $holes[$j]->{"drill_size"} ) {
#
#				if ( $holes[$i]->{ EnumsDrill->DTMclmn_DEPTH } != $holes[$j]->{ EnumsDrill->DTMclmn_DEPTH } ) {
#					$result = 1;
#					$$mess .= "Same hole tool " . $holes[$i]->{"drill_size"} . " has different depth.";
#				}
#			}
#		}
#	}
#
#	return $result;
#
#}

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

		my $t  = $tools[$i];
	 
		if ( $t->GetTypeProcess() ne DTMEnums->TypeProc_HOLE ) {
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
