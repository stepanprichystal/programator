#-------------------------------------------------------------------------------------------#
# Description: Helper class, contains general function working with job
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamJob;

#use lib qw(.. C:/Vyvoj/Perl/test);
#use LoadLibrary2;

#3th party library

use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamJob';
use aliased 'CamHelpers::CamAttributes';

#my $genesis = new Genesis;

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub GetSignalLayerCnt {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	return scalar( CamJob->GetSignalLayer( $inCAM, $jobId ) );
}

sub GetSignalLayerNames {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @l = CamJob->GetSignalLayer( $inCAM, $jobId );

	my @result = map { $_->{"gROWname"} } @l;

	return @result;
}

sub GetSignalLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	$inCAM->INFO( 'entity_type' => 'matrix', 'entity_path' => "$jobId/matrix", 'data_type' => 'ROW' );

	my @arr = ();

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWrow} } ) ; $i++ ) {

		my $rowFilled  = ${ $inCAM->{doinfo}{gROWtype} }[$i];
		my $rowContext = ${ $inCAM->{doinfo}{gROWcontext} }[$i];
		my $rowType    = ${ $inCAM->{doinfo}{gROWlayer_type} }[$i];

		if ( $rowFilled ne "empty" && $rowContext eq "board" ) {

			if ( $rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground" ) {

				my %info = ();
				$info{"gROWname"}       = ${ $inCAM->{doinfo}{gROWname} }[$i];
				$info{"gROWlayer_type"} = ${ $inCAM->{doinfo}{gROWlayer_type} }[$i];
				$info{"gROWpolarity"}   = ${ $inCAM->{doinfo}{gROWpolarity} }[$i];

				push( @arr, \%info );

			}
		}
	}
	return @arr;
}

#Return limits of profile
sub GetProfileLimits {

	my $self           = shift;
	my $inCAM          = shift;
	my $jobName        = shift;
	my $stepName       = shift;
	my $considerOrigin = shift;
 

	my %limits;

	unless ($considerOrigin) {
		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'step',
					  entity_path => "$jobName/$stepName",
					  data_type   => 'PROF_LIMITS'
		);
	}
	else {
		$inCAM->INFO(
					  units       => 'mm',
					  entity_type => 'step',
					  entity_path => "$jobName/$stepName",
					  data_type   => 'PROF_LIMITS',
					  "options"   => "consider_origin"
		);
	}

	$limits{"xmin"} = ( $inCAM->{doinfo}{gPROF_LIMITSxmin} );
	$limits{"xmax"} = ( $inCAM->{doinfo}{gPROF_LIMITSxmax} );
	$limits{"ymin"} = ( $inCAM->{doinfo}{gPROF_LIMITSymin} );
	$limits{"ymax"} = ( $inCAM->{doinfo}{gPROF_LIMITSymax} );

	return %limits;
}

#Return limits of profile, but with camelCase keys
sub GetProfileLimits2 {
	my $self = shift;

	my %lim = $self->GetProfileLimits(@_);

	my %limits = ();

	$limits{"xMin"} = $lim{"xmin"};
	$limits{"xMax"} = $lim{"xmax"};
	$limits{"yMin"} = $lim{"ymin"};
	$limits{"yMax"} = $lim{"ymax"};

	return %limits;
}

#Return limits of layer, profile doesn't have influence
sub GetLayerLimits {

	my $self      = shift;
	my $inCAM     = shift;
	my $jobName   = shift;
	my $stepName  = shift;
	my $layerName = shift;

	my %limits;

	$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$jobName/$stepName/$layerName", data_type => 'LIMITS' );

	$limits{"xmin"} = ( $inCAM->{doinfo}{gLIMITSxmin} );
	$limits{"xmax"} = ( $inCAM->{doinfo}{gLIMITSxmax} );
	$limits{"ymin"} = ( $inCAM->{doinfo}{gLIMITSymin} );
	$limits{"ymax"} = ( $inCAM->{doinfo}{gLIMITSymax} );

	return %limits;
}

#Return class of pcb step, which is saved as job attribute PcbClass
sub GetJobPcbClass {

	my $self = shift;

	my %info = CamAttributes->GetJobAttr(@_);

	return $info{"pcb_class"};

}

#Create layer
sub CreateLayer {

	my $self       = shift;
	my $inCAM      = shift;
	my $layerName  = shift;    #test
	my $context    = shift;    #board
	my $type       = shift;    #rout
	my $polarity   = shift;    #positive
	my $afterLayer = shift;

	$inCAM->COM(
				 'create_layer',
				 "layer"     => $layerName,
				 "context"   => $context,
				 "type"      => $type,
				 "polarity"  => $polarity,
				 "location"  => "after",
				 "ins_layer" => $afterLayer
	);

}

