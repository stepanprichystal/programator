
#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniDTM::UniDTM::UniDTMCheck;

#3th party library
use strict;
use warnings;

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';

use aliased 'Packages::CAM::UniDTM::Enums';
use aliased 'Enums::EnumsDrill';
use List::MoreUtils qw(uniq);

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"unitDTM"} = shift;

	return $self;
}

# Check if tools parameters are ok
# When some errors occure here, proper NC export is not possible
sub CheckTools {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	unless ( $self->__CheckUniqueTools($mess) ) {
		$result = 0;
	}

	unless ( $self->__CheckDrillSize($mess) ) {
		$result = 0;
	}

	return $result;
}

# Check is depth is correctly set in all tools
sub CheckToolDepthSet {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my @tools = @{ $self->{"unitDTM"}->{"tools"} };

	# Check if drillsize is defined
	my @noTools = grep { !$_->DepthIsOk() } @tools;

	foreach my $t (@noTools) {
		$result = 0;

		my $str = "NC layer: " . $self->{"unitDTM"}->{"layer"} . ". ";

		if ( $t->GetSource() eq Enums->Source_DTM ) {
			$str .= "Tool: " . $t->GetDrillSize() . " in DTM has wrong value of Depth column (depth is: \"" . $t->GetDepth() . "\").\n";
		}
		else {

			$str .=
			  "Surface id: \"" . $t->GetSurfaceId() . "\" has wrong value of \"tool_depth\" attribute (depth is: \"" . $t->GetDepth() . "\").\n";
		}

		$$mess .= $str;

	}

	return $result;
}

# Check is depth is is not set in tools
sub CheckToolDepthNotSet {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my @tools = @{ $self->{"unitDTM"}->{"tools"} };

	# Check if drillsize is defined
	my @depthTools = grep { $_->DepthIsOk() } @tools;

	foreach my $t (@depthTools) {
		$result = 0;

		my $str = "NC layer: " . $self->{"unitDTM"}->{"layer"} . ". ";

		if ( $t->GetSource() eq Enums->Source_DTM ) {
			$str .= "Tool: " . $t->GetDrillSize() . " in DTM has set \"depth\" column. This tool can't contain depth.\n";
		}
		else {

			$str .= "Surface id: \"" . $t->GetSurfaceId() . "\" has set \"tool_depth\" attribute. This tool can't contain depth.\n";
		}

		$$mess .= $str;

	}

	return $result;
}

# If tool is special, test if magazine info property is set properly
# and magazine code is find
sub CheckMagazine {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my @tools = @{ $self->{"unitDTM"}->{"tools"} };

	# 1) Check if drillsize is defined
	my @noMagCode =
	  grep { defined $_->GetMagazineInfo() && $_->GetMagazineInfo() ne "" && ( !defined $_->GetMagazine() || $_->GetMagazine() eq "" ) } @tools;

	foreach my $t (@noMagCode) {
		$result = 0;
		my $str = "NC layer: " . $self->{"unitDTM"}->{"layer"} . ". ";

		if ( $t->GetSource() eq Enums->Source_DTM ) {

			$str .= "Finding magazine for DTM special tool: ";
		}
		else {
			$str .= "Finding magazine for surface (id: \"" . $t->GetSurfaceId() . "\") special tool: ";
		}

		$str .=
		    $t->GetDrillSize()
		  . "�m was not succes. (magazine info: \""
		  . $t->GetMagazineInfo()
		  . "\", pcb material: \""
		  . $self->{"unitDTM"}->{"materialName"}
		  . "\").\n";
		$str .= "Check special tools definition file at y:\\server\\site_data\\scripts\\Config\\MagazineSpec.xml.\n";

		$$mess .= $str;
	}
	return $result;
}

# Check if some tools are same diameter as special tools and
# theses tools doesn't have magazine info
sub CheckSpecialTools {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my @tools = @{$self->{"unitDTM"}->{"tools"}};

	my @diametres  = map { $_->GetDrillSize() } @tools;
	my @specTool   = ();
	my @uniDTMTool = ();
	foreach my $k ( keys %{ $self->{"unitDTM"}->{"magazineSpec"}->{"tool"} } ) {

		my $tXml = $self->{"unitDTM"}->{"magazineSpec"}->{"tool"}->{$k};

		my @spec = grep { $_ / 1000 == $tXml->{"diameter"} } @diametres;
		if(scalar(@spec)){
			push( @specTool, "\"" . $k . "\"" );
			push( @uniDTMTool, ( $tXml->{"diameter"} * 1000 ) . "�m" );
		}


	}

	# get unique tools
	@specTool   = uniq(@specTool);
	@uniDTMTool = uniq(@uniDTMTool);

	if ( scalar(@specTool) ) {

		$result = 0;
		my $str  = join( "; ", @specTool );
		my $str2 = join( "; ", @uniDTMTool );
		$$mess .=
		    "Some standard tools ($str2), which are used have same diameter as special tools: $str."
		  . " You really don't want to use special tools? If so, fill \"magazine info\" parameter.\n";
	}

	return $result;
}

