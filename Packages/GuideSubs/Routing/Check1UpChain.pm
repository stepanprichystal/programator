#-------------------------------------------------------------------------------------------#
# Description: Checking rout layer during processing pcb
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
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Enums::EnumsRout';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Packages::Routing::RoutOutline';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::Routing::RoutLayer::RoutDrawing::RoutDrawing';
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStart';
use aliased 'Packages::Routing::RoutLayer::RoutParser::RoutCyclic';
use aliased 'Packages::Routing::RoutLayer::RoutStart::RoutStartAdjust';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamLayer';

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

	my @outlines = $unitRTM->GetOutlineChainSeqs();

	# If exist outline rout, check if other chains are inside
	if ( scalar(@outlines) ) {

		my @seq = $unitRTM->GetChainSequences();

		my %tmp;
		@tmp{ map { $_ } @outlines } = ();

		my @otherLayers = grep { !exists $tmp{$_} } @seq;

		my @notInside = grep { !$_->GetIsInside() } @otherLayers;

		if ( scalar(@notInside) ) {

			my @info = map { $_->GetStrInfo() } @notInside;
			my $str = join( "; ", @info );

			my @m = (
				"Ve vrstv??: \""
				  . $layer
				  . "\" jsou fr??zy, kter?? by m??ly b??t uvnit?? obrysov?? fr??zy, ale nejsou ($str). Pravd??podobn?? krom?? desek na patku jsou ve stepu i dps na m??stky",
				"Je to pravda?"
			);
			my @b =
			  ( "Ano, step obsahuje i dps na m??stky", "Ne neobsahuje, oprav??m to", "Ne neobsahuje, ale obsahuje pomocnou fr??zu za obrysem dps" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi

			if ( $messMngr->Result() == 0 ) {

				# set pcb is rout on bridges
				CamAttributes->SetStepAttribute( $inCAM, $jobId, $step, "rout_on_bridges", "yes" );

			}
			elsif ( $messMngr->Result() == 1 ) {
				$result = 0;
			}
			elsif ( $messMngr->Result() == 0 ) {

			}

		}
	}

	return $result;
}

# Check if there is only bridges rout
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
	CamAttributes->SetStepAttribute( $inCAM, $jobId, $step, "rout_on_bridges", "no" );

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @outlines = $unitRTM->GetOutlineChainSeqs();

	# If not exist outline rout, check if pcb is on bridges
	unless ( scalar(@outlines) ) {

		my @chains = $unitRTM->GetChains();
		my @lefts  = grep { $_->GetComp() eq EnumsRout->Comp_LEFT } @chains;
		my @none   = grep { $_->GetComp() eq EnumsRout->Comp_NONE } @chains;

		# no chains at layer
		if ( scalar(@chains) == 0 ) {

			my @m = ("Ve vrstv?? neobsahuje ????dnou fr??zu. Je to tak spr??vn???");
			my @b = ( "Ano vrstva je pr??zdn??, ", "Fr??za je ??patn??, oprav??m ji" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}

		}
		elsif ( scalar(@lefts) == 0 ) {

			my @m = ("Ve vrstv?? nen?? obrysov?? fr??za. Obsahuje vrstva pouze vnit??n?? v????ezy?");
			my @b = ( "Ano, vrstva obsahuje pouze vnit??n?? v????ezy", "Ne, dps obsahuje obrysovou fr??zu, oprav??m to", "Ne, dps je na m??stky" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi

			if ( $messMngr->Result() == 1 ) {
				$result = 0;
			}
			elsif ( $messMngr->Result() == 2 ) {

				# maybe thera are bridges, but not LEFT
				if ( scalar(@lefts) == 0 && scalar(@none) == 0 ) {

					my @m = ("Ve vrstv?? nejsou  m??stky s kompenzac?? left ani none. Pokud je to mo??n?? nastav m??stk??m kompenzaci \"left\".");
					my @b = ("Oprav??m m??stky na \"left\" nebo \"none\"");
					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
					if ( $messMngr->Result() == 0 ) {
						$result = 0;
					}

				}

				# there are probably bridges with left comp
				elsif ( scalar(@lefts) == 0 && scalar(@none) ) {

					my @m = ("Pravd??podobn?? je dps ponechan?? na m??stky, kter?? maj?? kompenzaci \"none\". Je to tak?");
					my @b = ( "Ano, dps je na m??stky s kompenzac?? \"none\"", "Ne, dps oprav??m na m??stky s kompenzac?? \"left\"" );
					$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
					if ( $messMngr->Result() == 0 ) {

						# set pcb is rout on bridges
						CamAttributes->SetStepAttribute( $inCAM, $jobId, $step, "rout_on_bridges", "yes" );
					}
					else {
						$result = 0;
					}
				}

			}

		}
		elsif ( scalar(@lefts) ) {
			my @m = ("Pravd??podobn?? je dps ponechan?? na m??stky, kter?? maj?? kompenzaci \"left\". Je to tak?");
			my @b = ( "Ano, dps je na m??stky s kompenzac?? \"left\"", "Ne, vrstva by m??la obsahovat obrysovou fr??zu, oprav??m to" );
			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m, \@b );    #  Script se zastavi
			if ( $messMngr->Result() == 0 ) {

				# set pcb is rout on bridges
				CamAttributes->SetStepAttribute( $inCAM, $jobId, $step, "rout_on_bridges", "yes" );

			}
			else {
				$result = 0;
			}
		}

	}

	return $result;
}

