#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::UniRTM::UniRTM::Parser::ChainToolParser;

#3th party library
use strict;
use warnings;
use List::MoreUtils qw(uniq);

#local library
use aliased 'CamHelpers::CamDTM';
use aliased 'CamHelpers::CamDTMSurf';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniChainSeq';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniChain';
use aliased 'Packages::CAM::UniRTM::Enums';
use aliased 'Enums::EnumsDrill';
use aliased 'Enums::EnumsRout';
use aliased 'Packages::CAM::UniDTM::Enums' => "DTMEnums";
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutCyclic';
use aliased 'Packages::CAM::UniRTM::UniRTM::UniChainTool';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Return array of unique route chain hashes
# Each info contain at least:
# "tool_size" = tool size
# ".route_chain" = number of chain (unique)
sub GetChainList {
	my $self     = shift;
	my @features = @{ shift(@_) };
	my $uniDTM   = shift;

	my @chainList = ();

	foreach my $f (@features) {

		# if no attributes
		unless ( $f->{"att"} ) {
			next;
		}

		my %attr = %{ $f->{"att"} };

		# if features contain attribute rout chain
		if ( $attr{".rout_chain"} && $attr{".rout_chain"} > 0 ) {

			# test, if chain with given routchain not exist exist, add it
			unless ( scalar( grep { $_->GetChainOrder() eq $attr{".rout_chain"} } @chainList ) ) {

				my $chainOrder = $attr{".rout_chain"};
				my $chainTool  = undef;
				my $chainComp  = undef;

				# if it is no surfaces
				if ( $f->{"type"} !~ /s/i ) {

					$chainTool = $f->{"thick"};     # add ifnp about rout tool size
					$chainComp = $attr{".comp"};    # add ifnp about rout tool size

				}
				else {

					#value is returned in inch so treanslate to mm TODO chzba incam
					if ( $attr{".rout_tool"} ) {
						$chainTool = sprintf( "%.1f", $attr{".rout_tool"} * 25.4 ) * 1000;    # add ifnp about rout tool size
					}

					if ( $attr{".comp"} eq "left" ) {
						$chainComp = EnumsRout->Comp_CCW;
					}
					else {
						$chainComp = EnumsRout->Comp_CW;
					}
				}

				my $dtmTool = undef;

				# id defined DTM, assign UniDTM tools to UniChainTool
				if ($uniDTM) {
					$dtmTool = $uniDTM->GetTool( $chainTool, DTMEnums->TypeProc_CHAIN );
				}

				my $uniChainTool = UniChainTool->new( $chainOrder, $chainTool, $chainComp, $dtmTool );

				push( @chainList, $uniChainTool );
			}

		}

	}

	@chainList = sort { $a->GetChainOrder() <=> $b->GetChainOrder() } @chainList;
 
	return @chainList;

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

 

	  my @syms = ( "r500", "r1" );
	  $f->AddIncludeSymbols( \[ "r500", "r1" ] );

	  print $f->Select();

	  print "fff";

}

1;

