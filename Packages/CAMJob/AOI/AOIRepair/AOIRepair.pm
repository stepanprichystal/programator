#-------------------------------------------------------------------------------------------#
# Description: Crate new job intended for AOI EXPORT
# Reduce job to necessary minimum and output OPFX for aoi
# Source job data are copied layer by layer to new jon D<xxxxxx>_OT<\d>
# This should be prevention for locking OPFX data during processing on server
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::AOI::AOIRepair::AOIRepair;
use base('Packages::ItemResult::ItemEventMngr');

#3th party library
use strict;
use warnings;
use utf8;
use List::Util qw[max min];
use List::Util qw(first);
use File::Basename;
use File::Copy;

#local library
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Widgets::Forms::SimpleInput::SimpleInputFrm';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamAttributes';
use aliased 'CamHelpers::CamMatrix';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamStepRepeatPnl';
use aliased 'CamHelpers::CamStep';
use aliased 'CamHelpers::CamLayer';
use aliased 'CamHelpers::CamDrilling';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';
use aliased 'Helpers::GeneralHelper';

use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Managers::MessageMngr::MessageMngr';
use aliased 'Packages::ProductionPanel::StandardPanel::StandardBase';
use aliased 'Packages::CAMJob::Panelization::SRStep';
use aliased 'Packages::AOTesting::ExportOPFX::ExportOPFX';

#-------------------------------------------------------------------------------------------#
#  Script methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	bless $self;

	$self->{"inCAM"}         = shift;
	$self->{"jobIdSrc"}      = shift;
	$self->{"AOIattemptCnt"} = shift // 20;    # Number of attempt to AOI subszstem

	return $self;
}

# Generate new job name in format D<xxxxxx>_ot<\d>
# Trzy to find job with last _ot number
sub GenerateJobName {
	my $self     = shift;
	my $jobIdSrc = $self->{"jobIdSrc"};

	my @dirs = FileHelper->GetFilesNameByPattern( EnumsPaths->Jobs_AOITESTSFUSIONDB, $jobIdSrc );
	my $IDx = max( grep { defined $_ } map { ( $_ =~ m/\w\d+_ot(\d+)/i )[0] } @dirs );
	$IDx = 1 if ( !defined $IDx );
	my $jobIdOut = $jobIdSrc . "_ot" . ( $IDx + 1 );

	return $jobIdOut;
}