#if layer already exist, delete it and than create
sub CreateLayerForce {

	my $self       = shift;
	my $inCAM      = shift;
	my $jobId      = shift;
	my $stepName   = shift;
	my $layerName  = shift;    #test
	my $context    = shift;    #board
	my $type       = shift;    #rout
	my $polarity   = shift;    #positive
	my $afterLayer = shift;

	if ( CamHelper->LayerExists( $inCAM, $jobId, $layerName ) ) {

		$inCAM->COM( 'delete_layer', "layer" => $layerName );
	}

	$inCAM->COM(
				 'create_layer',
				 "layer"     => $layerName,
				 "context"   => $context,
				 "type"      => $type,
				 "polarity"  => $polarity,
				 "location"  => "after",
				 "ins_layer" => $afterLayer
	);

}

# Return all layers from matrix as array of hash
# which contain info:
# - gROWname
# - gROWlayer_type
# - gROWcontext
sub GetAllLayers {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @arr = ();

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'matrix',
				  entity_path     => "$jobId/matrix",
				  data_type       => 'ROW',
				  parameters      => "layer_type+name+type+context+polarity"
	);

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWname} } ) ; $i++ ) {
		my %info = ();
		$info{"gROWname"}       = ${ $inCAM->{doinfo}{gROWname} }[$i];
		$info{"gROWlayer_type"} = ${ $inCAM->{doinfo}{gROWlayer_type} }[$i];
		$info{"gROWcontext"}    = ${ $inCAM->{doinfo}{gROWcontext} }[$i];
		$info{"gROWpolarity"}   = ${ $inCAM->{doinfo}{gROWpolarity} }[$i];

		my $rowFilled  = ${ $inCAM->{doinfo}{gROWtype} }[$i];
		my $rowContext = ${ $inCAM->{doinfo}{gROWcontext} }[$i];
		my $rowType    = ${ $inCAM->{doinfo}{gROWlayer_type} }[$i];

		if ( $rowFilled ne "empty" ) {

			push( @arr, \%info );
		}

	}
	return @arr;
}

# Return all layers from matrix as array of hash, which are layer_type == board
# which contain info:
# - gROWname
# - gROWlayer_type
# - gROWcontext
sub GetBoardLayers {
	my $self = shift;

	my @layers = $self->GetAllLayers(@_);

	@layers = grep { $_->{"gROWcontext"} eq "board" } @layers;

	return @layers;
}

# Return all layers from matrix as array of hash, which are layer_type == board
# And which are not NC layers
# which contain info:
# - gROWname
# - gROWlayer_type
# - gROWcontext
sub GetBoardBaseLayers {
	my $self = shift;

	my @layers = $self->GetAllLayers(@_);

	@layers = grep { $_->{"gROWcontext"} eq "board" && $_->{"gROWlayer_type"} ne "rout" && $_->{"gROWlayer_type"} ne "drill" } @layers;

	return @layers;
}

#Return layer names by layer type
sub GetLayerByType {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $type  = shift;

	my @arr = CamJob->GetBoardLayers( $inCAM, $jobId );

	my @res = ();

	foreach my $l (@arr) {

		if ( $l->{"gROWlayer_type"} =~ /$type/i ) {
			push( @res, $l );
		}
	}
	return @res;
}

#set $value for attribute on specific Job
sub SetJobAttribute {

	my $self      = shift;
	my $inCAM     = shift;
	my $attribute = shift;
	my $value     = shift;
	my $jobId     = shift;

	$inCAM->COM(
				 "set_attribute",
				 "type"      => "job",
				 "job"       => $jobId,
				 "entity"    => "",
				 "attribute" => $attribute,
				 "value"     => $value,
				 "name1"     => "",
				 "name2"     => "",
				 "name3"     => "",
				 "units"     => "mm"
	);
}

# Open given job
sub CloseJob {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	$inCam->COM( "close_job", "job" => "$jobName" );
}

# Open given job
sub SaveJob {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	$inCam->COM( "save_job", "job" => "$jobName" );

}

# Tell if job is open
sub IsJobOpen {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	$inCam->COM( "is_job_open", "job" => "$jobName" );
	my $reply = $inCam->GetReply();

	if ( $reply eq "yes" ) {
		return 1;
	}
	else {
		return 0;
	}
}

# CheckIn job
sub CheckInJob {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	$inCam->COM( "check_inout", "job" => "$jobName", "mode" => "in", "ent_type" => "job" );
}

# CheckIn job
sub CheckOutJob {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	$inCam->COM( "check_inout", "job" => "$jobName", "mode" => "out", "ent_type" => "job" );
}

# Get all jobs name in job database, where is actual job
sub GetJobList {
	my $self    = shift;
	my $inCAM   = shift;

	$inCAM->INFO("units" => 'mm', "angle_direction" => 'ccw', "entity_type" => 'root',     "data_type" => 'JOBS_LIST');
 
	my @jobs =  @{ $inCAM->{doinfo}{gJOBS_LIST } };	
	
	return @jobs;
}



1;
