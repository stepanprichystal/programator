
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewer;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Tests::Test';
use aliased 'Packages::Events::Event';
use aliased 'Connectors::TpvConnector::TpvMethods';
use aliased 'Enums::EnumsDrill';
use aliased 'Enums::EnumsGeneral';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcViewerFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilder2V';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderVV';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcViewerMatrix';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';

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
	$self->{"sigLayerSettChangedEvt"} = Event->new();
	$self->{"technologyChangedEvt"}   = Event->new();    # Technology for layer c/s only
	$self->{"etchingChangedEvt"}      = Event->new();    # Tenting for layer c/s only

	return $self;
}

sub BuildForm {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->{"procViewFrm"} = ProcViewerFrm->new( $parent, $inCAM, $jobId );

	my $procViewerBldr;

	if ( $self->{"defaultInfo"}->GetLayerCnt() <= 2 ) {
		my @sigLayers       = $self->{"defaultInfo"}->GetSignalLayers();
		my @boardBaseLayers = $self->{"defaultInfo"}->GetBoardBaseLayers();
		my @pltNClayers     = CamDrilling->GetPltNCLayers( $inCAM, $jobId );

		$procViewerBldr = ProcBuilder2V->new( $inCAM, $jobId );
		$procViewerBldr->Build( $self->{"procViewFrm"}, \@sigLayers, \@boardBaseLayers, \@pltNClayers );
	}
	elsif ( $self->{"defaultInfo"}->GetLayerCnt() > 2 ) {
		my $stackup = $self->{"defaultInfo"}->GetStackup();

		$procViewerBldr = ProcBuilderVV->new( $inCAM, $jobId );
		$procViewerBldr->Build( $self->{"procViewFrm"}, $stackup );

	}

	# Set handlers

	$self->{"procViewFrm"}->{"sigLayerSettChangedEvt"}->Add( sub { $self->__OnlayerSettChangedHndl(@_) } );
	$self->{"procViewFrm"}->{"technologyChangedEvt"}->Add( sub   { $self->__OnTechnologyChangedHndl(@_) } );
	$self->{"procViewFrm"}->{"etchingChangedEvt"}->Add( sub      { $self->__OnTentingChangedHndl(@_) } );

	# Build search matrix
	my @sigLayers    = $self->{"defaultInfo"}->GetSignalLayers();
	my @sigExtLayers = $self->{"defaultInfo"}->GetSignalExtLayers();
	my @allSig       = ( @sigLayers, @sigExtLayers );

	@allSig = () if ( $self->{"defaultInfo"}->GetPcbType() eq EnumsGeneral->PcbType_NOCOPPER );

	$self->{"searchMatrix"}->BuildMatrix( $self->{"procViewFrm"}, \@allSig );

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
	$copperFrm->SetStretchXVal( $l->{"stretchX"} );
	$copperFrm->SetStretchYVal( $l->{"stretchY"} );

	# Update plating at copper row frm
	$copperFrm->UpdatePlating( $l->{"technologyType"} eq EnumsGeneral->Technology_GALVANICS ? 1 : 0 );

	# 2) Set product technology

	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName( $l->{"name"} )->GetSubGroupFrm();
	my $etchType    = $l->{"etchingType"};

	# set tenting
	$subGroupFrm->SetTentingVal( $l->{"etchingType"} );

	# Set technology
	$subGroupFrm->SetTechnologyVal( $l->{"technologyType"} );

}

sub GetLayerValues {
	my $self = shift;

	my @layers = ();

	foreach my $l ( $self->{"searchMatrix"}->GetAllSignalLayers() ) {

		my %linfo = $self->GetLayerValue($l);

		push( @layers, \%linfo );
	}

	return @layers;
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
	$lInfo{"comp"}     = $copperFrm->GetCompVal();
	$lInfo{"stretchX"} = $copperFrm->GetStretchXVal();
	$lInfo{"stretchY"} = $copperFrm->GetStretchYVal();

	$lInfo{"etchingType"}    = $subGroupFrm->GetTentingVal();
	$lInfo{"technologyType"} = $subGroupFrm->GetTechnologyVal();
	return %lInfo;
}

