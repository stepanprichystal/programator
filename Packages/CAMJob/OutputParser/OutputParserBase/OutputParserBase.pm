
#-------------------------------------------------------------------------------------------#
# Description: Prepare NC layers to finla output
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::CAMJob::OutputParser::OutputParserBase::OutputParserBase;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Math::Trig;

#local library
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamHistogram';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputResult::OutputResult';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Packages::CAMJob::OutputParser::OutputParserBase::OutputParser';
use aliased 'Enums::EnumsGeneral';

#-------------------------------------------------------------------------------------------#
#  Interface
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;
	$self->{"step"}  = shift;

	$self->{"results"} = [];

	return $self;
}

sub Prepare {
	my $self  = shift;
	my $layer = shift;    # hash reference
	my $doFinalCheck = shift // 1; # if 0 - final check not run (check if all features in layer was parsed)

	my $inCAM  = $self->{"inCAM"};
	my $jobId  = $self->{"jobId"};
	my $step   = $self->{"step"};
	my $parser = OutputParser->new();

	CamHelper->SetStep( $inCAM, $step );

	# 1) init Layer

	# toto tady musi byt, jinak po tools_set nefunguje spravne shape slot/hole v DTM
	$inCAM->COM( 'tools_show', "layer" => $layer->{"gROWname"} );

	CamDrilling->AddNCLayerType( [$layer] );

	# load UniDTM for layer
	$layer->{"uniDTM"} = UniDTM->new( $inCAM, $jobId, $step, $layer->{"gROWname"}, 0 );

	if ( $layer->{"gROWlayer_type"} eq "rout" ) {

		# load UniRTM
		if ( $layer->{"type"} ne EnumsGeneral->LAYERTYPE_nplt_score ) {
			$layer->{"uniRTM"} = UniRTM->new( $inCAM, $jobId, $step, $layer->{"gROWname"}, 0, $layer->{"uniDTM"} );
		}
	}

	# 2) Backup ori layer
	my $backUp = $self->_BackupLayer( $layer->{"gROWname"} );

	# 3) Init parser and parse layer
	$self->InitParser( $layer, $parser );

	my @results = $parser->Parse();

	# 4) Final check
	if ( $doFinalCheck && !$self->_FinalCheck($layer) ) {

		die "NC output data - Layer was not fully parsed: " . $layer->{"gROWname"};
	}
	 

	$self->_RestoreBackupLayer( $layer, $backUp );
	 

	my $result = OutputResult->new( $inCAM, $jobId, $step, $layer, 1, \@results );

	# store reuslt
	push( @{ $self->{"results"} }, $result );

	return $result;
}

sub InitParser {
	my $self   = shift;
	my $l      = shift;
	my $parser = shift;

	die "Method has to be overriden by inherit class";

}

#-------------------------------------------------------------------------------------------#
#  Protected methods
#-------------------------------------------------------------------------------------------#

sub _BackupLayer {
	my $self     = shift;
	my $oriLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my $workLayer = GeneralHelper->GetGUID();

	$inCAM->COM(
				 'copy_layer',
				 "source_job"   => $jobId,
				 "source_step"  => $step,
				 "source_layer" => $oriLayer,
				 "dest"         => 'layer_name',
				 "dest_layer"   => $workLayer,
				 "mode"         => 'replace',
				 "invert"       => 'no'
	);

	return $workLayer;

}

sub _RestoreBackupLayer {
	my $self        = shift;
	my $layer       = shift;
	my $backupLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# clear ori layer before restoring
	CamLayer->WorkLayer( $inCAM, $layer->{"gROWname"} );
	CamLayer->DeleteFeatures($inCAM);

	# Restore backup layer
	$inCAM->COM(
				 'copy_layer',
				 "source_job"   => $jobId,
				 "source_step"  => $step,
				 "source_layer" => $backupLayer,
				 "dest"         => 'layer_name',
				 "dest_layer"   => $layer->{"gROWname"},
				 "mode"         => 'replace',
				 "invert"       => 'no'
	);

	CamMatrix->DeleteLayer( $inCAM, $jobId, $backupLayer );

}

# Remove all layers used in result
sub _FinalCheck {
	my $self        = shift;
	my $layer       = shift;
	my $backupLayer = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	my %hist = CamHistogram->GetFeatuesHistogram( $inCAM, $jobId, $step, $layer->{"gROWname"} );
	my %symHist = CamHistogram->GetSymHistogram( $inCAM, $jobId, $step, $layer->{"gROWname"}, 1, 1 );

	my $featsLeftCnt = $hist{"total"};

	# all feats cnt - r0 pads cnt
	if ( defined $symHist{"pads"}->{"r0"} && $layer->{"gROWlayer_type"} eq "rout" ) {

		$featsLeftCnt -= $symHist{"pads"}->{"r0"};
	}

	if ( $featsLeftCnt == 0 ) {

		return 1;
	}
	else {

		return 0;
	}
}

# Remove all layers used in result
sub Clear {
	my $self   = shift;
	my $result = shift;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};
	my $step  = $self->{"step"};

	# We have to clear layers in other case InCAM message (Drilll size vwill be recalculated) 
	# will be showed during delete layer
	$inCAM->COM('clear_layers');

	foreach my $resultL ( @{ $self->{"results"} } ) {

		$resultL->Clear();

	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#	use aliased 'Packages::CAMJob::OutputParser::OutputParserNC::OutputParserNC';
	#
	#	use aliased 'Packages::InCAM::InCAM';
	#
	#	my $inCAM = InCAM->new();
	#
	#	my $jobId = "f52456";
	#
	#	my $mess = "";
	#
	#	my $control = OutputParserNC->new( $inCAM, $jobId, "data_o+1" );
	#
	#	my %lInfo = ( "gROWname" => "f", "gROWlayer_type" => "rout" );
	#
	#	my $result = $control->Prepare( \%lInfo );
	#
	#	$control->Clear();

}

1;
