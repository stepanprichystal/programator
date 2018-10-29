
#-------------------------------------------------------------------------------------------#
# Description: Class provide function for loading / saving tif file
# TIF - technical info file - contain onformation important for produce, for technical list,
# another support script use this file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::Microsection::Microsection;

#3th party library
use strict;
use warnings;
use JSON;

#local library
use aliased 'Helpers::JobHelper';
use aliased "Helpers::FileHelper";
use aliased 'CamHelpers::CamDrilling';
use aliased 'Enums::EnumsGeneral';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
use aliased 'CamHelpers::CamSymbol';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamHelper';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamJob';


#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

my $CPN_HEIGHT      = 4000 + 3000;             # 1000 is text
my $HOLE_DIST       = 1700;
my $CPN_GROUP_WIDTH = 5900 + $HOLE_DIST / 2 + 300;

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	return $self;
}

sub CreateCoupon {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @groups = $self->__GetGroups();

	my $stepName = EnumsGeneral->Coupon_DRILL;

	my $step = SRStep->new( $inCAM, $jobId, $stepName );
	$step->Create( (scalar(@groups) * $CPN_GROUP_WIDTH)/1000, $CPN_HEIGHT/1000, 0, 0, 0, 0 );

	CamHelper->SetStep( $inCAM, $stepName );

	#my $d = SymbolDrawing->new($inCAM, $jobId);

	my @holes = $self->__GetAllHoles( \@groups );

	# Signal pads
	my @sigLayers = CamJob->GetSignalLayerNames( $inCAM, $jobId );

	foreach my $l (@sigLayers) {

		CamLayer->WorkLayer( $inCAM, $l );

		foreach my $h (@holes) {
			
			my $p = Point->new($h->X()/1000, $h->Y()/1000);
			CamSymbol->AddPad( $inCAM, "r1400", $p );
		}
	}

	# mask pads
	my @maskLayers = grep { $_->{"gROWname"} =~ /^m[cs]$/ } CamJob->GetBoardLayers( $inCAM, $jobId );

	foreach my $l (@maskLayers) {

		CamLayer->WorkLayer( $inCAM, $l->{"gROWname"});

		foreach my $h (@holes) {
			
			my $p = Point->new($h->X()/1000, $h->Y()/1000);
			
			CamSymbol->AddPad( $inCAM, "r1480", $p );
		}
		
		my %lim = CamJob->GetProfileLimits2( $inCAM, $jobId, $stepName );
		
		my %c1 = ( "x" => $lim{"xMin"}, "y" => $lim{"yMin"} );
		my %c2 = ( "x" => $lim{"xMax"}, "y" => $lim{"yMin"} );
		my %c3 = ( "x" => $lim{"xMax"}, "y" => $lim{"yMax"} );
		my %c4 = ( "x" => $lim{"xMin"}, "y" => $lim{"yMax"} );
		
		my @coord = ( \%c1, \%c2, \%c3, \%c4 );

		#
		CamSymbol->AddPolyline( $inCAM, \@coord, "r200", "positive", 1 );
	}

	# add holes
	for ( my $i = 0 ; $i < scalar(@groups) ; $i++ ) {

		my @holes = $self->__GetGroupHoles($i);

		CamLayer->WorkLayer( $inCAM, $groups[$i]->{"layer"} );

		foreach my $h (@holes) {
			
			my $p = Point->new($h->X()/1000, $h->Y()/1000);
			
			CamSymbol->AddPad( $inCAM, "r".$groups[$i]->{"tool"}, $p );
		}
	}
 

	# add texts 1
	CamLayer->WorkLayer( $inCAM, "c" );
	for ( my $i = 0 ; $i < scalar(@groups) ; $i++ ) {

		my $p = Point->new( ($i * $CPN_GROUP_WIDTH) +500, $CPN_HEIGHT - 1500 );

		my $p2 = Point->new($p->X()/1000, $p->Y()/1000);

		CamSymbol->AddText( $inCAM, $groups[$i]->{"text"}, $p2, 1, 0.2, 0.3 );
	}
	
	# add texts 2
	CamLayer->WorkLayer( $inCAM, "c" );
	for ( my $i = 0 ; $i < scalar(@groups) ; $i++ ) {

		my $p = Point->new( ($i * $CPN_GROUP_WIDTH) +500, $CPN_HEIGHT - 2700 );

		my $p2 = Point->new($p->X()/1000, $p->Y()/1000);

		CamSymbol->AddText( $inCAM, $groups[$i]->{"text2"}, $p2, 1, 0.2, 0.3 );
	}
	
	# add separator
	CamLayer->WorkLayer( $inCAM, "c" );
	for ( my $i = 1 ; $i < scalar(@groups); $i++ ) {

		my $ps = Point->new( ($i * $CPN_GROUP_WIDTH)/1000, ($CPN_HEIGHT -200)/1000 );
		my $pe = Point->new( ($i * $CPN_GROUP_WIDTH)/1000, (200)/1000 );
 
		CamSymbol->AddLine( $inCAM,  $ps, $pe, "r200" );
	}

}

