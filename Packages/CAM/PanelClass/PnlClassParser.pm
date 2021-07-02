
#-------------------------------------------------------------------------------------------#
# Description: Parse information from InCAM global Library Panel classes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAM::PanelClass::PnlClassParser;

#3th party library
use strict;
use warnings;
use XML::LibXML qw(:threads_shared);
use List::Util qw(first);

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::JobHelper';
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamGoldArea';
use aliased 'Packages::CAM::PanelClass::Classes::PnlBorder';
use aliased 'Packages::CAM::PanelClass::Classes::PnlSpacing';
use aliased 'Packages::CAM::PanelClass::Classes::PnlSize';
use aliased 'Packages::CAM::PanelClass::Classes::PnlClass';
use aliased 'Packages::CAM::PanelClass::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new{
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"path"} = shift // EnumsPaths->InCAM_server . "\\site_data\\library\\panel\\";

	# Properties
	$self->{"parsed"}   = 0;       # 1 if panel class files are parsed
	$self->{"classes"}  = [];
 

	return $self;
  }

  # if no shorts and brokens, return 1, else 0
sub Parse {
	my $self = shift;
 
	# 1) Parse all sizes
	my $pSize = $self->{"path"} . "pnlsize.xml";

	die "Sizes definition: ${pSize} doesn't exist" unless ( -e $pSize );

	my $sizesXML = XML::LibXML->load_xml( "location" => $pSize );

	my @sizes = ();
	foreach my $node ( $sizesXML->findnodes('/PnlSize/size') ) {

		my $w = $node->{"width"};
		my $h = $node->{"height"};

		$w = $self->__INCH2MM($w) if ( $node->{"units"} eq "inch" );
		$h = $self->__INCH2MM($h) if ( $node->{"units"} eq "inch" );

		my $size = PnlSize->new( $node->{"name"} );

		$size->SetWidth($w);
		$size->SetHeight($h);

		push( @sizes, $size );
	}

	# 2) Parse borders
	my $pBord = $self->{"path"} . "pnlborderspacing.xml";

	die "Sizes definition: ${pBord} doesn't exist" unless ( -e $pBord );

	my $bordSpacXML = XML::LibXML->load_xml( "location" => $pBord );

	my @border = ();
	foreach my $node ( $bordSpacXML->findnodes('/PnlBorderSpacing/borderSpacing ') ) {

		my $lb = $node->{"leftBorder"};
		my $rb = $node->{"rightBorder"};
		my $tb = $node->{"topBorder"};
		my $bb = $node->{"bottomBorder"};

		$lb = $self->__INCH2MM($lb) if ( $node->{"units"} eq "inch" );
		$rb = $self->__INCH2MM($rb) if ( $node->{"units"} eq "inch" );
		$tb = $self->__INCH2MM($tb) if ( $node->{"units"} eq "inch" );
		$bb = $self->__INCH2MM($bb) if ( $node->{"units"} eq "inch" );

		my $border = PnlBorder->new( $node->{"name"} );
		$border->SetBorderLeft($lb);
		$border->SetBorderRight($rb);
		$border->SetBorderTop($tb);
		$border->SetBorderBot($bb);

		push( @border, $border );
	}

	# 3) Parse spacing

	my @space = ();
	foreach my $node ( $bordSpacXML->findnodes('/PnlBorderSpacing/borderSpacing ') ) {

		my $sX = $node->{"spaceX"};
		my $sY = $node->{"spaceY"};

		$sX = $self->__INCH2MM($sX) if ( $node->{"units"} eq "inch" );
		$sY = $self->__INCH2MM($sY) if ( $node->{"units"} eq "inch" );

		my $space = PnlSpacing->new( $node->{"name"} );
		$space->SetSpaceX($sX);
		$space->SetSpaceY($sY);

		push( @space, $space );
	}

	# 3) Parse all classes
	my $pClass = $self->{"path"} . "pnlclass.xml";

	die "Sizes definition: ${$pClass} doesn't exist" unless ( -e $pClass );

	my $classesXML = XML::LibXML->load_xml( "location" => $pClass );

	my @classes = ();
	foreach my $node ( $classesXML->findnodes('/PnlClass/class') ) {

		my $class = PnlClass->new( $node->{"name"} );
		$class->SetGoldScoringDist( $node->{"goldScoringDist"} );
		$class->SetTransformation( $node->{"transformation"} );
		$class->SetRotation( $node->{"rotation"} );
		$class->SetPattern( $node->{"pattern"} );
		$class->SetInterlock( $node->{"interlock"} );
		$class->SetSpacingAlign( $node->{"spacingAlign"} );
		$class->SetNumMaxSteps( $node->{"numMaxSteps"} );

		# Parse borders
		my @bord = ();
		foreach my $nodeInner ( $node->findnodes('./BordersSpacings/borderSpacing') ) {

			my $obj = first { $_->GetName() eq $nodeInner->{"name"} } @border;
			die "Border: " . $nodeInner->{"name"} . " is not defined" unless ( defined $obj );
			push( @bord, $obj );
		}

		# parse spacing
		my @spac = ();
		foreach my $nodeInner ( $node->findnodes('./BordersSpacings/borderSpacing') ) {

			my $obj = first { $_->GetName() eq $nodeInner->{"name"} } @space;
			die "Space: " . $nodeInner->{"name"} . " is not defined" unless ( defined $obj );
			push( @spac, $obj );
		}

		# all border and spacing in class are matched in all sizes
		my @sz = ();
		foreach my $nodeInner ( $node->findnodes('./Sizes/size') ) {

			my $obj = first { $_->GetName() eq $nodeInner->{"name"} } @sizes;
			die "Size: " . $nodeInner->{"name"} . " is not defined" unless ( defined $obj );

			$obj->SetBorders( \@bord );
			$obj->SetSpacings( \@spac );

			push( @sz, $obj );
		}

		$class->SetSizes( \@sz );

		push( @classes, $class );
	}

	$self->{"classes"} = \@classes;

	$self->{"parsed"} = 1;
}

sub __INCH2MM {
	my $self = shift;
	my $val  = shift;

	$val = sprintf( "%.3f", $val * 25.4 );

	return $val;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::PanelClass::PnlClassParser';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d222606";
	my $parser = PnlClassParser->new( $inCAM, $jobId );
	$parser->Parse();

	my @classes  = $parser->GetClassesProductionPanel();
	my @mclasses = $parser->GetClassesCustomerPanel();

	die;
}

1;

