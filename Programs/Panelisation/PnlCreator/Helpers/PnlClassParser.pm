
#-------------------------------------------------------------------------------------------#
# Description: Parse information from InCAM global Library Panel classes
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Panelisation::PnlCreator::Helpers::PnlClassParser;
use base('Packages::CAM::PanelClass::PnlClassParser');

#3th party library
use strict;
use warnings;
use XML::LibXML qw(:threads_shared);
use List::Util qw(first);
use List::MoreUtils qw(uniq);

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
	my $inCAM = shift;
	my $jobId = shift;

	my $self = $class->SUPER::new( $inCAM, $jobId );
	bless $self;

	# Properties

	$self->{"layerCnt"} = CamJob->GetSignalLayerCnt( $self->{"inCAM"}, $self->{"jobId"} );
	$self->{"matKind"}  = HegMethods->GetMaterialKind( $self->{"jobId"} );
	$self->{"isFlex"}   = JobHelper->GetIsFlex( $self->{"jobId"} );

	$self->{"isSemiHybrid"} = 0;
	$self->{"isHybrid"} = JobHelper->GetIsHybridMat( $self->{"jobId"}, $self->{"matKind"}, [], \$self->{"isSemiHybrid"} );

	$self->{"surface"} = HegMethods->GetPcbSurface( $self->{"jobId"} );
	$self->{"zlaceni"} = CamGoldArea->GoldFingersExist( $self->{"inCAM"}, $self->{"jobId"}, "o+1", undef, ".gold_plating" );

	# Filter classes by panel type + PCB type
	$self->{"customerPnlClasses"}   = [];
	$self->{"productionPnlClasses"} = [];

	$self->SUPER::Parse();

	$self->__FilterBorderSpacing();

	$self->__AdjustCustomerClasses();
	$self->__AdjustProductionClasses();

	$self->__AdjustBorderSpacingName();

	return $self;
}

sub GetCustomerPnlClasses {
	my $self = shift;

	my $addEmptyClass = shift;    # Add class with no settings

	my @classes = @{ $self->{"customerPnlClasses"} };

	push( @classes, $self->__GetEmptyClass() ) if ($addEmptyClass);

	return @classes;
}

sub GetProductionPnlClasses {
	my $self          = shift;
	my $addEmptyClass = shift;    # Add class with no settings

	my @classes = @{ $self->{"productionPnlClasses"} };

	push( @classes, $self->__GetEmptyClass() ) if ($addEmptyClass);

	return @classes;

}

# Remove borders class which actually represent spacing
sub __FilterBorderSpacing {
	my $self = shift;

	my @classes = @{ $self->{"classes"} };

	foreach my $class (@classes) {

		foreach my $size ( $class->GetSizes() ) {

			# Borders
			my @realBorders = ();
			my @borders     = $size->GetBorders();
			foreach my $b (@borders) {

				push( @realBorders, $b ) if ( $b->GetName() =~ /^border_/ );
			}

			$size->SetBorders( \@realBorders );

			# Spacing
			my @realSpacing = ();
			my @spacings    = $size->GetSpacings();
			foreach my $s (@spacings) {

				push( @realSpacing, $s ) if ( $s->GetName() =~ /^spacing/ );
			}

			$size->SetSpacings( \@realSpacing );
		}
	}

}

# Border + spacings are combined into one structure in CAM, thus name conenction is:
# <type of PCB>_b<border size>_s<space size>
# Adjust name of theses splited structure to only "Border"/"Spacing"
sub __AdjustBorderSpacingName {
	my $self = shift;

	my @classes = ( @{ $self->{"customerPnlClasses"} }, @{ $self->{"productionPnlClasses"} } );

	my @borders  = map { $_->GetBorders() } map  { $_->GetSizes() } @classes;
	my @spacings = map { $_->GetSpacings() } map { $_->GetSizes() } @classes;

	foreach my $border (@borders) {

		my $str = "";
		$str .= sprintf( "%.1f", $border->GetBorderLeft() ) . "+";
		$str .= sprintf( "%.1f", $border->GetBorderRight() ) . "+";
		$str .= sprintf( "%.1f", $border->GetBorderTop() ) . "+";
		$str .= sprintf( "%.1f", $border->GetBorderBot() ) . " ";
		$str .= "(" . $border->GetName() . ")";

		$border->SetName($str);
	}

	foreach my $spacing (@spacings) {

		my $str = "";
		$str .= "X" . sprintf( "%.1f", $spacing->GetSpaceX() ) . "/";
		$str .= "Y" . sprintf( "%.1f", $spacing->GetSpaceY() ) . " ";
		$str .= "(" . $spacing->GetName() . ")";

		$spacing->SetName($str);
	}

}

