
#-------------------------------------------------------------------------------------------#
# Description: Simple "drawing" which allow keep simple symbols
# Then draw this symbols on specific coordinate with specific mirror
# Allow draw symbols and primitives. See class ISymbol and IPrimitive
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::SymbolDrawing::SymbolDrawing;

#3th party library
use utf8;
use strict;
use warnings;

#local library

use aliased 'Packages::CAM::SymbolDrawing::Enums';
use aliased 'CamHelpers::CamSymbol';
use aliased 'Packages::CAM::SymbolDrawing::Point';
use aliased 'CamHelpers::CamSymbolArc';
use aliased 'CamHelpers::CamSymbolSurf';
use aliased 'Packages::CAM::SymbolDrawing::SymbolInfo';
use aliased 'Packages::CAM::SymbolDrawing::Symbol::SymbolBase';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;

	$self = {};
	bless $self;

	$self->{"inCAM"}    = shift;
	$self->{"jobId"}    = shift;
	$self->{"position"} = shift;

	unless ( $self->{"position"} ) {
		$self->{"position"} = Point->new();
	}

	$self->{"mirrorX"}      = 0;
	$self->{"mirrorY"}      = 0;
	$self->{"mirrorXPoint"} = $self->{"position"}->Copy();
	$self->{"mirrorYPoint"} = $self->{"position"}->Copy();

	my @syms = ();
	$self->{"symbol"} = SymbolBase->new();    # parent of all symbols and primitives
	
	$self->{"symbol"}->SetPassGUID2prim(0);  # we don't want all primitives has same group GUID

	return $self;
}

sub AddSymbol {
	my $self = shift;
	my $sym  = shift;
	my $pos  = shift;

	$self->{"symbol"}->AddSymbol( $sym, $pos );

}

sub AddPrimitive {
	my $self      = shift;
	my $primitive = shift;

	$self->{"symbol"}->AddPrimitive($primitive);
	
	
}

sub SetMirrorX {
	my $self        = shift;
	my $mirrorPoint = shift;

	$self->{"mirrorX"} = 1;

	if ( defined $mirrorPoint ) {
		$self->{"mirrorXPoint"} = $mirrorPoint;
	}
}

sub SetMirrorY {
	my $self        = shift;
	my $mirrorPoint = shift;
	$self->{"mirrorY"} = 1;

	if ( defined $mirrorPoint ) {
		$self->{"mirrorYPoint"} = $mirrorPoint;
	}
}

sub Draw {
	my $self = shift;

	# 1)  Get all primitives
	my @primitives = ();

	$self->__GetPrimitives( $self->{"symbol"}, Point->new(), \@primitives );

	# 2) Mirror X,Y if set
	#$self->Mirror()

	# 3) Draw primitives
	$self->__DrawPrimitives( \@primitives );

}

sub __DrawPrimitives {
	my $self       = shift;
	my @primitives = @{ shift(@_) };
	
	$self->{"inCAM"}->COM( "cur_atr_reset"); # reset currently set attributes

	foreach my $pInfo (@primitives) {

		my $primitives = $pInfo->{"primitives"};
		my $pos        = $pInfo->{"position"};

		foreach my $p ( @{$primitives} ) {
			
			# Every primitive feature have set attribute feat_group_id
			CamSymbol->AddCurAttribute($self->{"inCAM"}, $self->{"jobId"}, "feat_group_id", $p->GetGroupGUID());
			

			if ( $p->GetType() eq Enums->Primitive_LINE ) {

				$self->__DrawLine( $p, $pos );

			}
			elsif ( $p->GetType() eq Enums->Primitive_TEXT ) {

				$self->__DrawText( $p, $pos );

			}
			elsif ( $p->GetType() eq Enums->Primitive_ARCSCE ) {

				$self->__DrawArcSCE( $p, $pos );

			}
			elsif ( $p->GetType() eq Enums->Primitive_SURFACEPOLY ) {

				$self->__DrawSurfPoly( $p, $pos );
			}
			elsif ( $p->GetType() eq Enums->Primitive_PAD ) {

				$self->__DrawPad( $p, $pos );
			}
			
			
			
			
			CamSymbol->ResetCurAttributes($self->{"inCAM"});
		}
	}
}

sub __DrawLine {
	my $self      = shift;
	my $line      = shift;
	my $symbolPos = shift;

	# consider origin of whole drawing + origin of symbol hierarchy

	my $sP = $line->GetStartP();
	my $eP = $line->GetEndP();
	$sP->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );
	$eP->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );

	# consider mirror
	if ( $self->{"mirrorX"} ) {

		$sP->MirrorX( $self->{"mirrorXPoint"} );
		$eP->MirrorX( $self->{"mirrorXPoint"} );
	}

	CamSymbol->AddLine( $self->{"inCAM"}, $sP, $eP, $line->GetSymbol(), $line->GetPolarity() );

}

sub __DrawText {
	my $self      = shift;
	my $t         = shift;
	my $symbolPos = shift;

	# consider origin of whole draw

	my $p = $t->GetPosition();
	$p->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );

	# consider mirror

	my $mirror = $t->GetMirror();

	if ( $self->{"mirrorX"} ) {

		$p->MirrorX( $self->{"mirrorXPoint"} );
		$p->Move( 0, -$t->GetHeight() );

		if ( $mirror == 1 ) {
			$mirror = 0;
		}
		else {
			$mirror = 1;
		}

	}

	CamSymbol->AddText( $self->{"inCAM"}, $t->GetValue(), $p, $t->GetHeight(), $t->GetLineWidth(), $mirror, $t->GetPolarity(), $t->GetAngle() );

}

