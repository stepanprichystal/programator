#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains calculation for drilling
# Author: SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamDrilling;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamMatrix';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return minimal hole tool for given layer and layer type
# Type EnumsGeneral->LAYERTYPE
sub GetMinHoleTool {

	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layertype = shift;
	my $fromLayer = shift;    #tell, only drill layers starts from <$fromLayer> will be considered

	my @layers = $self->GetNCLayersByType( $inCAM, $jobId, $layertype );
	$self->AddLayerStartStop( $inCAM, $jobId, \@layers );

	my $minTool;

	#filter layer, which go from <$fromLayer>
	if ($fromLayer) {
		@layers = grep { $_->{"gROWdrl_start_name"} eq $fromLayer } @layers;
	}

	foreach my $layer (@layers) {

		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'layer',
					  entity_path => "$jobId/$stepName/" . $layer->{"gROWname"},
					  data_type   => 'TOOL',
					  parameters  => 'drill_size+shape',
					  options     => "break_sr"
		);
		my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
		my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

		for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

			my $t = $toolSize[$i];
			my $s = $toolShape[$i];
			if ( $s eq 'hole' ) {

				if ( !defined $minTool || $t < $minTool ) {
					$minTool = $t;
				}

			}

		}
	}

	return $minTool;
}

#Return minimal hole tool for given layers
sub GetMinHoleToolByLayers {

	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $stepName = shift;
	my @layers   = @{ shift(@_) };

	my $minTool;

	foreach my $layer (@layers) {

		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'layer',
					  entity_path => "$jobId/$stepName/" . $layer->{"gROWname"},
					  data_type   => 'TOOL',
					  parameters  => 'drill_size+shape',
					  options     => "break_sr"
		);
		my @toolSize  = @{ $inCAM->{doinfo}{gTOOLdrill_size} };
		my @toolShape = @{ $inCAM->{doinfo}{gTOOLshape} };

		for ( my $i = 0 ; $i < scalar(@toolSize) ; $i++ ) {

			my $t = $toolSize[$i];
			my $s = $toolShape[$i];
			if ( $s eq 'hole' ) {

				if ( !defined $minTool || $t < $minTool ) {
					$minTool = $t;
				}

			}

		}
	}

	return $minTool;
}

#Return if layer given type exist
# Type EnumsGeneral->LAYERTYPE
sub NCLayerExists {

	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;
	my $type    = shift;

	my $exist = 0;
	my @layers = $self->GetNCLayersByType( $inCAM, $jobName, $type );

	if ( scalar(@layers) ) {
		$exist = 1;
	}

	return $exist;
}

#Return all layer by given type
# Type EnumsGeneral->LAYERTYPE
sub GetNCLayersByType {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;
	my $type    = shift;

	my @layers = CamJob->GetBoardLayers( $inCAM, $jobName );

	@layers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;

	$self->AddNCLayerType( \@layers );

	my @res = grep { $_->{"type"} eq $type } @layers;

	return @res;
}

