
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

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"path"} = shift // EnumsPaths->InCAM_server . "\\site_data\\library\\panel\\";

	# Properties
	$self->{"parsed"}   = 0;       # 1 if panel class files are parsed
	$self->{"classes"}  = [];
	$self->{"layerCnt"} = undef;
	$self->{"matKind"}  = undef;
	$self->{"isFlex"}   = undef;
	$self->{"surface"}  = undef;
	$self->{"zlaceni"}  = undef;

	return $self;
}

# if no shorts and brokens, return 1, else 0
sub Parse {
	my $self = shift;

	# Set default job poperty
	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"matKind"}  = HegMethods->GetMaterialKind( $self->{"jobId"} );
	$self->{"isFlex"}   = JobHelper->GetIsFlex( $self->{"jobId"} );
	$self->{"surface"}  = HegMethods->GetPcbSurface( $self->{"jobId"} );
	$self->{"zlaceni"}  = CamGoldArea->GoldFingersExist( $self->{"inCAM"}, $self->{"jobId"}, "o+1", undef, ".gold_plating" );

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
		$border->SetLeftBorder($lb);
		$border->SetRightBorder($rb);
		$border->SetTopBorder($tb);
		$border->SetBotBorder($bb);

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

		my @sz = ();
		foreach my $nodeInner ( $node->findnodes('./Sizes/size') ) {

			my $obj = first { $_->GetName() eq $nodeInner->{"name"} } @sizes;
			die "Size: " . $nodeInner->{"name"} . " is not defined" unless ( defined $obj );

			push( @sz, $obj );
		}

		$class->SetSizes( \@sz );

		my @bord = ();
		foreach my $nodeInner ( $node->findnodes('./BordersSpacings/borderSpacing') ) {

			my $obj = first { $_->GetName() eq $nodeInner->{"name"} } @border;
			die "Border: " . $nodeInner->{"name"} . " is not defined" unless ( defined $obj );
			push( @bord, $obj );
		}

		$class->SetBorders( \@bord );

		my @spac = ();
		foreach my $nodeInner ( $node->findnodes('./BordersSpacings/borderSpacing') ) {

			my $obj = first { $_->GetName() eq $nodeInner->{"name"} } @space;
			die "Space: " . $nodeInner->{"name"} . " is not defined" unless ( defined $obj );
			push( @spac, $obj );
		}

		$class->SetSpacings( \@spac );

		push( @classes, $class );
	}

	$self->{"classes"} = \@classes;

	$self->{"parsed"} = 1;
}

sub GetCustomerPnlClasses {
	my $self = shift;
	my $considerType = shift // 1;    # consider base pcb type (mat type + layer count)

	my @classes = @{ $self->{"classes"} };

	if ($considerType) {

		my $matType = $self->__GetPCBMaterialType();
		my $numType = $self->__GetPCBLayerCntType();

		my $className = join( "_", ( "mpanel", $matType, $numType ) );

		@classes = grep { $_->GetName() =~ /^$className/i } @{ $self->{"classes"} };

	}

	# 1) Pnl class
	foreach my $class (@classes) {

		die "Pnl class name: " . $class->GetName() . " has invlaid format" if ( $class->GetName() !~ /^mpanel_\w+_[2v]v$/ );

		# 2) Pnl size
		foreach my $sizeName ( map { $_->GetName() } $class->GetSizes() ) {

			die "Pnl size class name: ${sizeName} has invlaid format" if ( $sizeName !~ /^mpanel_\w+_[2v]v_\w+_\d+x\d+$/ );
		}

		# 3) Pnl border + spacing
		foreach my $borderName ( map { $_->GetName() } ( $class->GetBorders(), $class->GetSpacings() ) ) {

			die "Pnl border/spacing class name: ${borderName} has invlaid format"
			  if ( $borderName !~ /^mpanel(_\w+)?(_[2v]v)?/ );
		}
	}

	return @classes;
}

