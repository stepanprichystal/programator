
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewer;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Events::Event';
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Enums::EnumsDrill';
use aliased 'Enums::EnumsGeneral';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcViewerFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilder2V';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderVV';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderRiFlex';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewerMatrix';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES
	$self->{"inCAM"}       = shift;
	$self->{"jobId"}       = shift;
	$self->{"defaultInfo"} = shift;

	$self->{"procViewFrm"} = undef;

	$self->{"searchMatrix"} = ProcViewerMatrix->new();

	# EVENTS
	$self->{"layerSettChangedEvt"}  = Event->new();
	$self->{"technologyChangedEvt"} = Event->new();    # Technology for layer c/s only
	$self->{"tentingChangedEvt"}    = Event->new();    # Tenting for layer c/s only

	return $self;
}

sub BuildForm {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->{"procViewFrm"} = ProcViewerFrm->new( $parent, $inCAM, $jobId );

	
	my @sigLayers = $self->{"defaultInfo"}->GetSignalLayers();
	my $isFlex    = $self->{"defaultInfo"}->GetIsFlex();
	my $stackup   = $self->{"defaultInfo"}->GetStackup();
	my $layerCnt  = scalar(@sigLayers );

	my $procViewerBldr;

	if ( $layerCnt <= 2 ) {
		$procViewerBldr = ProcBuilder2V->new( $inCAM, $jobId );
	}
	elsif ( $layerCnt > 2 && !$isFlex ) {
		$procViewerBldr = ProcBuilderVV->new( $inCAM, $jobId );
	}
	elsif ( $layerCnt > 2 && $isFlex ) {
		$procViewerBldr = ProcBuilderRiFlex->new( $inCAM, $jobId );
	}

	$procViewerBldr->Build( $self->{"procViewFrm"}, \@sigLayers, $stackup );

	# Set handlers

	$self->{"procViewFrm"}->{"layerSettChangedEvt"}->Add( sub  { $self->__OnlayerSettChangedHndl(@_) } );
	$self->{"procViewFrm"}->{"technologyChangedEvt"}->Add( sub { $self->__OnTechnologyChangedHndl(@_) } );
	$self->{"procViewFrm"}->{"tentingChangedEvt"}->Add( sub    { $self->__OnTentingChangedHndl(@_) } );

	# Build search matrix
	$self->{"searchMatrix"}->BuildMatrix($self->{"procViewFrm"}, \@sigLayers );

	return $self->{"procViewFrm"};
}

sub SetLayerValues {
	my $self   = shift;
	my $layers = shift;

	die "Form is not built" unless ( defined $self->{"procViewFrm"} );

	foreach my $l ( @{$layers} ) {

		$self->SetLayerValue($l);
	}
}

sub SetLayerValue {
	my $self = shift;
	my $l    = shift;

	die "Form is not built" unless ( defined $self->{"procViewFrm"} );

	# 1) Set layer values
	my $copperFrm = $self->{"searchMatrix"}->GetItemByOriName( $l->{"name"} )->GetRowCopperFrm();

	$copperFrm->SetPolarityVal( $l->{"polarity"} );
	$copperFrm->SetMirrorVal( $l->{"mirror"} );
	$copperFrm->SetCompVal( $l->{"comp"} );
	$copperFrm->SetShrinkXVal( $l->{"shrinkX"} );
	$copperFrm->SetShrinkYVal( $l->{"shrinkY"} );

	$self->{"procViewFrm"}->SetLayerRow($l);

	# 2) Set product technology

	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName( $l->{"name"} )->GetSubGroupFrm();
	my $etchType    = $l->{"etchingType"};

	# set tenting
	$subGroupFrm->SetTenting( $l->{"etchingType"} );

	# Set technology
	$subGroupFrm->SetTechnology( $l->{"technologyType"} );
	
	# Update plating
	
	$subGroupFrm->UpdatePlating($l->{"technologyType"} eq EnumsGeneral->Technology_GALVANICS ? 1 : 0);

}

sub GetLayerValues {
	my $self = shift;

	my @layers = ();

	foreach my $l ( @{ $self->{"signalLayers"} } ) {

		my %linfo = $self->GetLayerValue( $l->{"gROWname"} );

		push( @layers, \%linfo );
	}

	return \@layers;
}