#Return all layer by given types
sub GetNCLayersByTypes {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;
	my $types   = shift;

	my @layers = CamJob->GetBoardLayers( $inCAM, $jobName );

	@layers = grep { $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" } @layers;

	$self->AddNCLayerType( \@layers );

	my %tmp;
	@tmp{ @{$types} } = ();

	@layers = grep { exists $tmp{ $_->{"type"} } } @layers;

	return @layers;
}

# Add  to every hash in array new value: type
# Type is assign by our rules, which ve use wehen proscess pcb
# Plated tells, if holes/slots in layer are plated or not
# Input is array of hash references
sub AddNCLayerType {
	my $self   = shift;
	my $layers = shift;

	#my @res = ();

	foreach my $l ( @{$layers} ) {

		unless ($l) { next; }

		# Plated NC layers

		my %i = ();
		if ( $l->{"gROWname"} =~ /^m[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_nDrill;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^sc[0-9]+$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_bDrillTop;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^ss[0-9]+$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_bDrillBot;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^mfill[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_nFillDrill;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^scfill[0-9]+$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_bFillDrillTop;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^ssfill[0-9]+$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_bFillDrillBot;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^j[0-9]+$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_cDrill;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^r[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_nMill;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^rzc[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_bMillTop;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^rzs[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_bMillBot;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^v$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_fDrill;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^v1$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_fcDrill;
			$l->{"plated"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^dc$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_plt_dcDrill;
			$l->{"plated"} = 1;
		}

		# Non plated NC layers
		elsif ( $l->{"gROWname"} =~ /^d[0-9]*$/ || $l->{"gROWname"} =~ /^fsch_d$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_nDrill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^f[0-9]*$/ || $l->{"gROWname"} =~ /^f(sch)?(lm)?$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_nMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fzc[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_bMillTop;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fzs[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_bMillBot;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^rs[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_rsMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fr[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_frMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^score$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_score;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^jfzc[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_cbMillTop;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^jfzs[0-9]*$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_cbMillBot;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fk$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_kMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^flc$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_lcMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fls$/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_lsMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^f_.*/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_fMillSpec;
			$l->{"plated"} = 0;
		}

		# new for flexi
		elsif ( $l->{"gROWname"} =~ /^fcoverlayc.*/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_cvrlycMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fcoverlays.*/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_cvrlysMill;
			$l->{"plated"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fprepreg.*/ ) {

			$l->{"type"}   = EnumsGeneral->LAYERTYPE_nplt_prepregMill;
			$l->{"plated"} = 0;
		}

	}

	#return @res;
}

# Return info about NC layer
sub GetNCLayerInfo {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $layer = shift;

	# Add key: type
	# Add key: plated
	my $ncType = shift // 0;

	# Add key: gROWlayer_type
	my $matrixType = shift // 0;

	# Add key: gROWdrl_start_name, gROWdrl_end_name
	# Add key: gROWdrl_start, gROWdrl_end
	# Add key: gROWdrl_dir
	my $startStop = shift // 0;

	my %lInfo = ( "gROWname" => $layer );

	if ($ncType) {
		$self->AddNCLayerType( [ \%lInfo ] );
		die "Key: \"type\" was not set"   unless ( defined $lInfo{"type"} );
		die "Key: \"plated\" was not set" unless ( defined $lInfo{"plated"} );
	}
	if ($matrixType) {
		$lInfo{"gROWlayer_type"} = CamMatrix->GetLayerType( $inCAM, $jobId, $layer );
		die "Key: \"gROWlayer_type\"  was not set" unless ( defined $lInfo{"gROWlayer_type"} );
	}

	if ($startStop) {
		$self->AddLayerStartStop( $inCAM, $jobId, [ \%lInfo ] );
		die "Key: \"gROWdrl_start_name\"  was not set" unless ( defined $lInfo{"gROWdrl_start_name"} );
		die "Key: \"gROWdrl_end_name\"  was not set"   unless ( defined $lInfo{"gROWdrl_end_name"} );
		die "Key: \"gROWdrl_start\"  was not set"      unless ( defined $lInfo{"gROWdrl_start"} );
		die "Key: \"gROWdrl_end\"  was not set"        unless ( defined $lInfo{"gROWdrl_end"} );
		die "Key: \"gROWdrl_dir\"  was not set"        unless ( defined $lInfo{"gROWdrl_dir"} );
	}

	return %lInfo;
}

# return all plated NC layers
# Result: array of hash references
sub GetPltNCLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @layers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );
	$self->AddNCLayerType( \@layers );

	my @pltLayers = grep { $_->{"plated"} && $_->{"type"} } @layers;

	return @pltLayers;

}

# return all nonplated NC layers
# Result: array of hash references
sub GetNPltNCLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @layers = ( CamJob->GetLayerByType( $inCAM, $jobId, "drill" ), CamJob->GetLayerByType( $inCAM, $jobId, "rout" ) );
	$self->AddNCLayerType( \@layers );

	my @npltLayers = grep { !$_->{"plated"} && $_->{"type"} } @layers;

	return @npltLayers;

}

# Add  to every hash in array new value:
# {"gROWdrl_start_name"}  - which lazer drilling start from (we consider only signal layers)
# {"gROWdrl_end_name"} - which layer drilling end in (we consider only signal layers)
# {"gROWdrl_start"}  - layer number
# {"gROWdrl_end"}   - layer number
sub AddLayerStartStop {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $layers = shift;    #specify layers

	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

	my @arr = ();

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'matrix',
				  entity_path     => "$jobId/matrix",
				  data_type       => 'ROW',
				  parameters      => "drl_end+drl_start+name+drl_dir"
	);

	my %order       = ();
	my %alias       = ();
	my $signalOrder = 1;
	my $signalAlias = "c";
	my $iterate     = 0;

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWname} } ) ; $i++ ) {
		my $name = ${ $inCAM->{doinfo}{gROWname} }[$i];

		$order{$name} = $signalOrder;

		#start signal counting. "c" = 1, "v2" = 2, ...
		if ( $name eq "c" || ( $signalOrder > 1 && $signalOrder < $layerCnt ) ) {
			$signalOrder++;
		}

		#start signal counting. "c" = 1, "v2" = 2, ...
		if ( $name eq "c" || $iterate ) {
			$signalAlias = $name;
			$iterate     = 1;
		}
		if ( $name eq "s" ) {
			$iterate = 0;
		}

		$alias{$name} = $signalAlias;
	}

	for ( my $i = 0 ; $i < scalar( @{$layers} ) ; $i++ ) {

		my $layer = ${$layers}[$i];

		my @lInfos = @{ $inCAM->{doinfo}{gROWname} };
		my $idx = ( grep { $layer->{"gROWname"} eq ${ $inCAM->{doinfo}{gROWname} }[$_] } 0 .. $#lInfos )[0];

		unless ( defined $idx ) {
			next;
		}

		my $start = ${ $inCAM->{doinfo}{gROWdrl_start} }[$idx];
		my $end   = ${ $inCAM->{doinfo}{gROWdrl_end} }[$idx];

		$layer->{"gROWdrl_start_name"} = $alias{$start};
		$layer->{"gROWdrl_end_name"}   = $alias{$end};
		$layer->{"gROWdrl_start"}      = $order{$start};
		$layer->{"gROWdrl_end"}        = $order{$end};

		$layer->{"gROWname"} = ${ $inCAM->{doinfo}{gROWname} }[$idx];

		# not_def value is set when drill direction not was set manually in InCAM (default direction from top to bot)
		#drill direction top2bot/bot2top/not_def
		$layer->{"gROWdrl_dir"} = ${ $inCAM->{doinfo}{gROWdrl_dir} }[$idx];

		# "not_def" value is set when drill direction not was set manually in InCAM (default direction from top to bot)
		# from this point gROWdrl_dir has only 2 values: top2bot/bot2top
		$layer->{"gROWdrl_dir"} = "top2bot" if ( $layer->{"gROWdrl_dir"} eq "not_def" );

		#Necessary, for old genesis bot drilling. Because all drilling direction
		#were from TOP to BOT. But InCAM allows make Bot blind with direction
		#from Bot to TOP
		if ( ${ $inCAM->{doinfo}{gROWname} }[$idx] =~ /s[0-9]+s/ ) {    #if blind BOT drilling, check

			if ( $order{$start} < $order{$end} ) {
				$layer->{"gROWdrl_start_name"} = $alias{$end};
				$layer->{"gROWdrl_end_name"}   = $alias{$start};
				$layer->{"gROWdrl_start"}      = $order{$end};
				$layer->{"gROWdrl_end"}        = $order{$start};
				$layer->{"gROWdrl_dir"}        = "bot2top";
			}
		}

		#push( @arr, \%info );
	}

}

# For given layer (if is NC layer) return number of stages
# Search in given layer and look for drill_stage attribute
sub GetStagesCnt {

	my $self      = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $inCAM     = shift;

	my $fFeatures = $inCAM->INFO(
								  units           => 'mm',
								  angle_direction => 'ccw',
								  entity_type     => 'layer',
								  entity_path     => "$jobId/$stepName/$layerName",
								  data_type       => 'FEATURES',
								  options         => "break_sr+f0",
								  parse           => 'no'
	);

	my $f;
	open( $f, $fFeatures );

	my $maxStage = 1;
	while ( my $l = <$f> ) {

		if ( $l =~ /###/ ) { next; }

		$l =~ m/.*;(.*)/;

		unless ($1) {
			next;
		}
		my @attr = split( ",", $1 );

		foreach my $at (@attr) {

			if ( $at =~ /\.drill_stage=([0-9])+/ ) {

				if ( $1 > $maxStage ) {
					$maxStage = $1;
				}
			}
		}
	}

	return $maxStage;
}

# Add max and min tool to each layer
sub AddHistogramValues {
	my $self   = shift;
	my $inCAM  = shift;
	my $jobId  = shift;
	my $step   = shift;
	my $layers = shift;    #specify layers

	for ( my $i = 0 ; $i < scalar( @{$layers} ) ; $i++ ) {

		my $layer = ${$layers}[$i];
		my $lName = $layer->{"gROWname"};

		$inCAM->INFO(
					  "units"           => 'mm',
					  "angle_direction" => 'ccw',
					  "entity_type"     => 'layer',
					  "entity_path"     => "$jobId/$step/$lName",
					  "data_type"       => 'SYMS_HIST',
					  "options"         => "break_sr"
		);

		my @symbols = @{ $inCAM->{"doinfo"}{"gSYMS_HISTsymbol"} };

		my $min = undef;
		my $max = undef;
		foreach my $s (@symbols) {

			my ($val) = $s =~ m/(\d+)/;

			unless ($val) {
				next;
			}

			# set min value
			if ( !defined $min || $val < $min ) {
				$min = $val;
			}

			# set max value
			if ( !defined $max || $val > $max ) {
				$max = $val;
			}
		}

		$layer->{"minTool"} = $min;
		$layer->{"maxTool"} = $max;
	}
}

# Return 1 if exist some via fill layer in matrix
sub GetViaFillExists {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;


	my @fillL = $self->GetNCLayersByTypes(
										   $inCAM, $jobId,
										   [
											  EnumsGeneral->LAYERTYPE_plt_nFillDrill, EnumsGeneral->LAYERTYPE_plt_bFillDrillTop,
											  EnumsGeneral->LAYERTYPE_plt_bFillDrillBot
										   ]
	);

	return scalar(@fillL) ? 1 : 0;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamDrilling';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId     = "d113609";
	my $stepName  = "o+1";
	my $layerName = "j1";

	my %inf = CamDrilling->GetNCLayerInfo( $inCAM, $jobId, $layerName, 1, 1, 1 );
	
	print "Type:". $inf{"gROWlayer_type"};

}

1;
