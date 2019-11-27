
#-------------------------------------------------------------------------------------------#
# Description: Builder of procedure for 1v +2v PCB
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilder2V;
use base('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::ProcBuilderBase');

use Class::Interface;
&implements('Programs::Exporter::ExportChecker::Groups::PreExport::View::ProcViewer::ProcBuilder::IProcBuilder');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Helpers::JobHelper';
use aliased 'Packages::Stackup::Enums' => 'StackEnums';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	$self = $class->SUPER::new(@_);
	bless $self;
}

sub Build {
	my $self            = shift;
	my $procViewerFrm   = shift;
	my $signalLayers    = shift;
	my $boardBaseLayers = shift;
	my $pltNCLayers     = shift;

	$self->__BuildInputProducts( $procViewerFrm, $signalLayers, $boardBaseLayers, $pltNCLayers );

	$procViewerFrm->HideControls();

}

sub __BuildInputProducts {
	my $self            = shift;
	my $procViewerFrm   = shift;
	my $signalLayers    = shift;
	my $boardBaseLayers = shift;
	my $pltNCLayers     = shift;

	my $pcbType     = JobHelper->GetPcbType( $self->{"jobId"} );
	my $baseCuThick = JobHelper->GetBaseCuThick( $self->{"jobId"} );

	$procViewerFrm->AddCategoryTitle( StackEnums->Product_INPUT, "Base product" );

	my $plugging = scalar( grep { $_->{"gROWname"} =~ /^plg[cs]$/ } @{$boardBaseLayers} ) ? 1 : 0;
	my @pltNC = grep { !$_->{"technical"}} @{$pltNCLayers};

	#	# if coverlays add extra group
	#	if ( scalar( grep { $_->{"gROWlayer_type"} eq "coverlay" } @{$boardBaseLayers} ) ) {
	#
	#		my $subG = $g->AddSubGroup( "1.2", StackEnums->Product_INPUT, \@pltNC );
	#
	#		 # Add TOP coverlay
	#		if ( scalar( grep { $_->{"gROWname"} =~ /^coverlayc$/ } @{$boardBaseLayers} ) ) {
	#
	#			$subG->AddCoverlayRow();
	#
	#		}
	#
	#		# Add Semi product
	#		$subG->AddProductRow( "1.1",    StackEnums->Product_INPUT);
	#
	#		# 1) Add BOT coverlay
	#		if ( scalar( grep { $_->{"gROWlayer_type"} eq "coverlay" && $_->{"gROWname"} =~ /^coverlays$/ } @{$boardBaseLayers} ) ) {
	#
	#			$subG->AddCoverlayRow();
	#		}
	#
	#	}

	return 0 if ( $pcbType eq EnumsGeneral->PcbType_NOCOPPER );

	# Create group
	my $g = $procViewerFrm->AddGroup( 1, StackEnums->Product_INPUT );

	my $subG = $g->AddSubGroup( "1.1", StackEnums->Product_INPUT, \@pltNC );

	# 2) Add TOP copper
 

	$subG->AddCopperRow( "c", 0, 0, 0, $baseCuThick, 1 );
	$subG->AddCopperRow( "c", 0, 1, 0, $baseCuThick, 1 ) if ($plugging);

	# 3) Add core
	$subG->AddCoreRow();

	# 4) Add BOT copper
	if ( scalar( grep { $_->{"gROWname"} =~ /^s$/ } @{$signalLayers} ) ) {

		$subG->AddCopperRow( "s", 0, 1, 0, $baseCuThick, 1 ) if ($plugging);
		$subG->AddCopperRow( "s", 0, 0, 0, $baseCuThick, 1 );

	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

