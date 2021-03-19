
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

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"path"} = shift // EnumsPaths->InCAM_server . "\\site_data\\library\\panel\\";

	# Properties
	$self->{"parsed"}   = 0;                                                                 # 1 if panel class files are parsed
	$self->{"classes"}  = [];
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"matKind"}  = HegMethods->GetMaterialKind( $self->{"jobId"} );
	$self->{"isFlex"}   = JobHelper->GetIsFlex( $self->{"jobId"} );
	$self->{"surface"}  = HegMethods->GetPcbSurface( $self->{"jobId"} );
	$self->{"zlaceni"} = CamGoldArea->GoldFingersExist( $self->{"inCAM"}, $self->{"jobId"}, "o+1", undef, ".gold_plating" );

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
	foreach my $node ( $sizesXML->findnodes('/PnlSize/size') ; ) {

		my $size = PnlSize->new( $node->{"name"} );
		$size->SetWidth( $node->{"width"} );
		$size->SetHeight( $node->{"height"} );

		push( @sizes, $size );
	}

	# 2) Parse borders
	my $pBord = $self->{"path"} . "pnlborderspacing.xml";

	die "Sizes definition: ${pBord} doesn't exist" unless ( -e $pBord );

	my $sizesXML = XML::LibXML->load_xml( "location" => $pBord );

	my @border = ();
	foreach my $node ( $sizesXML->findnodes('/PnlSize/borderSpacing ') ; ) {

		my $border = PnlBorder->new( $node->{"name"} );
		$border->SetLeftBorder( $node->{"leftBorder"} );
		$border->SetRightBorder( $node->{"rightBorder"} );
		$border->SetTopBorder( $node->{"topBorder"} );
		$border->SetBotBorder( $node->{"bottomBorder"} );

		push( @border, $border );
	}

	# 3) Parse spacing
	my $pSpac = $self->{"path"} . "pnlborderspacing.xml";

	die "Sizes definition: ${pSpac} doesn't exist" unless ( -e $pSpac );

	my $sizesXML = XML::LibXML->load_xml( "location" => $pSpac );

	my @space = ();
	foreach my $node ( $sizesXML->findnodes('/PnlSize/borderSpacing ') ; ) {

		my $space = PnlSpacing->new( $node->{"name"} );
		$space->SetSpaceX( $node->{"spaceX"} );
		$space->SetSpaceX( $node->{"spaceY"} );

		push( @space, $space );
	}

	# 3) Parse all classes
	my $pClass = $self->{"path"} . "pnlclass.xml";

	die "Sizes definition: ${$pClass} doesn't exist" unless ( -e $pClass );

	my $sizesXML = XML::LibXML->load_xml( "location" => $pClass );

	my @classes = ();
	foreach my $node ( $sizesXML->findnodes('/PnlSize/class ') ; ) {

		my $class = PnlSpacing->new( $node->{"name"} );
		$class->SetGoldScoringDist( $node->{"goldScoringDist"} );
		$class->SetTransformation( $node->{"transformation"} );
		$class->SetRotation( $node->{"rotation"} );
		$class->SetPattern( $node->{"pattern"} );
		$class->SetInterlock( $node->{"interlock"} );
		$class->SetSpacingAlign( $node->{"spacingAlign"} );
		$class->SetNumMaxSteps( $node->{"numMaxSteps"} );

		my @sz = ();
		foreach my $node ( $sizesXML->findnodes('/Sizes ') ) {

			my $obj = first { $_->GetName() eq $node->{"name"} } @sizes;
			die "Size: " . $node->{"name"} . " is not defined" unless ( defined $obj );

			push( @sz, $obj );
		}

		$class->SetSizes( \@sz );

		my @bord = ();
		foreach my $node ( $sizesXML->findnodes('/BordersSpacings ') ) {

			my $obj = first { $_->GetName() eq $node->{"name"} } @border;
			die "Border: " . $node->{"name"} . " is not defined" unless ( defined $obj );
			push( @bord, $obj );
		}

		$class->SetBorders( \@bord );

		my @spac = ();
		foreach my $node ( $sizesXML->findnodes('/BordersSpacings ') ) {

			my $obj = first { $_->GetName() eq $node->{"name"} } @space;
			die "Space: " . $node->{"name"} . " is not defined" unless ( defined $obj );
			push( @spac, $obj );
		}

		$class->SetBorders( \@spac );

		push( @classes, $class );
	}

	$self->{"classes"} = \@classes;

	$self->{"parsed"} = 1;
}

sub GetClassesCustomerPanel {
	my $self = shift;

}

sub GetClassesProductionPanel {
	my $self = shift;

}

sub __GetPCBMaterialType {
	my $self = shift;

	my $type = undef;

	if ( $self->{"matKind"} =~ /^AL_CORE|CU_CORE$/ ) {

		$type = Enums->PCBMaterialType_AL;

	}
	else {

		if ( $self->{"matKind"} =~ /^HYBRID$/ ) {

			$type = Enums->PCBMaterialType_HYBRID;

		}
		elsif ( $self->{"isFlex"} ) {

			$type = Enums->PCBMaterialType_FLEX;

		}
		else {

			$type = Enums->PCBMaterialType_RIGID;
		}
	}

	die "Type is not defined" unless ( defined $type );

	return $type;
}

sub __GetPCBLayerCntType {
	my $self = shift;

	my $type = undef;

	if ( $self->{"layerCnt"} <= 2 ) {

		$type = Enums->PCBLayerCnt_2V;

	}
	else {

		$type = Enums->PCBLayerCnt_VV;
	}

	die "Type is not defined" unless ( defined $type );

	return $type;
}

sub __GetPCBSpecialType {
	my $self = shift;

	my $type = undef;

	my $PbHAL = $self->{"surface"} =~ /^A$/ ? 1 : 0;
	my $HardGold = $self->{"zlaceni"};
	my $grafit =
	  scalar( grep { $_->{"gROWname"} =~ /^g[cs]$/i } CamJob->GetBoardBaseLayers( $self->{"inCAM"}, $self->{"jobId"} ) ) ? 1 : 0;

	# first has highest priority
	my @prior = ();

	push( @prior, Enums->PCBSpecial_GRAFIT ) if ($grafit);
	push( @prior, Enums->PCBSpecial_AU )     if ($HardGold);
	push( @prior, Enums->PCBSpecial_PBHAL )  if ($PbHAL);
	
	$type = shift @prior;

	return $type;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::CAM::PanelClass::PnlClassParser';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId  = "d222606";
	my $parser = PnlClassParser->new($jobId);
	$parser->Parse();

}

1;

