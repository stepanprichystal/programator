#-------------------------------------------------------------------------------------------#
# Description: Checking rout layer - tools,  during processing pcb
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Routing::Check1UpChainTool;

#3th party library
use utf8;
use strict;
use warnings;
use Math::Trig;

#local library
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamAttributes';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#
# Check if tool sizes are sorted ASC
sub ToolsAreOrdered {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );
	my @chains = $unitRTM->GetChainListByOutline(0);

	my @wrongSorted = ();

	# reset attribut "rout_tool_spec_order" to NO, assume tools are sorted ASC
	CamAttributes->SetJobAttribute( $inCAM, $jobId, "rout_tool_spec_order", 0 );

	for ( my $i = 0 ; $i < scalar(@chains) ; $i++ ) {

		if ( $i == 0 ) {
			next;
		}

		if ( $chains[$i]->GetChainSize() < $chains[ $i - 1 ]->GetChainSize() ) {
			my $str =
			    "Tool: \""
			  . $chains[$i]->GetChainSize()
			  . "µm\" (chain: \""
			  . $chains[$i]->GetChainOrder()
			  . "\") is placed after larger tool: \""
			  . $chains[ $i - 1 ]->GetChainSize()
			  . "µm\" (chain: \""
			  . $chains[ $i - 1 ]->GetChainOrder() . "\")\n";
			push( @wrongSorted, $str );
			$result = 0;
		}

	}

	unless ($result) {

		my $str = join( "", @wrongSorted );

		my @m =
		  ( "Ve vrstvě: \"" . $layer . "\" jsou špatně seřazené nástroje pro frézování:\n $str", " Je tohle pořadí frézování záměrné?" );
		my @b = ( "Ano je to záměr", "Není, opravím to" );
		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
		if ( $messMngr->Result() == 0 ) {
			$result = 1;
			CamAttributes->SetJobAttribute( $inCAM, $jobId, "rout_tool_spec_order", 1 );
		}
		else {
			$result = 0;

		}

	}

	return $result;
}

# Check if tool sizes are sorted ASC
sub OutlineToolIsLast {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $mess  = shift;

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );
	my @chains = $unitRTM->GetChains();

	my @outlines = $unitRTM->GetOutlineChains();

	unless ( scalar(@outlines) ) {
		return $result;
	}

	my $outlineStart = 0;
	foreach my $ch (@chains) {

		foreach my $chSeq ( $ch->GetChainSequences() ) {

			if ( $chSeq->IsOutline() && !$outlineStart ) {
 				
 				$outlineStart = 1; 
				next;
			}

			# if first outline was passed, all chain after has to be outline
			if ($outlineStart) {
				unless ( $chSeq->IsOutline() ) {
					$result = 0;

					$$mess .=
					    "Ve vrstvě: \""
					  . $layer
					  . "\" jsou špatně seřazené frézy. Fréza ". $chSeq->GetStrInfo() ." nesmí být za obrysovými frézami. Oprav to.\n"; 
				}
			}
		}
	}
	
	return $result;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Routing::Check1UpChainTool';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';
	use aliased 'Enums::EnumsGeneral';

	my $messMngr = MessageMngr->new("D3333");

	my $inCAM = InCAM->new();

	my $jobId = "d206764";
	my $step  = "o+1";
	my $layer = "f";

	my $mess = "";

	#my $res = Check1UpChainTool->ToolsAreOrdered( $inCAM, $jobId, $step, $layer, $messMngr );
	
	my $res = Check1UpChainTool->OutlineToolIsLast( $inCAM, $jobId, $step, $layer, \$mess );

	print $mess;

	print STDERR "\nReult is $res \n";

}

1;