# Check when left rout exists
sub OutlinePoolRoutChecks {
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
	@leftSeq = grep { $_->HasFootDown() } @leftSeq;

	if ( scalar(@leftSeq) ) {

		$result = 0;

		my @info = map { $_->GetStrInfo() } @leftSeq;
		my $str = join( "; ", @info );
		my $m =
		    "Ve stepu: \""
		  . $step
		  . "\", ve vrstv??: \"$layer\" jsou fr??zy s kompenzac???? left, kter?? maj???? nastavenou patku (.foot_down attribut) ($str)";

		$$mess .= $m;

	}

	return $result;
}

# Check when left rout exists
sub OutlineRoutChecks {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;
	my $mess  = shift;

	my $result = 1;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	# 2) Test if outline orut has only one attribute "foot_down_<angle>deg" of specific kind
	my @outlines = $unitRTM->GetOutlineChainSeqs();

	foreach my $oSeq (@outlines) {

		my $m = "";

		my @rotation = [ 0, 90, 180, 270 ];
		foreach my $angle (@rotation) {

			my @foot_down_att = grep { defined $_->{"att"}->{"foot_down_${angle}deg"} } $oSeq->GetFeatures();

			if ( scalar(@foot_down_att) > 1 ) {

				$result = 0;

				my $m =
				    "Ve stepu: \""
				  . $step
				  . "\", ve vrstv??: \"$layer\" je v??ce \"features\": "
				  . $oSeq->GetStrInfo()
				  . ", kter?? maj?? attribut: \"foot_down_${$angle}deg\". Oprav to.\n";

				$$mess .= $m;
			}
		}
	}

	# 3) Outline rout. Test if one feature doesn\t have more attributes "foot_down" eg: foot_down_0deg + foot_down_90deg + ...

	foreach my $oSeq (@outlines) {

		foreach my $f ( $oSeq->GetFeatures() ) {

			my @wrongFeats = grep { $_ =~ /foot_down_/i } keys %{ $f->{"att"} };

			if ( scalar(@wrongFeats) > 1 ) {

				$result = 0;
				my $m =
				    "Ve stepu: \""
				  . $step
				  . "\", ve vrstv??: \"$layer\" je \"feature\" ("
				  . $f->{"id"}
				  . "), kter?? m?? v??ce atribut?? \"foot_down_<uhel>deg\" s r??zn??m ??hlem, "
				  . "kter?? ozna??uj?? m??sto patky pro konkr??tn?? rotaci kusu na panelu. Oprav to.\n";

				$$mess .= $m;
			}
		}
	}

	# 4) If some chain tool containo utline, all another chain must by outline
	my @chains = $unitRTM->GetChains();

	foreach my $ch (@chains) {

		my @outline = grep { $_->IsOutline() } $ch->GetChainSequences();

		if ( scalar(@outline) && scalar(@outline) != scalar( $ch->GetChainSequences() ) ) {

			$result = 0;

			my $m =
			    "Ve stepu: \""
			  . $step
			  . "\", ve vrstv??: \"$layer\" jsou jedn????m n??strojem: \""
			  . $ch->GetStrInfo
			  . "\" definov??ny orbysov?? i neobrysov?? fr??zy dohromady - nelze. "
			  . " Ka??d?? obrysov?? fr??za mus?? m??t sv??j vlastn?? \"chain\".\n";

			$$mess .= $m;
		}

	}

	# 5) Each outline rout must have own chain tool
	foreach my $ch (@chains) {

		my @outline = grep { $_->IsOutline() } $ch->GetChainSequences();

		if ( scalar(@outline) > 1 ) {

			my $m =
			    "Ve stepu: \""
			  . $step
			  . "\", ve vrstv??: \"$layer\" je jedn????m n??strojem: \""
			  . $ch->GetStrInfo
			  . "\" definov??no v??ce obrysov??ch vrstev fr??zy dohromady - nelze. "
			  . " Ka??d?? obrysov?? fr??za mus?? m??t sv??j vlastn?? \"chain\".\n";

			$$mess .= $m;
		}

	}

	return $result;
}