sub AddCustomSizeToClass {
	my $self                = shift;
	my $class               = shift;
	my $sizeName            = shift;
	my $width               = shift;
	my $height              = shift;
	my $addAllBorderSpacing = shift // 1;    # Add all borders/spacings to new size from class

	my $size = PnlSize->new($sizeName);
	$size->SetWidth($width);
	$size->SetHeight($height);

	if ($addAllBorderSpacing) {
		$size->SetBorders(  [ uniq( map { $_->GetBorders() } $class->GetSizes() ) ] );
		$size->SetSpacings( [ uniq( map { $_->GetSpacings() } $class->GetSizes() ) ] );
	}

	$class->AddSize($size);

	return $size;

}

sub __AdjustCustomerClasses {
	my $self = shift;
	my $considerType = shift // 1;    # consider base pcb type (mat type + layer count)

	my @classes = @{ $self->{"classes"} };

	my $matType = $self->__GetPCBMaterialType();
	my $numType = $self->__GetPCBLayerCntType();

	my $className = join( "_", ( "mpanel", $matType, $numType ) );

	# 1) Filter classes
	@classes = grep { $_->GetName() =~ /^class_$className/i } @{ $self->{"classes"} };

	# 1) Pnl class
	foreach my $class (@classes) {

		die "Pnl class name: " . $class->GetName() . " has invlaid format" if ( $class->GetName() !~ /^class_mpanel_\w+_[2v]v$/ );

		# 2) Pnl size
		foreach my $size ( $class->GetSizes() ) {

			die "Pnl size class name: " . $size->GetName() . " has invlaid format" if ( $size->GetName() !~ /^size_mpanel_\w+_[2v]v_\w+_\d+x\d+$/ );

			# 3) Pnl border + spacing
			foreach my $borderName ( map { $_->GetName() } $size->GetBorders() ) {

				if ( $borderName !~ /^border_mpanel_l\d+_r\d+_t\d+_b\d+/i ) {
					die "Pnl borderclass name: ${borderName} has invlaid format ( /border_mpanel_b\\d+_s\\d+/)";
				}
			}

			foreach my $spacingName ( map { $_->GetName() } $size->GetSpacings() ) {

				if ( $spacingName !~ /^spacing_mpanel_X\d+(\.\d+)?_Y\d+(\.\d+)?/i ) {
					die "Pnl spacingclass name: ${spacingName} has invlaid format ( /spacing_mpanel_b\\d+_s\\d+/)";
				}

			}
		}
	}

	$self->{"customerPnlClasses"} = \@classes;
}

sub __AdjustProductionClasses {
	my $self = shift;

	my @classes = @{ $self->{"classes"} };

	my $matType = $self->__GetPCBMaterialType();
	my $numType = $self->__GetPCBLayerCntType();

	my $className = join( "_", ( $matType, $numType ) );

	# 1) Filter classes
	@classes = grep { $_->GetName() =~ /^class_$className$/i } @classes;

	# 2) Filter border + spacings in each class size

	# $self->__GetProductionPnlSpacings();

	foreach my $class (@classes) {

		foreach my $size ( $class->GetSizes() ) {

			my $class = first { $_->GetName() =~ /^class_$className/i } @{ $self->{"classes"} };
			die "Class:  $className was not found " unless ( defined $class );

			# add special type to name if exist
			my $spec = $self->__GetPCBSpecialType();

			my @allBorders      = $size->GetBorders();
			my @allSpacings     = $size->GetSpacings();
			my @filtredBorders  = ();
			my @filtredSpacings = ();

			# Borders
			my @parsedSze = split( "_", $size->GetName() );
			shift(@parsedSze);    # Remove prefix "size"
			push( @parsedSze, $spec ) if ( defined $spec );
			while ( scalar(@parsedSze) >= 0 ) {

				my $name = join( "_", @parsedSze );

				my @b = grep { $_->GetName() =~ /^border_$name$/i } @allBorders;
				if ( scalar(@b) ) {
					push( @filtredBorders, @b );
					last;
				}

				if ( scalar(@parsedSze) == 0 ) {
					last;
				}
				else {
					pop @parsedSze;
				}
			}

			# spacings
			@parsedSze = split( "_", $size->GetName() );
			shift(@parsedSze);    # Remove prefix "size"
			push( @parsedSze, $spec ) if ( defined $spec );
			while ( scalar(@parsedSze) >= 0 ) {

				my $name = join( "_", @parsedSze );

				my @b = grep { $_->GetName() =~ /^spacing_$name/i } @allSpacings;
				if ( scalar(@b) ) {
					push( @filtredSpacings, @b );
					last;
				}

				if ( scalar(@parsedSze) == 0 ) {
					last;
				}
				else {
					pop @parsedSze;
				}

			}

			$size->SetBorders(  [@filtredBorders] );
			$size->SetSpacings( [@filtredSpacings] );
		}
	}

	# 3) Do check of naming convention

	# 1) Pnl class
	foreach my $class (@classes) {

		die "Pnl class name: " . $class->GetName() . " has invlaid format" if ( $class->GetName() !~ /^class_\w+_[2v]v$/ );

		# 2) Pnl size
		foreach my $size ( $class->GetSizes() ) {

			die "Pnl size class name: " . $size->GetName() . " has invlaid format" if ( $size->GetName() !~ /^size_\w+_[2v]v_\d+x\d+$/ );

			my $className = $class->GetName();
			my $sizeName  = $size->GetName();

			# 3) Pnl border + spacing
			my $classTmp = $className;
			$classTmp =~ s/class_//;
			foreach my $borderName ( map { $_->GetName() } $size->GetBorders() ) {

				if ( $borderName !~ /border_$classTmp/i ) {
					die "Pnl borderclass name: ${borderName} has invlaid format (name should start with: /border_${classTmp}/)";
				}
			}

			foreach my $spacingName ( map { $_->GetName() } $size->GetSpacings() ) {

				if ( $spacingName !~ /spacing_$classTmp/i && $spacingName !~ /spacing_X\d+(\.\d+)?_Y\d+(\.\d+)?/i ) {
					die
'Pnl spacing class name: ${spacingName} has invlaid format (name should start with: /spacing_${classTmp}/ or /spacing_X\d+(\.\d+)?_Y\d+(\.\d+)?/i)';
				}

			}
		}

	}

	$self->{"productionPnlClasses"} = \@classes;

}

