
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
	$self->{"surface"}  = HegMethods->GetPcbSurface( $self->{"jobId"} );
	$self->{"zlaceni"}  = CamGoldArea->GoldFingersExist( $self->{"inCAM"}, $self->{"jobId"}, "o+1", undef, ".gold_plating" );

	# Filter classes by panel type + PCB type
	$self->{"customerPnlClasses"}   = [];
	$self->{"productionPnlClasses"} = [];

	$self->Parse();

	#$self->__AdjustCustomerClasses();
	$self->__AdjustProductionClasses();

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
	@classes = grep { $_->GetName() =~ /^$className/i } @{ $self->{"classes"} };

	# 2) Filter border + spacings in each class size
	my @spacings = $self->__GetCustomerPnlSpacings();

	foreach my $class (@classes) {

		foreach my $size ( $class->GetSizes() ) {

			my @parsedSze = split( "_", $size->GetName() );

			my @allBorders = $size->GetBorders();

			my @filtredBorders = ();

			while ( scalar(@filtredBorders) == 0 ) {

				my $name = join( "_", @parsedSze );

				my @b = grep { $_->GetName() =~ /^$name/i } @allBorders;
				push( @filtredBorders, @b ) if ( scalar(@b) );
			}

			$size->SetBorders( \@filtredBorders );
			$size->SetSpacings( [@spacings] );
		}
	}

	# 3) Do check of naming convention

	# 1) Pnl class
	foreach my $class (@classes) {

		die "Pnl class name: " . $class->GetName() . " has invlaid format" if ( $class->GetName() !~ /^mpanel_\w+_[2v]v$/ );

		# 2) Pnl size
		foreach my $sizeName ( map { $_->GetName() } $class->GetSizes() ) {

			die "Pnl size class name: ${sizeName} has invlaid format" if ( $sizeName !~ /^mpanel_\w+_[2v]v_\w+_\d+x\d+$/ );
		}

		# 3) Pnl border + spacing
		foreach my $borderName ( map { $_->GetName() } ( $class->GetBorders() ) ) {

			die "Pnl border/spacing class name: ${borderName} has invlaid format"
			  if ( $borderName !~ /^mpanel(_\w+)?(_[2v]v)?/ );
		}
	}

	return @classes;
}

sub __AdjustProductionClasses {
	my $self = shift;

	my @classes = @{ $self->{"classes"} };

	my $matType = $self->__GetPCBMaterialType();
	my $numType = $self->__GetPCBLayerCntType();

	my $className = join( "_", ( $matType, $numType ) );

	# 1) Filter classes
	@classes = grep { $_->GetName() =~ /^$className$/i } @{ $self->{"classes"} };

	# 2) Filter border + spacings in each class size
	my @spacings = $self->__GetProductionPnlSpacings();

	foreach my $class (@classes) {

		foreach my $size ( $class->GetSizes() ) {

			my $class = first { $_->GetName() =~ /^$className/i } @{ $self->{"classes"} };
			die "Class:  $className was not found " unless ( defined $class );

			# add special type to name if exist
			my $spec = $self->__GetPCBSpecialType();

			my @allBorders     = $size->GetBorders();
			my @filtredBorders = ();

			my @parsedSze = split( "_", $size->GetName() );
			push( @parsedSze, $spec ) if ( defined $spec );
			while ( scalar(@parsedSze) > 0 ) {

				my $name = join( "_", @parsedSze );

				my @b = grep { $_->GetName() =~ /^$name$/i } @allBorders;
				if ( scalar(@b) ) {
					push( @filtredBorders, @b );
					last;
				}

				pop @parsedSze;
			}

			$size->SetBorders( \@filtredBorders );
			$size->SetSpacings( [@spacings] );
		}
	}

	# 3) Do check of naming convention

	# 1) Pnl class
	foreach my $class (@classes) {

		die "Pnl class name: " . $class->GetName() . " has invlaid format" if ( $class->GetName() !~ /^\w+_[2v]v$/ );

		# 2) Pnl size
		foreach my $size ( $class->GetSizes() ) {

			die "Pnl size class name: " . $size->GetName() . " has invlaid format" if ( $size->GetName() !~ /^\w+_[2v]v_\d+x\d+$/ );

			# 3) Pnl border + spacing
			foreach my $borderName ( map { $_->GetName() } ( $size->GetBorders() ) ) {

				die "Pnl border/spacing class name: ${borderName} has invlaid format"
				  if ( $borderName !~ /^\w+_[2v]v(_\d+x\d+)?(_\w+)?$/ );
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

sub __GetProductionPnlSpacings {
	my $self = shift;

	my @spacings = ();

	my $spac1 = PnlSpacing->new("Produc_pnl_4,5mm");
	$spac1->SetSpaceX(4.5);
	$spac1->SetSpaceY(4.5);

	push( @spacings, $spac1 );

	my $spac2 = PnlSpacing->new("Produc_pnl_10mm");
	$spac2->SetSpaceX(10);
	$spac2->SetSpaceY(10);

	push( @spacings, $spac2 );

	my $spac3 = PnlSpacing->new("Produc_pnl_15mm");
	$spac3->SetSpaceX(15);
	$spac3->SetSpaceY(15);

	push( @spacings, $spac3 );

	return @spacings;

}

sub __GetCustomerPnlSpacings {
	my $self = shift;

	my @spacings = ();

	my $spac1 = PnlSpacing->new("Customer_pnl_0mm");
	$spac1->SetSpaceX(0);
	$spac1->SetSpaceY(0);

	push( @spacings, $spac1 );

	my $spac2 = PnlSpacing->new("Customer_pnl_2mm");
	$spac2->SetSpaceX(2);
	$spac2->SetSpaceY(2);

	push( @spacings, $spac2 );

	my $spac3 = PnlSpacing->new("Customer_pnl_10mm");
	$spac3->SetSpaceX(10);
	$spac3->SetSpaceY(10);

	push( @spacings, $spac3 );

	return @spacings;

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