sub TestFindStart {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $step        = shift;
	my $layer       = shift;
	my $rotateAngle = shift;    # if foot down is tested on rotated pcb. Rotation is CCW
	my $messMngr    = shift;

	my $unitRTM = UniRTM->new( $inCAM, $jobId, $step, $layer );

	my @lefts = $unitRTM->GetOutlineChainSeqs();
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

	my %result = ( "result" => 1, "footEdge" => undef, "angle" => $rotateAngle, "outlInfo" => $left->GetStrInfo() );

	my @features = $left->GetFeatures();

	my $rotation = RoutStartAdjust->new( \@features );    # class responsible for rout rotaion

	my $startByAtt    = 0;
	my $startByScript = 0;
	my $footDownEdge  = undef;

	# 1) Find start of chain by user foot down attribute
	my $attFootName = undef;
	if ( $rotateAngle >= 0 ) {
		$attFootName = "foot_down_" . $rotateAngle . "deg";
	}

	if ( defined $attFootName ) {

		my $edge = ( grep { $_->{"att"}->{$attFootName} } @features )[0];

		if ( defined $edge ) {

			$startByAtt   = 1;
			$footDownEdge = $edge;
		}
	}

	# 2) Find start of chain by script, if is not already found
	if ( !$startByAtt ) {

		$rotation->Transform( RoutOutline->GetDefRoutStart($jobId), $rotateAngle );

		my %modify = RoutStart->RoutNeedModify( \@features );

		my $routModify = 0;

		if ( $modify{"result"} ) {    # tadz p5idat test na to jestli bzla seqence kodifikovana pri nacitani

			$routModify = 1;
			RoutStart->ProcessModify( \%modify, \@features );
		}

		my %startResult = RoutStart->GetRoutStart( \@features );
		my %footResult  = RoutStart->GetRoutFootDown( \@features );

		# if foot down is tested on rotated pcb, rotate back before drawing
		$rotation->TransformBack();

		if ( $startResult{"result"} ) {

			$startByScript = 1;
			$footDownEdge  = $footResult{"edge"};

			if ( $routModify || $left->GetModified() ) {

				# p??ekreslit fr??zu
				my $draw = RoutDrawing->new( $inCAM, $jobId, $step, $layer );

				my @delete = grep { $_->{"id"} > 0 } @features;

				$draw->DeleteRoute( \@delete );

				$draw->DrawRoute( \@features, 2000, EnumsRout->Comp_LEFT, $startResult{"edge"} );    # draw new
			}
		}
	}

	if ( $startByAtt || $startByScript ) {

		my $startCopy = clone($footDownEdge);
		$result{"footEdge"} = $startCopy;
	}
	else {
		$result{"result"} = 0;
	}

	#	else {
	#		my @m = ( "Za????tek fr??zy pro dps : " . $left->GetStrInfo() . " p??i rotaci dps: $rotateAngle?? nebyl nalezen" );
	#
	#		$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m );    #  Script se zastavi
	#		$result{"result"} = 0;
	#	}

	return %result;
}