sub GetLayerValue {
	my $self  = shift;
	my $lname = shift;

	die "Form is not built" unless ( defined $self->{"procViewFrm"} );

	my $copperFrm   = $self->{"searchMatrix"}->GetItemByOriName($lname)->GetRowCopperFrm();
	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName($lname)->GetSubGroupFrm();

	my %lInfo = ();

	$lInfo{"name"} = $lname;

	$lInfo{"polarity"} = $copperFrm->GetPolarityVal();
	$lInfo{"mirror"}   = $copperFrm->GetMirrorVal();
	$lInfo{"comp"}     = $copperFrm->SetCompVal();
	$lInfo{"shrinkX"}  = $copperFrm->SetShrinkXVal();
	$lInfo{"shrinkY"}  = $copperFrm->SetShrinkYVal();

	$lInfo{"etchingType"}    = $subGroupFrm->GetTentingVal();
	$lInfo{"technologyType"} = $subGroupFrm->GetTechnologyVal();

	return %lInfo;
}

# User can set etching type for layer cs manually
sub SetTechnologyS {
	my $self       = shift;
	my $technology = shift;

	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();

	$subGroupFrm->SetTechnologyVal($technology);
}

# User can set etching type for layer cs manually
sub GetTechnologyCS {
	my $self = shift;

	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();

	return $subGroupFrm->GetTechnologyVal();
}

# User can set etching type for layer cs manually
sub SetTentingCS {
	my $self    = shift;
	my $tenting = shift;

	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();

	$subGroupFrm->SetTentingVal($tenting);
}

# User can set etching type for layer cs manually
sub GetTentingCS {
	my $self = shift;

	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();

	return $subGroupFrm->GetTentingVal();
}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnlayerSettChangedHndl {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	my $lName = $self->{"searchMatrix"}->BuildCopperLayerName( $copperName, $outerCore, $plugging );

	# 1) Get current layer value
	my %currLSett = $self->GetLayerValue($lName);

	$self->{"layerSettChangedEvt"}->Do( \%currLSett );

	print STDERR "Copper row changed: $copperName, outer core: $outerCore, plugging: $plugging\n";

}

sub __OnTechnologyChangedHndl {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;
	my $technology  = shift;

	print STDERR "Technology changed. Product Id: $productId, technology: $technology  \n";

	# Get affected layers
	my @mItems = $self->{"searchMatrix"}->GetItemsByProduct( $productId, $productType );

	foreach my $mItem (@mItems) {

		my $lName      = $mItem->GetLayerName();
		my $tentingNew = undef;

		if ( $technology eq EnumsGeneral->Technology_GALVANICS ) {

			# Set automatically default trenting value

			my %defLSett = $self->{"defaultInfo"}->GetDefSignalLSett( $mItem->GetMatrixProp() );
			$tentingNew = $defLSett{"etchingType"}
		}
		elsif ( $technology ne EnumsGeneral->Technology_GALVANICS ) {

			# Set automatically tenting = resis
			$tentingNew = EnumsGeneral->Etching_ONLY;
		}

		$mItem->GetSubGroupFrm()->SetTenting($tentingNew);    # Update GUI
		$self->__OnTentingChangedHndl( $productId, $productType, $tentingNew );    # Riese event in order recompute layer values

	}

	# raise event if tenting change for layer c/s
	if ( scalar( grep { $_->GetLayerName() =~ /^[cs]$/ } @mItems ) ) {

		$self->{"technologyChangedEvt"}->Do($technology);
	}
}

sub __OnTentingChangedHndl {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;
	my $tenting     = shift;

	# Get affected layers
	my @mItems = $self->{"searchMatrix"}->GetItemsByProduct( $productId, $productType );

	#  Recompute copper layer values
	my @layers = ();

	foreach my $mItem (@mItems) {

		my $lName = $mItem->GetLayerName();

		# 1) Get current layer value
		my %currLSett = $self->GetLayerValue($lName);

		# 2) Recompute settings

		my $isPlt = $currLSett{"technology"} eq EnumsGeneral->Technology_GALVANICS ? 1 : 0;

		my %newSett = $self->{"defaultInfo"}->GetSignalLSett( $lName, $isPlt, $currLSett{"etchingType"}, $currLSett{"technologyType"} );

		# 3) Update form

		$self->SetLayerValue( \%newSett );

		# 4) Reise change event

		$self->{"layerSettChangedEvt"}->Do( \%newSett );

		print STDERR "Technology changed. Product Id: $productId, Layer: $lName,  tenting: $tenting  \n";
	}

	# raise event if tenting change for layer c/s
	if ( scalar( grep { $_->GetLayerName() =~ /^[cs]$/ } @mItems ) ) {

		$self->{"tentingChangedEvt"}->Do($tenting);
	}
}

sub __SeLayerValue {
	my $self  = shift;
	my $lSett = shift;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