sub GetProductionPnlClasses {
	my $self = shift;
	my $considerType = shift // 1;    # consider base pcb type (mat type + layer count)

	my @classes = @{ $self->{"classes"} };

	if ($considerType) {
		my $matType = $self->__GetPCBMaterialType();
		my $numType = $self->__GetPCBLayerCntType();

		my $className = join( "_", ( $matType, $numType ) );

		@classes = grep { $_->GetName() =~ /^$className$/i } @{ $self->{"classes"} };

	}

	# Do check of naming convention

	# 1) Pnl class
	foreach my $class (@classes) {

		die "Pnl class name: " . $class->GetName() . " has invlaid format" if ( $class->GetName() !~ /^\w+_[2v]v$/ );

		# 2) Pnl size
		foreach my $sizeName ( map { $_->GetName() } $class->GetSizes() ) {

			die "Pnl size class name: ${sizeName} has invlaid format" if ( $sizeName !~ /^\w+_[2v]v_\d+x\d+$/ );
		}

		# 3) Pnl border + spacing
		foreach my $borderName ( map { $_->GetName() } ( $class->GetBorders(), $class->GetSpacings() ) ) {

			die "Pnl border/spacing class name: ${borderName} has invlaid format"
			  if ( $borderName !~ /^\w+_[2v]v(_\d+x\d+)?(_\w+)?$/ );
		}
	}

	return @classes;

}

sub GetProductionPnlBorder {
	my $self      = shift;
	my $className = shift;
	my $sizeName  = shift;

	my @borders = $self->__GetProductionPnlBS( $className, $sizeName, "border" );

	return @borders;
}

sub GetProductionPnlSpace {
	my $self      = shift;
	my $className = shift;
	my $sizeName  = shift;

	my @borders = $self->__GetProductionPnlBS( $className, $sizeName, "space" );

	return @borders;
}

sub GetCustomerPnlBorder {
	my $self      = shift;
	my $className = shift;
	my $sizeName  = shift;

	my @borders = $self->__GetCustomerPnlBS( $className, $sizeName, "border" );

	return @borders;
}

sub GetCustomerPnlSpace {
	my $self      = shift;
	my $className = shift;
	my $sizeName  = shift;

	my @borders = $self->__GetCustomerPnlBS( $className, $sizeName, "space" );

	return @borders;
}

sub __GetProductionPnlBS {
	my $self      = shift;
	my $className = shift;
	my $sizeName  = shift;
	my $type      = shift;    # borde / space

	die "Class is not defined"      if ( !defined $className );
	die "Class size is not defined" if ( !defined $sizeName );

	my $class = first { $_->GetName() =~ /^$sizeName$/i } @{ $self->{"classes"} };
	die "Class:  $className was not found " unless ( defined $class );

	my @parsedSze = split( "_", $sizeName );

	# add special type to name if exist
	my $spec = $self->__GetPCBSpecialType();
	push( @parsedSze, $spec ) if ( defined $spec );

	my @class = ();

	my @allClass = ();

	if ( $type eq "border" ) {

		@allClass = @{ $class->GetBorders() };
	}
	elsif ( $type eq "border" ) {

		@allClass = @{ $class->GetSpaces() };
	}
	else {

		die "Unknow type..";
	}

	while ( scalar(@class) == 0 ) {

		my $name = join( "_", @parsedSze );

		my @b = grep { $_->GetName() =~ /^$name/i } @allClass;
		push( @class, @b ) if ( scalar(@b) );
	}

	return @class;
}

sub __GetCustomerPnlBS {
	my $self      = shift;
	my $className = shift;
	my $sizeName  = shift;
	my $type      = shift;    # borde / space

	die "Class is not defined"      if ( !defined $className );
	die "Class size is not defined" if ( !defined $sizeName );

	my $class = first { $_->GetName() =~ /^$sizeName$/i } @{ $self->{"classes"} };
	die "Class:  $className was not found " unless ( defined $class );

	my @parsedSze = split( "_", $sizeName );

	my @class = ();

	my @allClass = ();

	if ( $type eq "border" ) {

		@allClass = @{ $class->GetBorders() };
	}
	elsif ( $type eq "border" ) {

		@allClass = @{ $class->GetSpaces() };
	}
	else {

		die "Unknow type..";
	}

	while ( scalar(@class) == 0 ) {

		my $name = join( "_", @parsedSze );

		my @b = grep { $_->GetName() =~ /^$name/i } @allClass;
		push( @class, @b ) if ( scalar(@b) );
	}

	return @class;
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

