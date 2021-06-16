#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains calculation for drilling
# Author: SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamDrilling;

#3th party library
use strict;
use warnings;
use List::Util qw[max min];
use Array::Utils qw(:all);

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamMatrix';
use aliased 'Enums::EnumsDrill';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return minimal hole tool for given layer and layer type
# Type EnumsGeneral->LAYERTYPE
sub GetMinHoleTool {

	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepName   = shift;
	my $layertypes = shift;
	my $fromLayer  = shift;    #tell, only drill layers starts from <$fromLayer> will be considered

	my @layers = $self->GetNCLayersByTypes( $inCAM, $jobId, $layertypes );
	$self->AddLayerStartStop( $inCAM, $jobId, \@layers );

	my $minTool;

	#filter layer, which go from <$fromLayer>
	if ($fromLayer) {
		@layers = grep { $_->{"NCSigStart"} eq $fromLayer } @layers;
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

# Add  to every hash in array new value:
# - type: Type is assign by our rules, which ve use wehen proscess pcb
# - plated: Plated tells, if holes/slots in layer are plated or not
# - technical: NC layer only concerns panel technical frame
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

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_nDrill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^sc[0-9]+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_bDrillTop;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^ss[0-9]+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_bDrillBot;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^mfill[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_nFillDrill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^scfill[0-9]+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_bFillDrillTop;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^ssfill[0-9]+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_bFillDrillBot;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^j[0-9]+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_cDrill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^jfill[0-9]+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_cFillDrill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;
		}
		elsif ( $l->{"gROWname"} =~ /^r[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_nMill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^rzc[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_bMillTop;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^rzs[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_bMillBot;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^v$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_fDrill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^v1$/ || $l->{"gROWname"} =~ /^v1j\d+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_fcDrill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 1;

		}
		elsif ( $l->{"gROWname"} =~ /^v1p\d+$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_plt_fcPressDrill;
			$l->{"plated"}    = 1;
			$l->{"technical"} = 1;

		}


		# Non plated NC layers
		elsif ( $l->{"gROWname"} =~ /^d[0-9]*$/ || $l->{"gROWname"} =~ /^fsch_d$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_nDrill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^ds[0-9]*$/ || $l->{"gROWname"} =~ /^fsch_ds$/) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_nDrillBot;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^f[0-9]*$/ || $l->{"gROWname"} =~ /^f(sch)?(lm)?$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_nMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fs[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_nMillBot;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fzc[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_bMillTop;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fzs[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_bMillBot;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^rs[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_rsMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fr[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_frMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^score$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_score;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^jfzc[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_cbMillTop;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^jfzs[0-9]*$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_cbMillBot;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fk$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_kMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^flc$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_lcMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fls$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_lsMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^f_.*/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_fMillSpec;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;
		}

		# new for flexi
		elsif ( $l->{"gROWname"} =~ /^fcvrlc\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_cvrlycMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fcvrls\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_cvrlysMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fprprg[12]/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_prepregMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fstiffc\d?$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_stiffcMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fstiffs\d?$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_stiffsMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fstiffcadh\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_stiffcAdhMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fstiffsadh\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_stiffsAdhMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fzstiffc\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_bstiffcMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fzstiffs\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_bstiffsMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fsoldc\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_soldcMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^fsolds\d?/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_soldsMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^ftpc$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_tapecMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^ftps$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_tapesMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;

		}
		elsif ( $l->{"gROWname"} =~ /^ftpbr$/ ) {

			$l->{"type"}      = EnumsGeneral->LAYERTYPE_nplt_tapebrMill;
			$l->{"plated"}    = 0;
			$l->{"technical"} = 0;
		}

	}

	#return @res;
}

# Return if NC layer is known for scripts
# If "type" is find bz AddNCLayerType method, NC layer is known
sub GetNCLayerIsKnown {
	my $self      = shift;
	my $layerName = shift;

	my %lInfo = ( "gROWname" => $layerName );
	$self->AddNCLayerType( [ \%lInfo ] );

	defined $lInfo{"type"} ? return 1 : return 0;
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

		die "Key: \"type\" was not set at layer: $layer"   unless ( defined $lInfo{"type"} );
		die "Key: \"plated\" was not set at layer: $layer" unless ( defined $lInfo{"plated"} );
	}
	if ($matrixType) {
		$lInfo{"gROWlayer_type"} = CamMatrix->GetLayerType( $inCAM, $jobId, $layer );
		die "Key: \"gROWlayer_type\"  was not set at layer: $layer" unless ( defined $lInfo{"gROWlayer_type"} );
	}

	if ($startStop) {
		$self->AddLayerStartStop( $inCAM, $jobId, [ \%lInfo ] );
		die "Key: \"gROWdrl_start\"  was not set at layer: $layer" unless ( defined $lInfo{"gROWdrl_start"} );
		die "Key: \"gROWdrl_end\"  was not set at layer: $layer"   unless ( defined $lInfo{"gROWdrl_end"} );
		die "Key: \"NCStartOrder\"  was not set at layer: $layer"  unless ( defined $lInfo{"NCStartOrder"} );
		die "Key: \"NCEndOrder\"  was not set at layer: $layer"    unless ( defined $lInfo{"NCEndOrder"} );
		die "Key: \"gROWdrl_dir\"  was not set at layer: $layer"   unless ( defined $lInfo{"gROWdrl_dir"} );

		if ( $lInfo{"NCThroughSig"} ) {

			die "Key: \"NCSigStart\"  was not set at layer: $layer"      unless ( defined $lInfo{"NCSigStart"} );
			die "Key: \"NCSigEnd\"  was not set at layer: $layer"        unless ( defined $lInfo{"NCSigEnd"} );
			die "Key: \"NCSigStartOrder\"  was not set at layer: $layer" unless ( defined $lInfo{"NCSigStartOrder"} );
			die "Key: \"NCSigEndOrder\"  was not set at layer: $layer"   unless ( defined $lInfo{"NCSigEndOrder"} );
		}
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

# Add  to every hash (layer) in array new keys:
# - {"gROWdrl_start"} - layer name where NC layer starts ( start layer type does not matter )
# - {"gROWdrl_end"}   -  layer name where NC layer starts ( end layer type does not matter )
# - {"NCStartOrder"}  - layer order index where NC layer starts ( start layer type does not matter )
# - {"NCEndOrder"}    - layer order index where NC layer starts ( end layer type does not matter )
# - {"gROWdrl_dir"}   - direction of NC layer in matrix
# - {"NCThroughSig"} - 0/1 indicate if NC layer start/end/go through at least one signal layer
#
# If NC layer which start/end/go through at least one signal layer add extra keys:
# - {"NCSigStart"}   - signal layer name where NC layer starts (if NC layer start/end/go through at least one signal layer)
# - {"NCSigEnd"}     - signal layer name where NC layer end (if NC layer start/end/go through at least one signal layer)
# - {"NCSigStartOrder"}  - signal layer order (c = 1) where NC layer starts (if NC layer start/end/go through at least one signal layer)
# - {"NCSigEndOrder"}    - signal layer order (c = 1) where NC layer end (if NC layer start/end/go through at least one signal layer)
sub AddLayerStartStop {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $NCLayers = shift;    #specify layers

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'matrix',
				  entity_path     => "$jobId/matrix",
				  data_type       => 'ROW',
				  parameters      => "drl_end+drl_start+name+drl_dir+layer_type"
	);

	my @arr = ( 1, 2 );
	my $arrRef = [ 1, 2 ];

	my %matrixLayerOrder = ();

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWname} } ) ; $i++ ) {

		$matrixLayerOrder{ $inCAM->{"doinfo"}{"gROWname"}->[$i] } = $i + 1;
	}

	# 1) Add base info for all NC layers
	foreach my $NCl ( @{$NCLayers} ) {
		my $idx = ( grep { $inCAM->{doinfo}{gROWname}->[$_] eq $NCl->{"gROWname"} } 0 .. $#{ $inCAM->{doinfo}{gROWname} } )[0];

		# start/stop info
		$NCl->{"gROWdrl_start"} = $inCAM->{"doinfo"}{"gROWdrl_start"}->[$idx];    # start layer name
		$NCl->{"gROWdrl_end"}   = $inCAM->{"doinfo"}{"gROWdrl_end"}->[$idx];      # end layer name
		$NCl->{"gROWdrl_dir"}   = $inCAM->{"doinfo"}{"gROWdrl_dir"}->[$idx];      # layer matrix direction
		     # "not_def" value is set when drill direction not was set manually in InCAM (default direction from top to bot)
		     # from this point gROWdrl_dir has only 2 values: top2bot/bot2top
		$NCl->{"gROWdrl_dir"} = "top2bot" if ( $NCl->{"gROWdrl_dir"} eq "not_def" );

		$NCl->{"NCStartOrder"} = $matrixLayerOrder{ $NCl->{"gROWdrl_start"} };    # start layer order in matrix
		$NCl->{"NCEndOrder"}   = $matrixLayerOrder{ $NCl->{"gROWdrl_end"} };      # end layer order in matrix
	}

	# 2) Add extra info for NC layers which start/end/go through at least one signal layer

	my @sigLayerMatrixOrder = ();
	my %sigLayerOrder       = ();

	my $sigLayerIdx = 1;
	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWname} } ) ; $i++ ) {

		my $lName = $inCAM->{doinfo}{gROWname}->[$i];
		my $lType = $inCAM->{doinfo}{gROWlayer_type}->[$i];

		if ( ( $lType eq "signal" || $lType eq "power_ground" || $lType eq "mixed" ) && $lName =~ /(^v\d+$)|^[cs]$/ ) {

			push( @sigLayerMatrixOrder, $i + 1 );
			$sigLayerOrder{$lName} = $sigLayerIdx;
			$sigLayerIdx++;
		}
	}

	foreach my $NCl ( @{$NCLayers} ) {

		$NCl->{"NCThroughSig"} = 1;

		my @goThroughLayers = ();

		if ( $NCl->{"gROWdrl_dir"} eq "bot2top" ) {
			@goThroughLayers = reverse( $NCl->{"NCEndOrder"} .. $NCl->{"NCStartOrder"} );
		}
		else {
			@goThroughLayers = $NCl->{"NCStartOrder"} .. $NCl->{"NCEndOrder"};
		}

		# Check if NC layer start/end/go through at least one signal layer
		my @sigLIsect = intersect( @sigLayerMatrixOrder, @goThroughLayers );

		unless (@sigLIsect) {

			$NCl->{"NCThroughSig"} = 0;
			next;
		}

		my $sigMatrixStart;
		my $sigMatrixEnd;

		if ( $NCl->{"gROWdrl_dir"} eq "top2bot" ) {

			$sigMatrixStart = max( min(@sigLayerMatrixOrder), $NCl->{"NCStartOrder"} );
			$sigMatrixEnd = min( max(@sigLayerMatrixOrder), $NCl->{"NCEndOrder"} );

		}
		elsif ( $NCl->{"gROWdrl_dir"} eq "bot2top" ) {

			$sigMatrixStart = min( max(@sigLayerMatrixOrder), $NCl->{"NCStartOrder"} );
			$sigMatrixEnd = max( min(@sigLayerMatrixOrder), $NCl->{"NCEndOrder"} );
		}

		# Get signal layer name and signal layer order by start/end layer order in matrix
		foreach my $lName ( keys %matrixLayerOrder ) {

			if ( $sigMatrixStart == $matrixLayerOrder{$lName} ) {

				$NCl->{"NCSigStart"}      = $lName;
				$NCl->{"NCSigStartOrder"} = $sigLayerOrder{$lName};
			}

			if ( $sigMatrixEnd == $matrixLayerOrder{$lName} ) {

				$NCl->{"NCSigEnd"}      = $lName;
				$NCl->{"NCSigEndOrder"} = $sigLayerOrder{$lName};
			}
		}

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

# Return type of via filling in job, based on NC layers
# If $fillType is not defined, return if at leas one type of viafill exist
# Values for param $fillType:
#	EnumsDrill->ViaFill_OUTER  - check if any via fill NC layer start from very top or very bot stackup layer
#	EnumsDrill->ViaFill_INNER- check if any via fill NC layer start from inner layer  of stackup layer
sub GetViaFillExists {
	my $self     = shift;
	my $inCAM    = shift;
	my $jobId    = shift;
	my $fillType = shift // undef;    # EnumsDrill->ViaFill_

	my @ncLayers = $self->GetNCLayersByTypes(
											  $inCAM, $jobId,
											  [
												 EnumsGeneral->LAYERTYPE_plt_nFillDrill,    EnumsGeneral->LAYERTYPE_plt_bFillDrillTop,
												 EnumsGeneral->LAYERTYPE_plt_bFillDrillBot, EnumsGeneral->LAYERTYPE_plt_cFillDrill
											  ]
	);

	$self->AddLayerStartStop( $inCAM, $jobId, \@ncLayers );

	if ( defined $fillType ) {

		my $sigLayerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );

		if ( $fillType eq EnumsDrill->ViaFill_OUTER ) {

			@ncLayers = grep { $_->{"NCSigStartOrder"} == 1 || $_->{"NCSigStartOrder"} == $sigLayerCnt } @ncLayers;
		}
		elsif ( $fillType eq EnumsDrill->ViaFill_INNER ) {

			@ncLayers = grep { $_->{"NCSigStartOrder"} > 1 && $_->{"NCSigStartOrder"} < $sigLayerCnt } @ncLayers;
		}
	}

	return scalar(@ncLayers) ? 1 : 0;
}

# Return NC operation name
# Operation name is used for getting tool parameters, tool feed rate, etc..
# Operation name depands on:
# - matrix layer name
# - process type of tool
sub GetToolOperation {
	my $self        = shift;
	my $inCAM       = shift;
	my $jobId       = shift;
	my $layer       = shift;
	my $processType = shift;    # EnumsDrills->TypeProc_HOLE /  EnumsDrills->TypeProc_CHAIN

	my %l = $self->GetNCLayerInfo( $inCAM, $jobId, $layer, 1, 1 );

	my $operation = undef;

	# 1) Specify type by plated/nonplated and hlole/chain type
	if ( $l{"plated"} && $processType eq EnumsDrill->TypeProc_HOLE ) {

		$operation = EnumsDrill->ToolOp_PLATEDDRILL;

	}
	elsif ( $l{"plated"} && $processType eq EnumsDrill->TypeProc_CHAIN ) {

		$operation = EnumsDrill->ToolOp_PLATEDROUT;

	}
	elsif ( !$l{"plated"} && $processType eq EnumsDrill->TypeProc_HOLE ) {

		$operation = EnumsDrill->ToolOp_NPLATEDDRILL;

	}
	elsif ( !$l{"plated"} && $processType eq EnumsDrill->TypeProc_CHAIN ) {

		$operation = EnumsDrill->ToolOp_NPLATEDROUT;

	}

	# 2) Specify type by on on layer type
	if ( $processType eq EnumsDrill->TypeProc_CHAIN && $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_rsMill ) {

		$operation = EnumsDrill->ToolOp_ROUTBEFOREETCH;

	}
	elsif ( $processType eq EnumsDrill->TypeProc_CHAIN && $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_kMill ) {

		$operation = EnumsDrill->ToolOp_ROUTBEFOREET;

	}
	elsif (
			$processType eq EnumsDrill->TypeProc_CHAIN
			&& (    $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlycMill
				 || $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_cvrlysMill )
	  )
	{
		$operation = EnumsDrill->ToolOp_COVERLAYROUT;

	}
	elsif ( $processType eq EnumsDrill->TypeProc_CHAIN && $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_prepregMill ) {

		$operation = EnumsDrill->ToolOp_PREPREGROUT;

	}
	elsif (
			$processType eq EnumsDrill->TypeProc_CHAIN
			&& (    $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapecMill
				 || $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_tapesMill
				 || $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffcAdhMill
				 || $l{"type"} eq EnumsGeneral->LAYERTYPE_nplt_stiffsAdhMill )
	  )
	{

		$operation = EnumsDrill->ToolOp_TAPEROUT;
	}

	die "Tool operation is not defined for tool process type: $processType, layer: " . $layer unless ( defined $operation );

	return $operation;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamDrilling';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId    = "d322394";
	my $stepName = "o+1";

	#my $layerName = "fstiffs";

	my %res = CamDrilling->GetNCLayerInfo( $inCAM, $jobId, "v", 1, 1 ,1);

	die;

}

1;