# Create Repaired / cleaned job and export AOI
sub CreateAOIRepairJob {
	my $self = shift;

	my $jobIdOut    = shift;
	my @layersUsr   = @{ shift(@_) };
	my $OPFXPath    = shift;
	my $send2server = shift // 0;

	my $reduceSteps = shift // 0;
	my $countoruL   = shift // 0;
	my $resizeL     = shift // 0;
	my $delAttrL    = shift // 0;

	die "No layers defined " unless ( scalar(@layersUsr) );
	die "OPFX path not defined " unless ( defined $OPFXPath );

	my $inCAM    = $self->{"inCAM"};
	my $jobIdSrc = $self->{"jobIdSrc"};

	# 1) Create job and output OPFX

	CamJob->DeleteJob( $inCAM, $jobIdOut ) if ( CamJob->JobExist( $inCAM, $jobIdOut ) );
	CamJob->CreateJob( $inCAM, $jobIdOut );

	CamJob->CloseJob( $inCAM, $jobIdOut );    # Close we want another window with editor
	CamJob->CheckOutJob( $inCAM, $jobIdOut );

	# Set job attributes
	CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );    # Set source job contextOut
	my %srcJobAttr = CamAttributes->GetJobAttr( $inCAM, $jobIdSrc );

	CamHelper->OpenJob( $inCAM, $jobIdOut, 0 );    # Set output job contextOut
	CamHelper->OpenStep( $inCAM, $jobIdOut, "o" ); # only existing step in new job (set context for scripts)
	CamAttributes->SetJobAttribute( $inCAM, $jobIdOut, "user_name",       $srcJobAttr{"user_name"} );
	CamAttributes->SetJobAttribute( $inCAM, $jobIdOut, "pcb_class",       $srcJobAttr{"pcb_class"} );
	CamAttributes->SetJobAttribute( $inCAM, $jobIdOut, "pcb_class_inner", $srcJobAttr{"pcb_class_inner"} );
	CamMatrix->CreateLayer( $inCAM, $jobIdOut, "o", "document", "positive", 0 );

	# Create step structure
	#my %contextSrc = ();
	#my %contextOut = ();

	# Nested steps
	if ( !$reduceSteps ) {

		CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );    # Set source job contextOut
		my @srcSteps = CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobIdSrc );

		foreach my $srcS (@srcSteps) {

			# Get information from source job at once
			CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );    # Set source job contextOut
			CamHelper->OpenStep( $inCAM, $jobIdSrc, $srcS->{"stepName"} );

			my %datumSrc = CamStep->GetDatumPoint( $inCAM, $jobIdSrc, $srcS->{"stepName"}, 1 );

			CamHelper->OpenJob( $inCAM, $jobIdOut, 0 );    # Set output job contextOut
			CamStep->CreateStep( $inCAM, $jobIdOut, $srcS->{"stepName"} );    # create step
			CamHelper->OpenStep( $inCAM, $jobIdOut, $srcS->{"stepName"} );

			CamStep->SetDatumPoint( $inCAM, $srcS->{"stepName"}, $datumSrc{"x"}, $datumSrc{"y"} );    # Set Datum point

			# create step
			CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );
			CamHelper->OpenStep( $inCAM, $jobIdSrc, $srcS->{"stepName"} );                            # Set source job contextOut

			my $profL = GeneralHelper->GetGUID();
			CamStep->ProfileToLayer( $inCAM, $srcS->{"stepName"}, $profL, 200 );
			CamLayer->WorkLayer( $inCAM, $profL );
			$inCAM->COM( "sel_buffer_copy", "x_datum" => 0, "y_datum" => 0 );

			CamHelper->OpenJob( $inCAM, $jobIdOut, 0 );
			CamHelper->OpenStep( $inCAM, $jobIdOut, $srcS->{"stepName"} );                            # Set source job contextOut

			CamLayer->WorkLayer( $inCAM, "o" );
			$inCAM->COM( "sel_buffer_paste", "x" => 0, "y" => 0 );
			$inCAM->COM('sel_all_feat');
			$inCAM->COM( 'sel_create_profile', 'create_profile_with_holes' => 'yes' );

			CamHelper->OpenJob( $inCAM, $jobIdSrc,1 );  # Open in editor, unless delete not work
			CamHelper->OpenStep( $inCAM, $jobIdSrc, $srcS->{"stepName"} );
			CamMatrix->DeleteLayer( $inCAM, $jobIdSrc, $profL );

		}
	}

	# Panel step
	CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );    # Set source job contextOut
	CamHelper->OpenStep( $inCAM, $jobIdSrc, "panel" );    # Set source job contextOut

	my $scrPnl = StandardBase->new( $inCAM, $jobIdSrc );

	CamHelper->OpenJob( $inCAM, $jobIdOut, 0 );           # Set output job contextOut

	my $SRStep = SRStep->new( $inCAM, $jobIdOut, "panel" );
	$SRStep->Create( $scrPnl->W(), $scrPnl->H(),
					 ( $scrPnl->H() - $scrPnl->HArea() ) / 2,
					 ( $scrPnl->H() - $scrPnl->HArea() ) / 2,
					 ( $scrPnl->W() - $scrPnl->WArea() ) / 2,
					 ( $scrPnl->W() - $scrPnl->WArea() ) / 2 );
	CamHelper->OpenStep( $inCAM, $jobIdOut, "panel" );

	# Set step structure
	if ( !$reduceSteps ) {

		CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );    # Set source job contextOut
		my @nestSteps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobIdSrc );

		foreach my $step ( @nestSteps, "panel" ) {
			CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );    # Set source job contextOut
			my @repeats = CamStepRepeat->GetStepAndRepeat( $inCAM, $jobIdSrc, $step );
			@repeats = grep { $_->{"stepName"} !~ /coupon/i } @repeats;

			next if ( !scalar(@repeats) );

			CamHelper->OpenJob( $inCAM, $jobIdOut, 0 );    # Set source job contextOut
			CamHelper->OpenStep( $inCAM, $jobIdOut, $step );    # Set source job contextOut
			                                                    #CamHelper->SetGroupId( $inCAM, $contextOut{ $step->{"stepName"} } );

			my $outStep = SRStep->new( $inCAM, $jobIdOut, $step );

			foreach my $r (@repeats) {
				$outStep->AddSRStep( $r->{"stepName"}, $r->{"gSRxa"}, $r->{"gSRya"}, $r->{"gSRangle"},
									 $r->{"gSRnx"},    $r->{"gSRny"}, $r->{"gSRdx"}, $r->{"gSRdy"} );
			}
		}
	}

	# Copy layers

	my @steps = ("panel");

	if ( !$reduceSteps ) {

		my @nestSteps = map { $_->{"stepName"} } CamStepRepeatPnl->GetUniqueNestedStepAndRepeat( $inCAM, $jobIdSrc );
		push( @steps, @nestSteps );
	}

	# Add necessary NC layers
	my @sigL =
	  grep { $_->{"gROWlayer_type"} =~ /(signal)|(power_ground)|(mixed)/i } CamJob->GetBoardLayers( $inCAM, $jobIdSrc );

	my @NCL = CamDrilling->GetNCLayersByTypes(
											   $inCAM,
											   $jobIdSrc,
											   [
												  EnumsGeneral->LAYERTYPE_plt_nDrill,        EnumsGeneral->LAYERTYPE_plt_bDrillTop,
												  EnumsGeneral->LAYERTYPE_plt_bDrillBot,     EnumsGeneral->LAYERTYPE_plt_nFillDrill,
												  EnumsGeneral->LAYERTYPE_plt_bFillDrillTop, EnumsGeneral->LAYERTYPE_plt_bFillDrillBot,
												  EnumsGeneral->LAYERTYPE_plt_cDrill,        EnumsGeneral->LAYERTYPE_plt_cFillDrill,
												  EnumsGeneral->LAYERTYPE_plt_nMill,         EnumsGeneral->LAYERTYPE_plt_bMillTop,
												  EnumsGeneral->LAYERTYPE_plt_bMillBot
											   ]
	);
	CamDrilling->AddLayerStartStop( $inCAM, $jobIdSrc, \@NCL );

	CamHelper->OpenJob( $inCAM, $jobIdOut, 0 );    # Set output job contextOut
	CamHelper->OpenStep( $inCAM, $jobIdOut, "panel" );    # Switch to step o+1 in order set group

	my @lToCreate = ( @sigL, @NCL );

	foreach my $l (@lToCreate) {

		# set attributes layer side

		#my $srcL = first { $_->{"gROWname"} eq $l->{"gROWname"} } @lToCreate;
		CamMatrix->CreateLayer( $inCAM, $jobIdOut, $l->{"gROWname"}, $l->{"gROWlayer_type"}, $l->{"gROWpolarity"}, 1 );

		if ( defined $l->{"type"} ) {
			CamMatrix->SetNCLayerStartEnd( $inCAM, $jobIdOut, $l->{"gROWname"}, $l->{"NCSigStart"}, $l->{"NCSigEnd"} );
		}

		# Get panel layer attributes
		if ( !defined $l->{"type"} ) {
			my %srcLAtt = CamAttributes->GetLayerAttr( $inCAM, $jobIdSrc, "panel", $l->{"gROWname"} );
			CamAttributes->SetLayerAttribute( $inCAM, "layer_side",  $srcLAtt{"layer_side"},  $jobIdOut, "panel", $l->{"gROWname"} );
			CamAttributes->SetLayerAttribute( $inCAM, ".cdr_mirror", $srcLAtt{".cdr_mirror"}, $jobIdOut, "panel", $l->{"gROWname"} );

		}
	}

	my @lUsr = map { { "gROWname" => $_ } } @layersUsr;
	my @lToFill = ( @lUsr, @NCL );

	foreach my $step (@steps) {

		# Open source step

		foreach my $l (@lToFill) {

			CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );
			CamHelper->OpenStep( $inCAM, $jobIdSrc, $step );    # Set source job contextOut
			                                                    #CamHelper->SetGroupId( $inCAM, $contextSrc{$step} );

			# Flatten layer
			my $srcL = $l->{"gROWname"};
			if ($reduceSteps) {
				$srcL = GeneralHelper->GetGUID();
				$inCAM->COM( 'flatten_layer', "source_layer" => $l->{"gROWname"}, "target_layer" => $srcL );
			}

			# Copz over buffer to avoid copyng mess with matrix layer
			CamHelper->OpenJob( $inCAM, $jobIdSrc, 0 );
			CamHelper->OpenStep( $inCAM, $jobIdSrc, $step );    # Set source job contextOut
			CamLayer->WorkLayer( $inCAM, $srcL );
			$inCAM->COM('sel_all_feat');
			if ( CamLayer->GetSelFeaturesCnt($inCAM) ) {
				$inCAM->COM( "sel_buffer_copy", "x_datum" => 0, "y_datum" => 0 );

				CamHelper->OpenJob( $inCAM, $jobIdOut, 0 );
				CamHelper->OpenStep( $inCAM, $jobIdOut, $step );    # Set source job contextOut

				CamLayer->WorkLayer( $inCAM, $l->{"gROWname"} );
				$inCAM->COM( "sel_buffer_paste", "x" => 0, "y" => 0 );
			}

			if ($reduceSteps) {
				CamHelper->OpenJob( $inCAM, $jobIdSrc, 1 ); # Open in editor uinless delete  layer not work
				CamHelper->OpenStep( $inCAM, $jobIdSrc, $step );    # Set source job contextOut
				CamMatrix->DeleteLayer( $inCAM, $jobIdSrc, $srcL )  # remove flaten layer
			}

		}

		# Do operation according user settings
		CamHelper->OpenJob( $inCAM, $jobIdOut, 1 );
		CamHelper->OpenStep( $inCAM, $jobIdOut, $step );            # Set source job contextOut
		CamLayer->AffectLayers( $inCAM, \@layersUsr );

		if ($resizeL) {

			CamLayer->ResizeFeatures( $inCAM, $resizeL );
		}

		if ($delAttrL) {
			$inCAM->COM( "sel_delete_atr", "mode" => "all" );
		}

		if ($countoruL) {

			$inCAM->COM(
						 "sel_contourize",
						 "accuracy"         => "6.35",
						 "break_to_islands" => "yes"
			);
		}

	}

	# Output layers

	my $export = ExportOPFX->new( $inCAM, $jobIdOut, "panel", $self->{"AOIattemptCnt"}, 1 );
	$export->{"onItemResult"}->Add( sub { $self->_OnItemResult(@_) } );

	# AOI subszstem can raise editor error, when there is no free license, so upress
	$inCAM->SupressToolkitException(1);
	$export->Export( $OPFXPath, \@layersUsr, 0 );
	$inCAM->SupressToolkitException(0);

	CamJob->SaveJob( $inCAM, $jobIdOut );
	CamJob->CheckInJob( $inCAM, $jobIdOut );
	CamJob->CloseJob( $inCAM, $jobIdOut );    # Close we want another window with editor

	# Copy to server
	if ($send2server) {

		foreach my $layer (@layersUsr) {

			my @aoiFile = FileHelper->GetFilesNameByPattern( $OPFXPath, "$jobIdOut@" . "$layer" );

			if ( scalar(@aoiFile) ) {

				my $dest = EnumsPaths->Jobs_AOITESTSFUSION . ( fileparse( $aoiFile[0] ) )[0];

				unless ( copy( $aoiFile[0], $dest ) ) {
					die "Unable to copy AOI test $aoiFile[0] to server\n";
				}
			}
		}
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