sub __GetPCBMaterialType {
	my $self = shift;

	my $type = undef;

	if ( $self->{"matKind"} =~ /^AL_CORE|CU_CORE$/ ) {

		$type = Enums->PCBMaterialType_AL;

	}
	else {
		if ( $self->{"isSemiHybrid"} ) {

			# Exception 1 -  if multilayer + coverlay, return hybrid
			if ( $self->{"layerCnt"} > 2 ) {

				$type = Enums->PCBMaterialType_HYBRID;
			}

			# Exception 2 -  if doublesided layer + coverlay, return flex
			if ( $self->{"layerCnt"} <= 2 ) {

				$type = Enums->PCBMaterialType_FLEX;
			}

		}
		elsif ( $self->{"isHybrid"} ) {

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

sub __GetEmptyClass {
	my $self = shift;

	my $name = shift // "<empty>";

	my $border   = PnlBorder->new($name);
	my $spacings = PnlSpacing->new($name);
	my $size     = PnlSize->new($name);
	my $class    = PnlClass->new($name);

	$size->SetBorders(  [$border] );
	$size->SetSpacings( [$spacings] );

	$class->SetSizes( [$size] );

	return $class;

}

#sub __GetProductionPnlSpacings {
#	my $self = shift;
#
#	my @spacings = ();
#
#	my $spac1 = PnlSpacing->new("Spacing 4,5x4,5mm");
#	$spac1->SetSpaceX(4.5);
#	$spac1->SetSpaceY(4.5);
#
#	push( @spacings, $spac1 );
#
#	my $spac2 = PnlSpacing->new("Spacing 10x10mm");
#	$spac2->SetSpaceX(10);
#	$spac2->SetSpaceY(10);
#
#	push( @spacings, $spac2 );
#
#	my $spac3 = PnlSpacing->new("Spacing 15x15mm");
#	$spac3->SetSpaceX(15);
#	$spac3->SetSpaceY(15);
#
#	push( @spacings, $spac3 );
#
#	return @spacings;
#
#}

#sub __GetCustomerPnlSpacings {
#	my $self = shift;
#
#	my @spacings = ();
#
#	my $spac1 = PnlSpacing->new("Customer_pnl_0mm");
#	$spac1->SetSpaceX(0);
#	$spac1->SetSpaceY(0);
#
#	push( @spacings, $spac1 );
#
#	my $spac2 = PnlSpacing->new("Customer_pnl_2mm");
#	$spac2->SetSpaceX(2);
#	$spac2->SetSpaceY(2);
#
#	push( @spacings, $spac2 );
#
#	my $spac3 = PnlSpacing->new("Customer_pnl_10mm");
#	$spac3->SetSpaceX(10);
#	$spac3->SetSpaceY(10);
#
#	push( @spacings, $spac3 );
#
#	return @spacings;
#
#}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Panelisation::PnlCreator::Helpers::PnlClassParser';
	use aliased 'Packages::InCAM::InCAM';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d324772";
	my $parser = PnlClassParser->new( $inCAM, $jobId );
	$parser->Parse();

	my @classes  = $parser->GetProductionPnlClasses();
	my @mclasses = $parser->GetCustomerPnlClasses();

	die;
}

1;

