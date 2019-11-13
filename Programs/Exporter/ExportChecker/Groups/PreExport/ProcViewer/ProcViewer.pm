
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
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::Forms::ProcViewerFrm';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilder2V';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderVV';
use aliased 'Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderRiFlex';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	# PROPERTIES
	$self->{"inCAM"}        = shift;
	$self->{"jobId"}        = shift;
	$self->{"signalLayers"} = shift;
	$self->{"isFlex"}       = shift;
	$self->{"stackup"}      = shift;

	$self->{"procViewFrm"} = undef;

	# EVENTS

	#	$self->{"onLayerSettChanged"} = Event->new();
	#	$self->{"technologyChanged"}  = Event->new();
	#	$self->{"tentingChanged"}     = Event->new();

	return $self;
}

sub BuildForm {
	my $self   = shift;
	my $parent = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	$self->{"procViewFrm"} = ProcViewerFrm->new( $parent, $inCAM, $jobId );

	my $layerCnt = scalar( @{ $self->{"signalLayers"} } );

	my $procViewerBldr;

	if ( $layerCnt <= 2 ) {
		$procViewerBldr = ProcBuilder2V->new( $inCAM, $jobId );
	}
	elsif ( $layerCnt > 2 && !$self->{"isFlex"} ) {
		$procViewerBldr = ProcBuilderVV->new( $inCAM, $jobId );
	}
	elsif ( $layerCnt > 2 && $self->{"isFlex"} ) {
		$procViewerBldr = ProcBuilderRiFlex->new( $inCAM, $jobId );
	}

	$procViewerBldr->Build( $self->{"procViewFrm"}, $self->{"signalLayers"}, $self->{"stackup"} );

	# Set handlers

	$self->{"procViewFrm"}->{"layerSettChangedEvt"}->Add( sub  { $self->__OnlayerSettChangedHndl(@_) } );
	$self->{"procViewFrm"}->{"technologyChangedEvt"}->Add( sub { $self->__OnTechnologyChangedHndl(@_) } );
	$self->{"procViewFrm"}->{"tentingChangedEvt"}->Add( sub    { $self->__OnTentingChangedHndl(@_) } );

	return $self->{"procViewFrm"};

}

sub SetLayers {
	my $self   = shift;
	my $layers = shift;

	die "Form is not built" unless ( defined $self->{"procViewFrm"} );

	foreach my $l ( @{$layers} ) {

		$self->{"procViewFrm"}->SetLayerRow($l);
	}

}

sub GetLayers {
	my $self = shift;

	die "Form is not built" unless ( defined $self->{"procViewFrm"} );

	my @layers = ();

	foreach my $l ( @{ $self->{"signalLayers"} } ) {

		my %linfo = $self->{"procViewFrm"}->GetLayerValues( $l->{"gROWname"} );

		push( @layers, \%linfo );

	}
	return \@layers;

}

#-------------------------------------------------------------------------------------------#
#  Private methods
#-------------------------------------------------------------------------------------------#

sub __OnlayerSettChangedHndl {
	my $self       = shift;
	my $copperName = shift;
	my $outerCore  = shift;
	my $plugging   = shift;

	print STDERR "Copper row changed: $copperName, outer core: $outerCore, plugging: $plugging\n";

}

sub __OnTechnologyChangedHndl {
	my $self       = shift;
	my $productId  = shift;
	my $technology = shift;

	print STDERR "Technology changed. Product Id: $productId, technology: $technology  \n";

}

sub __OnTentingChangedHndl {
	my $self      = shift;
	my $productId = shift;
	my $tenting   = shift;

	print STDERR "Technology changed. Product Id: $productId, tenting: $tenting  \n";

}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