sub __GetGroups {
	my $self = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @layers = CamDrilling->GetNCLayersByTypes(
												  $inCAM, $jobId,
												  [
													 EnumsGeneral->LAYERTYPE_plt_nDrill,    EnumsGeneral->LAYERTYPE_plt_bDrillTop,
													 EnumsGeneral->LAYERTYPE_plt_bDrillBot, EnumsGeneral->LAYERTYPE_plt_cDrill
												  ]
	);

	CamDrilling->AddLayerStartStop( $inCAM, $jobId, \@layers );

	my @uniqueSR = map { $_->{"stepName"} } CamStepRepeat->GetUniqueStepAndRepeat( $inCAM, $jobId, "panel" );

	my @groups = ();

	foreach my $l (@layers) {

		my $addGroup = 1;
		my $minTool  = undef;

		foreach my $s (@uniqueSR) {

			my $t = CamDrilling->GetMinHoleToolByLayers( $inCAM, $jobId, $s, [ $l] );

			if ( !defined $minTool || $t < $minTool ) {
				$minTool = $t;
			}
		}

		if ( !defined $minTool || $minTool > 1000 ) {
			$addGroup = 0;
			last;
		}
		else {

			my %inf = ();
			$inf{"layer"} = $l->{"gROWname"};
			$inf{"tool"}  = $minTool;
			$inf{"text"}  = "L".$l->{"gROWdrl_start"} . "-" . $l->{"gROWdrl_end"};
			$inf{"text2"}  = "D".sprintf("%.2f", $minTool/1000);
			
			

			push( @groups, \%inf );

		}

	}

	return @groups;
}

sub __GetGroupHoles {
	my $self       = shift;
	my $groupOrder = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my @pos = ();

	# 1 line
	push( @pos, Point->new( 1400,                      1400 ) );
	push( @pos, Point->new( $pos[0]->X() + $HOLE_DIST, $pos[0]->Y() ) );
	push( @pos, Point->new( $pos[1]->X() + $HOLE_DIST, $pos[1]->Y() ) );

	# 2 line
	push( @pos, Point->new( $pos[0]->X() + $HOLE_DIST / 2, $pos[0]->Y() + $HOLE_DIST ) );
	push( @pos, Point->new( $pos[1]->X() + $HOLE_DIST / 2, $pos[1]->Y() + $HOLE_DIST ) );
	push( @pos, Point->new( $pos[2]->X() + $HOLE_DIST / 2, $pos[2]->Y() + $HOLE_DIST ) );

	foreach my $p (@pos) {

		my $move = $groupOrder * $CPN_GROUP_WIDTH;

		$p->Move( $move, 0 );
	}

	return @pos;
}

sub __GetAllHoles {
	my $self   = shift;
	my $groups = shift;

	my @holes = ();

	for ( my $i = 0 ; $i < scalar( @{$groups} ) ; $i++ ) {

		push( @holes, $self->__GetGroupHoles($i) );
	}

	return @holes;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	
	use aliased 'Packages::CAMJob::Microsection::Microsection';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "d113608";
	my $step  = "panel";

	my $m = Microsection->new( $inCAM, $jobId );
	$m->CreateCoupon();

}

1;