sub TestFindAndDrawStarts {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $step      = shift;
	my $layer     = shift;
	my $angle0    = shift;         # if foot down is tested on rotated pcb. Rotation is CCW
	my $angle90   = shift;         # if foot down is tested on rotated pcb. Rotation is CCW
	my $angle180  = shift;         # if foot down is tested on rotated pcb. Rotation is CCW
	my $angle270  = shift;         # if foot down is tested on rotated pcb. Rotation is CCW
	my $mandatory = shift // 0;    # if 1, it means, all required footdown must by solved
	my $messMngr = shift;

	my @footResults = ();

	if ($angle0) {
		my @res = $self->TestFindStart( $inCAM, $jobId, $step, $layer, 0, $messMngr );
		push( @footResults, @res );
	}

	if ($angle90) {
		my @res = $self->TestFindStart( $inCAM, $jobId, $step, $layer, 90, $messMngr );
		push( @footResults, @res );
	}

	if ($angle180) {
		my @res = $self->TestFindStart( $inCAM, $jobId, $step, $layer, 180, $messMngr );
		push( @footResults, @res );
	}

	if ($angle270) {
		my @res = $self->TestFindStart( $inCAM, $jobId, $step, $layer, 270, $messMngr );
		push( @footResults, @res );
	}

	# Draw foots
	if ( scalar(@footResults) ) {

		# a) Draw founds foot down
		my $lFootRes = "footdown_" . $jobId;
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lFootRes );
		CamMatrix->CreateLayer( $inCAM, $jobId, $lFootRes, "document", "positive", 0 );
		my $drawFoorRes = RoutDrawing->new( $inCAM, $jobId, $step, $lFootRes );
		$drawFoorRes->DrawFootRoutResult( \@footResults, 1, 1 );

		# b) # Draw helper scheme which clarify where should be placed woot downs

		my $drawFootSch = RoutDrawing->new( $inCAM, $jobId, $step, $lFootRes );

		my @foots = ();
		push( @foots, 0 )   if ($angle0);
		push( @foots, 90 )  if ($angle90);
		push( @foots, 180 ) if ($angle180);
		push( @foots, 270 ) if ($angle270);

		my $defDir   = RoutOutline->GetDefRoutDirection($jobId);
		my $defStart = RoutOutline->GetDefRoutStart($jobId);

		$drawFootSch->DrawFootScheme( \@foots, $defDir, $defStart );

		$inCAM->COM(
					 "display_layer",
					 name    => $layer,
					 display => "yes",
					 number  => 2
		);

		$inCAM->COM( "work_layer", name => $layer );
		$inCAM->COM("zoom_home");

		# Show error, if find footdown fail and footdwon are mandatory

		#		$result{"result"} = 0;

		my @notFound = grep { !$_->{"result"} } @footResults;

		if ( scalar(@notFound) && $mandatory ) {

			my @m = ();
			foreach my $notFound (@notFound) {
				push( @m,
					  "Za????tek fr??zy pro dps : " . $notFound->{"outlInfo"} . " p??i rotaci dps: " . $notFound->{"angle"} . "?? nebyl nalezen." );
				push( @m, "Nastav patku p??es atribut: \"foot_down_" . $notFound->{"angle"} . "deg\"\n" );
			}

			$messMngr->ShowModal( -1, EnumsGeneral->MessageType_WARNING, \@m );    #  Script se zastavi

		}

		$inCAM->PAUSE("Zkontroluj popripade uprav navrzene patky, ktere se pouziji pri tvorbe vrstvy FSCH...");
		
		CamLayer->WorkLayer( $inCAM,$layer );
		CamMatrix->DeleteLayer( $inCAM, $jobId, $lFootRes );
		
	}

	# Show info, if foot down was not found
	my $notFound = scalar( grep { !$_->{"result"} } @footResults );

	if ($notFound) {
		return 0;
	}
	else {
		return 1;
	}

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

	my $jobId = "d300696";
	my $step  = "o+1";

	# Get work layer
	$inCAM->COM('get_work_layer');

	my $layer = "$inCAM->{COMANS}";    # layer where rout is original rout

	my $mess = "";

	#my $res = Check1UpChain->OutsideChains( $inCAM, $jobId, $step, $layer, 1, 1, $messMngr );

	my $res = Check1UpChain->OutlineRoutChecks( $inCAM, $jobId, $step, $layer, $messMngr );

}

1;

