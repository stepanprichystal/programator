#-------------------------------------------------------------------------------------------#
# Description: Do checks of tool in Universal DTM
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::GuideSubs::Routing::Check1UpChain;

#3th party library
use utf8;
use strict;
use warnings;
use Math::Trig;
use Clone qw(clone);

#local library
use aliased 'Packages::CAM::UniRTM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';
use aliased 'CamHelpers::CamAttributes';

use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
 
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutRotation';
	use aliased 'Enums::EnumsGeneral';
	use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

# Check if there is outline layer, if all other layer (inner, right etc) are in this outline layer
sub OutsideChains {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @lefts = $unitRTM->GetOutlineChains();

	# If exist outline rout, check if other chains are inside
	if ( scalar(@lefts) ) {

		my @seq = $unitRTM->GetChainSequences();

		my %tmp;
		@tmp{ map { $_ } @lefts } = ();

		my @otherLayers = grep { !exists $tmp{$_} } @seq;

		my @notInside = grep { !$_->GetIsInside() } @otherLayers;

		if ( scalar(@notInside) ) {

			my @info = map { $_->GetStrInfo() } @notInside;
			my $str = join( "; ", @info );

			my @m = (
					  "Ve vrstvě: \"" . $layer . "\" jsou frézy, které by měly být uvnitř obrysové frézy, ale nejsou ($str).",
					  "Je to tak správně?"
			);
			my @b = ( "Ano", "Není, opravím to" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}

		}
	}

	return $result;
}

# Check if there is noly bridges rout
# if so, save this information to job attribute "rout_on_bridges"
sub OnlyBridges {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $messMngr = shift;

	my $result = 1;

	# reset attribut "rout_on_bridges" to NO, thus pcb is not on bridges
	CamAttributes->SetJobAttribute( $inCAM, $jobId, "rout_on_bridges", 0 );

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @outlines = $unitRTM->GetOutlineChains();

	my @chains = $unitRTM->GetChains();
	my @lefts = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } @chains;

	# If not exist outline rout, check if pcb is on bridges
	unless ( scalar(@outlines) ) {

		# no chains at layer
		unless (@chains) {

			my @m = ("Ve vrstvě není ani obrysová vrstva ani můstky. Je to tak správně?");
			my @b = ( "Ano", "Ne" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}

		}

		# maybe thera are bridges, but not LEFT
		elsif ( scalar(@lefts) == 0 ) {

			my @m = ("Ve vrstvě není ani obrysová vrstva ani můstky s kompenzací left. Pokud je pcb na můstky nastav jim kompenzaci left.");
			my @b = ( "Takhle je to správně", "Opravím můstky na LEFT" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}

		}

		# there are probably bridges with left comp
		else {

			my @m = ("Pravděpodobně je dps ponechaná na můstky, které mají kompenzaci left. Pokud to není pravda oprav frézu.");
			my @b = ( "Takhle je to správně", "Opravím frézu" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 0 ) {

				# set pcb is rout on bridges
				CamAttributes->SetJobAttribute( $inCAM, $jobId, "rout_on_bridges", 1 );

			}
			else {
				$result = 0;
			}
		}
	}

	return $result;
}

# Check when left rout exists
sub LeftRoutChecks {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $mess  = shift;

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	# 1) test if tehere are left no cyclic rout, which has foot down
	my @lefts   = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } $unitRTM->GetChains();
	my @leftSeq = map  { $_->GetChainSequences() } @lefts;
	@leftSeq = grep { !$_->GetCyclic() && $_->HasFootDown() } @leftSeq;

	if ( scalar(@leftSeq) ) {
		$result = 0;

		my @info = map { $_->GetStrInfo() } @leftSeq;
		my $str = join( "; ", @info );
		$$mess .= "Ve vrstvě: \"" . $layer . "\" jsou frézy s kompenzací left, které nejsou obrysové a mají patku. " . $str;
	}

	# 2) Test if outline orut has only one attribute "foot_down_<angle>deg" of specific kind
	my @outlines = $unitRTM->GetOutlineChains();

	foreach my $o (@outlines) {

		foreach my $oSeq ( $o->GetChainSequences() ) {

			my @foot_down_0deg = grep { defined $_->{"att"}->{"foot_down_0deg"} } $oSeq->GetFeatures();

			if ( scalar(@foot_down_0deg) > 1 ) {
				$result = 0;
				$$mess .=
				  "Ve vrstvě: \"" . $layer . "\" je fréza: " . $oSeq->GetStrInfo() . ", která má více atributů \"foot_down_0deg\". Oprav to.\n";
			}

			my @foot_down_270deg = grep { defined $_->{"att"}->{"foot_down_270deg"} } $oSeq->GetFeatures();

			if ( scalar(@foot_down_270deg) > 1 ) {
				$result = 0;
				$$mess .=
				    "Ve vrstvě: \""
				  . $layer
				  . "\" je fréza: "
				  . $oSeq->GetStrInfo()
				  . ", která má více atributů \"foot_down_270deg\". Oprav to.\n";
			}
		}
	}

	# 3) Outline rout. Test if one feature doesn\t have more attributes "foot_down" eg: foot_down_0deg + foot_down_90deg

	foreach my $o (@outlines) {

		foreach my $oSeq ( $o->GetChainSequences() ) {

			my @wrongAtt = grep { defined $_->{"att"}->{"foot_down_0deg"} && defined $_->{"att"}->{"foot_down_270deg"} } $oSeq->GetFeatures();

			if ( scalar(@wrongAtt) > 1 ) {

				my @ids = map { $_->{"id"} } @wrongAtt;
				my $str = join( ";", @ids );

				$result = 0;
				$$mess .=
				    "Ve vrstvě: \""
				  . $layer
				  . "\" jsou \"features\", ktereé mají zároveň atribut \"foot_down_0deg\" i \"foot_down_270deg\". Oprav to.\n";
			}
		}
	}
}