# Uniqu "key tool" is created from (drillSize + processType)
# Check if there are some differnet property when two tools ha same "key"
sub __CheckUniqueTools {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my @tools = @{ $self->{"unitDTM"}->{"tools"} };

	for ( my $i = 0 ; $i < scalar(@tools) ; $i++ ) {

		for ( my $j = $i ; $j < scalar(@tools) ; $j++ ) {

			my $ti = $tools[$i];
			my $tj = $tools[$j];

			# if tools equal, check if all attributes are same
			if ( $ti->GetDrillSize() == $tj->GetDrillSize() && $ti->GetTypeProcess() eq $tj->GetTypeProcess() ) {
				my $mStr = "NC layer: " . $self->{"unitDTM"}->{"layer"} . ". ";
				$mStr .= "Same  tools (" . $ti->GetDrillSize() . "�m, " . $ti->GetTypeProcess() . ") has different parameter \"%s\" ";
				$mStr .= "(";
				$mStr .=
				  $ti->GetSource() eq Enums->Source_DTM
				  ? "column value: \"%s\" in DTM "
				  : "attribnute value: \"%s\" in surface id: \"" . $ti->GetSurfaceId() . "\"";
				$mStr .= "is not equal to ";
				$mStr .=
				  $tj->GetSource() eq Enums->Source_DTM
				  ? "column value: \"%s\" in DTM "
				  : "attribute value: \"%s\" in surface ids: " . $tj->GetSurfaceId();
				$mStr .= ")";
				$mStr .= ".\n Set same value to parameter or move one tool to new NC layer.\n";

				if ( $tools[$i]->GetDepth() != $tools[$j]->GetDepth() ) {
					$result = 0;
					$$mess .= sprintf( $mStr, "depth", $tools[$i]->GetDepth(), $tools[$j]->GetDepth() );
				}

				if ( $tools[$i]->GetMagazineInfo() ne $tools[$j]->GetMagazineInfo() ) {
					$result = 0;
					$$mess .= sprintf( $mStr, "magazine info", $tools[$i]->GetMagazine(), $tools[$j]->GetMagazine() );
				}

				if ( $tools[$i]->GetTolPlus() ne $tools[$j]->GetTolPlus() ) {
					$result = 0;
					$$mess .= sprintf( $mStr, "tolerance+", $tools[$i]->GetTolPlus(), $tools[$j]->GetTolPlus() );
				}

				if ( $tools[$i]->GetTolMinus() ne $tools[$j]->GetTolMinus() ) {
					$result = 0;
					$$mess .= sprintf( $mStr, "tolerance-", $tools[$i]->GetTolMinus(), $tools[$j]->GetTolMinus() );
				}
			}
		}
	}

	return $result;
}

# Check if drill sizes of tools are set correctly
# When tool is type Source_DTMSURF check if drillSize == drillSize2
sub __CheckDrillSize {
	my $self = shift;
	my $mess = shift;

	my $result = 1;

	my @tools = @{ $self->{"unitDTM"}->{"tools"} };

	# 1) Check if drillsize is defined
	my @noTools = grep { !defined $_->GetDrillSize() || $_->GetDrillSize() eq "" || $_->GetDrillSize() == 0 } @tools;

	foreach my $t (@noTools) {
		$result = 0;
		my $str = "NC layer: " . $self->{"unitDTM"}->{"layer"} . ". ";

		if ( $t->GetSource() eq Enums->Source_DTM ) {
			$str .= "Tool: " . $t->GetFinishSize() . " in DTM has not set Drill size.\n";

		}
		else {

			$str .= "Surface: " . $t->GetSurfaceId() . " has not set attribute \".rout_tool\".\n";
		}

		$$mess .= $str;
	}

	# 2) Check if drillsize 2 == 0 or is equal to drill size 1 ( type Source_DTMSurf)
	my @toolsSurf = grep { $_->GetSource() eq Enums->Source_DTMSURF } @tools;
	my @wrongTool = grep { !defined $_->GetDrillSize2() || $_->GetDrillSize2() eq "" || $_->GetDrillSize() != $_->GetDrillSize2() } @toolsSurf;

	foreach my $t (@wrongTool) {
		$result = 0;
		$$mess .=
		    "NC layer: "
		  . $self->{"unitDTM"}->{"layer"}
		  . ". Attributes \".rout_tool\" and \".rout_tool2\" are not equal. Surface id: \""
		  . $t->GetSurfaceId() . "\".\n";
	}

	return $result;
}


 
#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::FeatureFilter::FeatureFilter';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

	my $f = FeatureFilter->new( $inCAM, "m" );

	$f->SetPolarity("positive");

	my @types = ( "surface", "pad" );
	$f->SetTypes( \@types );

	my @syms = ( "r500", "r1" );
	$f->AddIncludeSymbols( \[ "r500", "r1" ] );

	print $f->Select();

	print "fff";

}

1;

