#-------------------------------------------------------------------------------------------#
# Description: Helper, which contains only the simplest operation over InCAM
# Such as LayerExist, StepExist etc.. No complex operation here!
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamHelper;

#3th party library
use strict;
use warnings;

#loading of locale modules

#use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamJob';
use aliased 'Enums::EnumsGeneral';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Helpers::FileHelper';
#
##-------------------------------------------------------------------------------------------#
##   Package methods
##-------------------------------------------------------------------------------------------#
#
##Open job and step in genesis
#sub Pause {
#
#	my $self  = shift;
#	my $inCAM = shift;
#	my $mess  = shift;
#
#	$inCAM->PAUSE($mess);
#
#	my $res = $inCAM->{"PAUSANS"};
#
#	if ( !defined $res || $res eq "" ) {
#		return 0;
#
#	}
#	else {
#
#		return 1;
#	}
#
#}
#
## Open job / set job for scripts
#sub OpenJob {
#
#	my $self       = shift;
#	my $inCam      = shift;
#	my $jobName    = shift;
#	my $openEditor = shift // 1;
#
#	#	$inCam->COM(
#	#				 "clipb_open_job",
#	#				 job              => "$jobName",
#	#				 update_clipboard => "view_job"
#	#	);
#
#	$inCam->COM( "open_job", job => "$jobName", "open_win" => ( $openEditor ? "yes" : "no" ) );
#
#	#$inCam->AUX( 'set_group', group => $inCam->{COMANS} );
#
#}
#
## Set step + return group id of step
## Use when work with more than one jobs at one script
#sub OpenStep {
#
#	my $self     = shift;
#	my $inCAM    = shift;
#	my $jobName  = shift;
#	my $stepName = shift;
#
#	$inCAM->COM(
#				 "open_entity",
#				 job  => "$jobName",
#				 type => "step",
#				 name => $stepName
#	);
#
#	my $groupId = $inCAM->GetReply();
#
#	$inCAM->AUX( 'set_group', "group" => $groupId );
#
#	return $groupId;
#}
# 
#
## Set step
## Use when work with one job  at script
## Optimalization - Set only if not set
## Current step is stored in environment variables
## If InCAM is connected to Editor through server script
## After connect InCAM librarz to server script running in InCAM editor,
## Server send ENV variables to InCAM library and override current script ENV variables
#sub SetStep {
#	my $self     = shift;
#	my $inCAM    = shift;
#	my $stepName = shift;
#
#	$inCAM->COM( "set_step", "name" => $stepName ) if(!defined $stepName || $stepName ne $ENV{"STEP"});
#
#}
#
#sub SetGroupId {
#	my $self    = shift;
#	my $inCAM   = shift;
#	my $groupId = shift;
#
#	$inCAM->AUX( 'set_group', group => $groupId );
#}
#
#sub GetGroupId {
#	my $self  = shift;
#	my $inCAM = shift;
#	my $jobId = shift;
#	my $step  = shift;
#
#	$inCAM->COM(
#				 'open_group',
#				 'job'    => "$jobId",
#				 'step'   => $step,
#				 'is_sym' => 'no'
#	);
#
#	return $inCAM->GetReply();
#
#}
#
## Open given job
#sub SaveAndCloseJob {
#	my $self    = shift;
#	my $inCam   = shift;
#	my $jobName = shift;
#
#	$inCam->COM( "save_job",  "job" => "$jobName" );
#	$inCam->COM( "close_job", "job" => "$jobName" );
#}
#
##Return if step exists
#sub StepExists {
#
#	my $self     = shift;
#	my $inCAM    = shift;
#	my $jobName  = shift;
#	my $stepName = shift;
#
#	$inCAM->INFO(
#				  entity_type => 'step',
#				  entity_path => "$jobName/$stepName",
#				  data_type   => 'exists'
#	);
#
#	if ( $inCAM->{doinfo}{gEXISTS} eq "yes" ) {
#		return 1;
#	}
#	else {
#		return 0;
#	}
#}
#
## reset filter and clear affected layers
#sub ClearEditor {
#	my $self    = shift;
#	my $inCAM   = shift;
#	my $jobName = shift;
#
#	$inCAM->AUX( 'set_group', group => $inCAM->{COMANS} );
#	$inCAM->COM( 'units', type => 'mm' );
#	$inCAM->COM( 'affected_layer', name => "", mode => "all", affected => "no" );
#	$inCAM->COM('clear_layers');
#}
#
##Return if layer exists
#sub LayerExists {
#	my $self    = shift;
#	my $inCAM   = shift;
#	my $jobName = shift;
#
#	#my $stepName  = shift; # param isn't need
#	my $layerName = shift;
#
#	$inCAM->INFO(
#				  units           => 'mm',
#				  angle_direction => 'ccw',
#				  entity_type     => 'matrix',
#				  entity_path     => "$jobName/matrix",
#				  data_type       => 'ROW',
#				  parameters      => "name"
#	);
#
#	my @layers = @{ $inCAM->{doinfo}{gROWname} };
#
#	if ( scalar( grep { $_ eq $layerName } @layers ) ) {
#		return 1;
#	}
#	else {
#		return 0;
#	}
#}
#
##Return type of layer
## type such as: rout, drill, signal..
#sub LayerType {
#
#	my $self    = shift;
#	my $inCAM   = shift;
#	my $jobName = shift;
#
#	#my $stepName  = shift;  # param isn't need
#	my $layerName = shift;
#
#	$inCAM->INFO(
#				  units           => 'mm',
#				  angle_direction => 'ccw',
#				  entity_type     => 'matrix',
#				  entity_path     => "$jobName/matrix",
#				  data_type       => 'ROW',
#				  parameters      => "layer_type+name"
#	);
#
#	my @layers = @{ $inCAM->{doinfo}{gROWname} };
#	my @types  = @{ $inCAM->{doinfo}{gROWlayer_type} };
#
#	my $idx = ( grep { $layerName eq $layers[$_] } 0 .. $#layers )[0];
#
#	if ( defined $idx ) {
#
#		return $types[$idx];
#	}
#}
#
##Return user name of logged user
#sub GetUserName {
#	my $self  = shift;
#	my $inCAM = shift;
#
#	$inCAM->COM("get_user_name");
#
#	return $inCAM->GetReply();
#}
#
##Return real type of pcb based on Helios and CAM information
## Type can be all from: EnumsGeneral->PcbTyp_xxx
#sub GetPcbType {
#	my $self  = shift;
#	my $inCAM = shift;
#	my $jobId = shift;
#
#	my $type;
#	my $layerCnt = CamJob->GetSignalLayerCnt( $inCAM, $jobId );
#
#	if ( HegMethods->GetTypeOfPcb($jobId) eq 'Neplatovany' ) {
#
#		$type = EnumsGeneral->PcbType_NOCOPPER;
#
#	}
#	elsif ( HegMethods->GetTypeOfPcb($jobId) eq 'Sablona' ) {
#
#		$type = EnumsGeneral->PcbType_STENCIL;
#	}
#	else {
#
#		if ( $layerCnt == 1 ) {
#
#			$type = EnumsGeneral->PcbType_1V;
#
#		}
#		elsif ( $layerCnt == 2 ) {
#
#			$type = EnumsGeneral->PcbType_2V;
#
#		}
#		else {
#
#			$type = EnumsGeneral->PcbType_MULTI;
#		}
#	}
#
#	return $type;
#}
#
#sub EntityChanged {
#	my $self   = shift;
#	my $inCAM  = shift;
#	my $jobId  = shift;
#	my $type   = shift;            # created/modified
#	my @entity = @{ shift(@_) };
#
#	# 1) load file with changes
#	my $infoFile = $inCAM->INFO(
#								 "units"           => 'mm',
#								 "angle_direction" => 'ccw',
#								 "entity_type"     => 'job',
#								 "entity_path"     => $jobId,
#								 "data_type"       => 'CHANGES',
#								 "parse"           => 'no'
#	);
#
#	unless ( -e $infoFile ) {
#		die "Infofile job CHANGES doesn't exist.\n";
#	}
#
#	my $linesRef = FileHelper->ReadAsLines($infoFile);
#
#	unlink($infoFile);
#
#	my $entities = undef;
#
#	my %hash = ();
#
#	my @created  = ();
#	my @modified = ();
#	$hash{"created"}  = \@created;
#	$hash{"modified"} = \@modified;
#	$hash{"deleted"}  = \@modified;
#
#	if ($linesRef) {
#
#		my @lines = @{$linesRef};
#
#		foreach my $l (@lines) {
#
#			if ( $l =~ /^[\s\t\n]$/ || $l =~ /-{3,}/ ) {
#				next;
#			}
#
#			$l = lc($l);
#			chomp($l);
#
#			if ( $l =~ "created entities" ) {
#				$entities = "created";
#			}
#			elsif ( $l =~ "modified entities" ) {
#				$entities = "modified";
#
#			}
#			elsif ( $l =~ "deleted entities" ) {
#				$entities = "deleted";
#			}
#			else {
#
#				unless ($entities) {
#					next;
#				}
#
#				# Parse lines
#				# each item of array = one level (step, layer, ...)
#				my $str    = "";
#				my @ent    = split( ",", $l );
#				my @entRes = ();
#
#				# get entity values
#				foreach my $e (@ent) {
#					my $val = ( split( "=", $e ) )[1];
#					$val =~ s/\s//g;
#					push( @entRes, $val ) if ( defined $val );
#				}
#
#				push( @{ $hash{$entities} }, lc( join( "/", @entRes ) ) );
#			}
#		}
#	}
#
#	# 2) Check if entities was modified/created
#
#	my $entitStr = join( "/", @entity );
#	$entitStr = lc($entitStr);
#	$entitStr = quotemeta $entitStr;
#
#	my $exist = grep { $_ =~ /^$entitStr$/i } @{ $hash{$type} };
#
#	if ($exist) {
#		return 1;
#	}
#	else {
#		return 0;
#	}
#}
#
##-------------------------------------------------------------------------------------------#
##  Place for testing..
##-------------------------------------------------------------------------------------------#
#my ( $package, $filename, $line ) = caller;
#if ( $filename =~ /DEBUG_FILE.pl/ ) {
#
#	#	use aliased 'CamHelpers::CamHelper';
#	#	use aliased 'Packages::InCAM::InCAM';
#	#
#	#	my $inCAM = InCAM->new();
#	#
#	#	my $jobId     = "f69854";
#	#	my $stepName  = "panel";
#	#
#	#	my @arr =  ("mpanel", "m");
#	#
#	#	my $res = CamHelper->StepExists(  $inCAM, $jobId, "o+1");
#	#
#	#	print STDERR "test";
#
#}

1;