sub TestFindStart {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $layer       = shift;
	my $rotateAngle = shift;    # if foot down is tested on rotated pcb. Rotation is CCW
	my $messMngr    = shift;

	my %result = ( "result" => 1, "startEdge" => undef );

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @lefts = $unitRTM->GetOutlineChains();
	my @res   = ();

	foreach my $left (@lefts) {

		my %result = $self->TestFindStartSingle( $inCAM, $jobId, $step, $layer, $rotateAngle, $left, $messMngr );
		push( @res, \%result );
	}

	return @res;
}

sub TestFindStartSingle {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $layer       = shift;
	my $rotateAngle = shift;    # if foot down is tested on rotated pcb. Rotation is CCW
	my $left        = shift;
	my $messMngr    = shift;

	my %result = ( "result" => 1, "startEdge" => undef, "angle" => $rotateAngle );

	my @features = $left->GetFeatures();

	my $rotation = RoutRotation->new( \@features );    # class responsible for rout rotaion

	# if foot down is tested on rotated pcb
	if ( $rotateAngle > 0 ) {

		$rotation->Rotate($rotateAngle);
	}

	my %modify = RoutStart->RoutNeedModify( \@features );

	my $routModify = 0;

	if ( $modify{"result"} ) {                         # tadz p5idat test na to jestli bzla seqence kodifikovana pri nacitani

		$routModify = 1;

		RoutStart->ProcessModify( \%modify, \@features );
	}

	my %startResult = RoutStart->GetRoutStart( \@features );
	my %footResult  = RoutStart->GetRoutFootDown( \@features );

	# if foot down is tested on rotated pcb, rotate back before drawing
	if ( $rotateAngle > 0 ) {
		$rotation->RotateBack();
	}

	unless ( $startResult{"result"} ) {

		my @m = ( "Začátek frézy pro dps : " . $left->GetStrInfo() . " při rotaci dps: $rotateAngle° nebyl nalezen" );

		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m );    #  Script se zastavi
		$result{"result"} = 0;
	}
	else {

		if ( $routModify || $left->GetModified() ) {

			# překreslit frézu
			my $draw = RoutDrawing->new( $inCAM, $jobId, $step, $layer );

			my @delete = grep { $_->{"id"} > 0 } @features;

			$draw->DeleteRoute( \@delete );

			$draw->DrawRoute( \@features, 2000, EnumsRout->Comp_LEFT, $startResult{"edge"} );    # draw new

			# Show information message
			my @m = (
					  "Fréza byla upravena, aby byly nalezeni vhodní kandidáti na patku (při rotaci dps: $rotateAngle°)",
					  "Fréza: " . $left->GetStrInfo()
			);

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m );                  #  Script se zastavi
		}

		my $startCopy = clone( $footResult{"edge"} );
		$result{"startEdge"} = $startCopy;
	}

	return %result;
}

sub TestFindAndDrawStarts {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $step     = shift;
	my $layer    = shift;
	my $angle0   = shift;    # if foot down is tested on rotated pcb. Rotation is CCW
	my $angle270 = shift;    # if foot down is tested on rotated pcb. Rotation is CCW
	my $messMngr = shift;

	my @foots = ();

	if ($angle270) {
		my @res = $self->TestFindStart( $inCAM, $jobId, $step, $layer, 270, $messMngr );
		push( @foots, @res );
	}

	if ($angle0) {
		my @res = $self->TestFindStart( $inCAM, $jobId, $step, $layer, 0, $messMngr );
		push( @foots, @res );
	}



	# Draw foots

	my $lName = "footdown_" . $jobId;

	if ( CamHelper->LayerExists( $inCAM, $jobId, $lName ) ) {
		$inCAM->COM( "delete_layer", "layer" => $lName );
	}

	$inCAM->COM( 'create_layer', layer => $lName, context => 'misc', type => 'document', polarity => 'positive', ins_layer => '' );

	my $drawView = RoutDrawing->new( $inCAM, $jobId, $step, $lName );

	$drawView->DrawStartRoutResult( \@foots );

	$inCAM->COM(
				 "display_layer",
				 name    => $layer,
				 display => "yes",
				 number  => 2
	);

	$inCAM->COM( "work_layer", name => $layer );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::GuideSubs::Routing::Check1UpChain';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Managers::MessageMngr::MessageMngr';

	use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';

	my $messMngr = MessageMngr->new("D3333");

	my $inCAM = InCAM->new();

	my $jobId = "d99992";
	my $step  = "o";

	# Get work layer
	$inCAM->COM('get_work_layer');

	my $layer = "$inCAM->{COMANS}";    # layer where rout is original rout

	my $mess = "";

	my $res = Check1UpChain->TestFindAndDrawStarts($inCAM, $jobId, $step, $layer, 1, 1, $messMngr );

	#my $res = Check1UpChain->OnlyBridges( $inCAM, $jobId, $step, $layer, $messMngr );

}

1;

