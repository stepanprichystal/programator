#-------------------------------------------------------------------------------------------#
# Description: Helper module for InCAM "Drill tool manager" for surfaces
# DTM for surafaces is not real, but it is effort do same thing for surface tools like
# for normal tool
# Author:SPR
#-------------------------------------------------------------------------------------------#
package CamHelpers::CamDTMSurf;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub CheckDTM {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;
	my $mess    = shift;

	my $result = 1;

	my @srfs = $self->__GetAllSurfaceTools( $inCAM, $jobId, $step, $layer, $breakSR );

	# 1) Check if attribute .rout_tool and .rout_tool2 has same tool

	my @noTools = grep { !defined $_->{".rout_tool"} || $_->{".rout_tool"} eq "" || $_->{".rout_tool"} == 0 } @srfs;

	if ( scalar(@noTools) ) {
		$result = 0;
		@noTools = map { $_->{"id"} } @noTools;

		$$mess .=
		    "Some surfaces have not set tool (attribute \".rout_tool\" and \".rout_tool2\" ). Surfaces with id: "
		  . join( ";", @noTools )
		  . ". Layer: $layer.\n";
	}

	# 2) Check if attribute .rout_tool and .rout_tool2 has same tool

	my @wrongTools = grep { defined $_->{".rout_tool"} && defined $_->{".rout_tool2"} && $_->{".rout_tool"} != $_->{".rout_tool2"} } @srfs;

	if ( scalar(@wrongTools) ) {
		$result = 0;
		@wrongTools = map { $_->{"id"} } @wrongTools;

		$$mess .=
		    "Some surfaces have wrong set tool. Attributes \".rout_tool\" and \".rout_tool2\" must be equal. Surfaces with id: "
		  . join( ";", @wrongTools )
		  . ". Layer: $layer.\n";

	}

	# 3) Check if for one tool diameter are all tool attributes equal
	for ( my $i = 0 ; $i < scalar(@srfs) ; $i++ ) {

		for ( my $j = $i ; $j < scalar(@srfs) ; $j++ ) {

			my $surfStr =
			    " for surface tool: "
			  . $srfs[$i]->{".rout_tool"}
			  . "µm. Surfaces id: \""
			  . $srfs[$i]->{"id"}
			  . "\" and \""
			  . $srfs[$j]->{"id"}
			  . "\" Layer: $layer.\n";

			# if tools equal, check if all attributes are same
			if ( $srfs[$i]->{".rout_tool"} == $srfs[$j]->{".rout_tool"} ) {

				if ( $srfs[$i]->{".rout_tool2"} != $srfs[$j]->{".rout_tool2"} ) {
					$result = 0;
					$$mess .= "Different attributes: \".rout_tool2\"" . $surfStr;

				}

				if ( $srfs[$i]->{ EnumsDrill->DTMatt_DEPTH } != $srfs[$j]->{ EnumsDrill->DTMatt_DEPTH } ) {
					$result = 0;
					$$mess .= "Different attributes: \"" . EnumsDrill->DTMatt_DEPTH . "\"" . $surfStr;

				}

				if ( $srfs[$i]->{ EnumsDrill->DTMatt_MAGAZINE } ne $srfs[$j]->{ EnumsDrill->DTMatt_MAGAZINE } ) {
					$result = 0;
					$$mess .= "Different attributes: \"" . EnumsDrill->DTMatt_MAGAZINE . "\"" . $surfStr;
				}

			}
		}
	}
	
	return $result;
}

# Return info about tool in DTM
# Result: array of hashes. Each has contain info about row in DTM
sub GetDTMTools {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	my $mess = "";
	unless ( $self->CheckDTM( $inCAM, $jobId, $step, $layer, $breakSR, \$mess ) ) {

		die "DTM sufrace tools are not set correctly: \n" . $mess;
	}

	# tools, some can be duplicated
	my @tools = $self->__GetAllSurfaceTools( $inCAM, $jobId, $step, $layer, $breakSR );

	# do distinst by .rout_tool attribute
	my %seen;
	@tools = grep { !$seen{ $_->{".rout_tool"} }++ } @tools;

	return @tools;
}

# Return for each surface, its tool attributes
sub __GetAllSurfaceTools {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	$breakSR = $breakSR ? "break_sr+" : "";

	my @surfaces = ();

	my $fFeatures = $inCAM->INFO(
								  units           => 'mm',
								  angle_direction => 'ccw',
								  entity_type     => 'layer',
								  entity_path     => "$jobId/$step/$layer",
								  data_type       => 'FEATURES',
								  options         => $breakSR . "feat_index+f0",
								  parse           => 'no'
	);

	my $f;
	open( $f, $fFeatures );

	while ( my $l = <$f> ) {

		if ( $l =~ /###/ ) { next; }

		if ( $l !~ /#(\d+)\s*#S/i ) { next; }    # we want olnly surfaces

		my $surfId = $1;

		$l =~ m/.*;(.*)/;

		unless ($1) {
			next;
		}

		my $depth    = EnumsDrill->DTMatt_DEPTH;
		my $magazine = EnumsDrill->DTMatt_MAGAZINE;

		# set defaul tool values
		my %tInfo = ( "id" => $surfId );
		$tInfo{".rout_tool"}  = 0;
		$tInfo{".rout_tool2"} = 0;
		$tInfo{$depth} =   0;
		$tInfo{$magazine} =   "";

		my @attr = split( ",", $1 );

		foreach my $at (@attr) {

			if ( $at =~ /\.rout_tool=\s*(.*)\s*/ ) {

				$tInfo{".rout_tool"} = $1;

				if ( $tInfo{".rout_tool"} ) {

					# TODO chzba incam,  je v inch misto mm
					$tInfo{".rout_tool"} = sprintf( "%.2f", $tInfo{".rout_tool"} * 25.4 );

					$tInfo{".rout_tool"} *= 1000;    # rout tool in µm
				}

			}
			elsif ( $at =~ /\.rout_tool2=\s*(.*)\s*/ ) {

				$tInfo{".rout_tool2"} = $1;

				if ( $tInfo{".rout_tool2"} ) {

					# TODO chzba incam,  je v inch misto mm
					$tInfo{".rout_tool2"} = sprintf( "%.2f", $tInfo{".rout_tool2"} * 25.4 );

					$tInfo{".rout_tool2"} *= 1000;    # rout tool in µm
				}

			}
			elsif ( $at =~ /\$depth=\s*(.*)\s*/ ) {

				$tInfo{$depth} = $1;

				# TODO chzba incam, hloubka je v inch misto mm
				if ( defined $tInfo{$depth} ) {

					$tInfo{$depth} = sprintf( "%.2f", $tInfo{$depth} * 25.4 );
				}

			}
			elsif ( $at =~ /\$magazine=\s*(.*)\s*/ ) {

				$tInfo{$magazine} = $1;

			}
		}

		push( @surfaces, \%tInfo );

	}

	return @surfaces;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamDTMSurf';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f52456";

	#my $step  = "mpanel_10up";

	my @result = CamDTMSurf->GetDTMTools( $inCAM, $jobId, "o+1", "f" );

	#my $self             = shift;

	print 1;

}

1;