sub __DrawPad {
	my $self      = shift;
	my $t         = shift;
	my $symbolPos = shift;

	# consider origin of whole draw

	my $p = $t->GetPosition();
	$p->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );

	# consider mirror

	my $mirror = $t->GetMirror();

	if ( $self->{"mirrorX"} ) {

		$p->MirrorX( $self->{"mirrorXPoint"} );
		$p->Move( 0, -$t->GetHeight() );

		if ( $mirror == 1 ) {
			$mirror = 0;
		}
		else {
			$mirror = 1;
		}

	}

	CamSymbol->AddPad( $self->{"inCAM"}, $t->GetSymbol(), $p, $mirror, $t->GetPolarity() );

}

sub __DrawArcSCE {
	my $self      = shift;
	my $arc       = shift;
	my $symbolPos = shift;

	my $dir = $arc->GetDirection();

	# consider origin of whole draw

	my $sP = $arc->GetStartP();
	my $cP = $arc->GetCenterP();
	my $eP = $arc->GetEndP();

	$sP->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );
	$cP->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );
	$eP->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );

	# consider mirror
	if ( $self->{"mirrorX"} ) {

		$sP->MirrorX( $self->{"mirrorXPoint"} );
		$cP->MirrorX( $self->{"mirrorXPoint"} );
		$eP->MirrorX( $self->{"mirrorXPoint"} );

		# and switch start and
		$dir = "ccw";
	}

	CamSymbolArc->AddArcStartCenterEnd( $self->{"inCAM"}, $sP, $cP, $eP, $dir, $arc->GetSymbol(), $arc->GetPolarity() );

}

sub __DrawSurfPoly {
	my $self      = shift;
	my $surf      = shift;
	my $symbolPos = shift;

	# consider origin of whole drawing + origin of symbol hierarchy
	foreach my $p ( $surf->GetPoints() ) {

		$p->Move( $self->{"position"}->X() + $symbolPos->X(), $self->{"position"}->Y() + $symbolPos->Y() );
	}

	# consider mirror
	# consider mirror
	if ( $self->{"mirrorX"} ) {
		foreach my $p ( $surf->GetPoints() ) {

			$p->MirrorX( $self->{"mirrorXPoint"} );
		}
	}

	# set surface pattern
	my $patt = $surf->GetPattern();

	if ( $patt->GetPredefined_pattern_type() eq "lines" ) {

		CamSymbolSurf->AddSurfaceLinePattern(
											  $self->{"inCAM"},           $patt->GetOutline_draw(),
											  $patt->GetOutline_width(),  $patt->GetLines_angle(),
											  $patt->GetOutline_invert(), $patt->GetLines_width(),
											  $patt->GetLines_dist()
		);

	}
	elsif ( $patt->GetPredefined_pattern_type() eq "solid" ) {

		CamSymbolSurf->AddSurfaceLinePattern( $self->{"inCAM"}, $patt->GetOutline_draw(), $patt->GetOutline_width() );
	}

	my @points = $surf->GetPoints();
	CamSymbolSurf->AddSurfacePolyline( $self->{"inCAM"}, \@points, 1 );

}

sub __GetPrimitives {
	my $self       = shift;
	my $symbol     = shift;
	my $position   = shift;
	my $primitives = shift;

	my @childSymbols = $symbol->GetSymbols();

	if ( scalar(@childSymbols) ) {

		# recusive search another nested symbols
		foreach my $sInfo (@childSymbols) {

			my $s = $sInfo->GetSymbol();
			my $p = $sInfo->GetPosition();

			# consider position of parent symbol
			$p->Move( $position->X(), $position->Y() );

			$self->__GetPrimitives( $s, $p, $primitives );
		}
	}

	my @primitives = $symbol->GetPrimitives();

	if ( scalar(@primitives) ) {
		my %info = ( "primitives" => \@primitives, "position" => $position );

		#get primitives
		push( @{$primitives}, \%info );
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::CAM::SymbolDrawing::SymbolDrawing';
	#	use aliased 'Packages::InCAM::InCAM';
	#	use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimV1Lines';
	#	use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimH1Lines';
	#	use aliased 'Packages::CAM::SymbolDrawing::SymbolLib::DimAngle1';
	#
	#	my $inCAM = InCAM->new();
	#
	#	$inCAM->COM("sel_delete");

	#	my $textValue     = shift;
	#	my $textHeight    = shift;     # font size in mm
	#	my $textLineWidth = shift;     # font size in mm

	#my $dim = DimH1Lines->new( "top", "left", 150, 10, 50,200, "r1000", " Dim 50 mm", 10, 2 );
	#my $dim = DimV1Lines->new( "right", "bot", 150, 10, 50,200, "r1000", " Dim 50 mm", 10, 2 );
	# my $dim = DimAngle1->new( 120, 50, "r1000", " Dim 50 mm", 10, 2 );

	#
	#  my $draw = SymbolDrawing->new($inCAM);
	#  $draw->AddSymbol($dim);
	#  $draw->Draw();

}

1;