## User can set etching type for layer cs manually
#sub SetTechnologyCS {
#	my $self       = shift;
#	my $technology = shift;
#
#	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();
#
#	$subGroupFrm->SetTechnologyVal($technology);
#}
#
## User can set etching type for layer cs manually
#sub GetTechnologyCS {
#	my $self = shift;
#
#	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();
#
#	return $subGroupFrm->GetTechnologyVal();
#}
#
## User can set etching type for layer cs manually
#sub SetTentingCS {
#	my $self    = shift;
#	my $tenting = shift;
#
#	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();
#
#	$subGroupFrm->SetTentingVal($tenting);
#}
#
## User can set etching type for layer cs manually
#sub GetTentingCS {
#	my $self = shift;
#
#	my $subGroupFrm = $self->{"searchMatrix"}->GetItemByOriName("c")->GetSubGroupFrm();
#
#	return $subGroupFrm->GetTentingVal();
#}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnlayerSettChangedHndl {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	my $lName = JobHelper->BuildSignalLayerName( $copperName, $outerCore, $plugging );

	# 1) Get current layer value
	my %currLSett = $self->GetLayerValue($lName);

	$self->{"sigLayerSettChangedEvt"}->Do( \%currLSett );

	Diag("Copper row changed: $copperName, outer core: $outerCore, plugging: $plugging\n");

}

sub __OnTechnologyChangedHndl {
	my $self        = shift;
	my $productId   = shift;
	my $productType = shift;
	my $technology  = shift;

	Diag("Technology changed. Product Id: $productId, technology: $technology  \n");

	# Change Tenting by technology
	my $mItem = ( $self->{"searchMatrix"}->GetItemsByProduct( $productId, $productType ) )[0];
	my $tentingNew = undef;

	if ( $technology eq EnumsGeneral->Technology_GALVANICS ) {

		if ( $self->{"defaultInfo"}->GetLayerCnt() <= 1 ) {
			$tentingNew = EnumsGeneral->Etching_TENTING;

		}
		else {
			# Set automatically default trenting value
			my %defLSett = $self->{"defaultInfo"}->GetDefSignalLSett( $mItem->GetLayerMatrixProp() );
			$tentingNew = $defLSett{"etchingType"};
		}

	}
	elsif ( $technology ne EnumsGeneral->Technology_GALVANICS ) {

		# Set automatically tenting = resis
		$tentingNew = EnumsGeneral->Etching_ONLY;
	}

	$mItem->GetSubGroupFrm()->SetTentingVal($tentingNew);    # Update GUI
	$self->__OnTentingChangedHndl( $productId, $productType, $tentingNew );    # Riese event in order recompute layer values

	# raise event if tenting change for layer c/s
	if ( $mItem->GetLayerName() =~ /^[cs]$/ ) {

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

		my $isPlt = 1;

		if ( $currLSett{"etchingType"} eq EnumsGeneral->Etching_ONLY || $mItem->GetOuterCore() ) {
			$isPlt = 0;
		}

		my %newSett =
		  $self->{"defaultInfo"}->GetSignalLSett( $mItem->GetLayerMatrixProp(), $isPlt, $currLSett{"etchingType"}, $currLSett{"technologyType"} );

		# 3) Update form

		$self->SetLayerValue( \%newSett );

		# 4) Reise change event

		$self->{"sigLayerSettChangedEvt"}->Do( \%newSett );

		Diag("Technology changed. Product Id: $productId, Layer: $lName,  tenting: $tenting  \n");
	}

	# raise event if tenting change for layer c/s
	if ( scalar( grep { $_->GetLayerName() =~ /^[cs]$/ } @mItems ) ) {

		$self->{"etchingChangedEvt"}->Do($tenting);
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

