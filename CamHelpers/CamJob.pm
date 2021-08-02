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
use List::Util qw[max min first];

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamAttributes';
use aliased 'Helpers::GeneralHelper';
use aliased 'Helpers::FileHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'Connectors::HeliosConnector::HegMethods';

#my $genesis = new Genesis;

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub GetSignalLayerCnt {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $noOuter = shift;
	my $noInner = shift;

	return scalar( $self->GetSignalLayer( $inCAM, $jobId, $noOuter, $noInner ) );
}

sub GetSignalLayerNames {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $noOuter = shift;
	my $noInner = shift;

	my @l = $self->GetSignalLayer( $inCAM, $jobId, $noOuter, $noInner );

	my @result = map { $_->{"gROWname"} } @l;

	return @result;
}

# Return all layers which are board and type of: signal; mixed; powerground
sub GetSignalLayer {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $noOuter = shift;
	my $noInner = shift;

	$inCAM->INFO( 'entity_type' => 'matrix', 'entity_path' => "$jobId/matrix", 'data_type' => 'ROW' );

	my @arr = ();

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWrow} } ) ; $i++ ) {

		my $rowFilled  = ${ $inCAM->{doinfo}{gROWtype} }[$i];
		my $rowContext = ${ $inCAM->{doinfo}{gROWcontext} }[$i];
		my $rowType    = ${ $inCAM->{doinfo}{gROWlayer_type} }[$i];

		if ( $rowFilled ne "empty" && $rowContext eq "board" ) {

			if ( $rowType eq "signal" || $rowType eq "mixed" || $rowType eq "power_ground" ) {

				my %info = ();
				$info{"gROWrow"}        = ${ $inCAM->{doinfo}{gROWrow} }[$i];
				$info{"gROWname"}       = ${ $inCAM->{doinfo}{gROWname} }[$i];
				$info{"gROWlayer_type"} = ${ $inCAM->{doinfo}{gROWlayer_type} }[$i];
				$info{"gROWpolarity"}   = ${ $inCAM->{doinfo}{gROWpolarity} }[$i];

				push( @arr, \%info );

			}
		}
	}

	# filter out outer layers
	if ($noOuter) {
		@arr = grep { $_->{"gROWname"} !~ /^[cs]$/ } @arr;
	}

	# filter out inner layers
	if ($noInner) {
		@arr = grep { $_->{"gROWname"} !~ /^v\d+$/ } @arr;
	}

	return @arr;
}

# Return all layers which are not directly signal but special:
# - layers for plugging vias
# - layers for outer cores Copper exposing
sub GetSignalExtLayer {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @boarBase = $self->GetBoardBaseLayers( $inCAM, $jobId );

	my @extraL = ();

	# Add plug layers
	push( @extraL, grep { $_->{"gROWname"} =~ /^plg[csv]\d*$/ } @boarBase );

	# Add outer core layers
	push( @extraL, grep { $_->{"gROWname"} =~ /^outer[csv]\d*$/ } @boarBase );

	return @extraL;
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

# return layer limits, consider SR features
sub GetLayerLimits2 {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $stepName  = shift;
	my $layerName = shift;
	my $breakSR   = shift;

	my %limits;

	my $tmp   = 0;
	my $layer = $layerName;
	if ( $breakSR && CamStepRepeat->ExistStepAndRepeats( $inCAM, $jobId, $stepName ) ) {

		CamHelper->SetStep( $inCAM, $stepName );
		$tmp   = 1;
		$layer = GeneralHelper->GetGUID();
		$inCAM->COM( 'flatten_layer', "source_layer" => $layerName, "target_layer" => $tmp );
	}

	$inCAM->INFO( units => 'mm', entity_type => 'layer', entity_path => "$jobId/$stepName/$layer", data_type => 'LIMITS' );

	$limits{"xMin"} = ( $inCAM->{doinfo}{gLIMITSxmin} );
	$limits{"xMax"} = ( $inCAM->{doinfo}{gLIMITSxmax} );
	$limits{"yMin"} = ( $inCAM->{doinfo}{gLIMITSymin} );
	$limits{"yMax"} = ( $inCAM->{doinfo}{gLIMITSymax} );

	if ($tmp) {
		$inCAM->COM( 'delete_layer', layer => $layer );
	}

	return %limits;
}

#Return class of pcb step, which is saved as job attribute PcbClass
sub GetJobPcbClass {

	my $self = shift;

	my %info = CamAttributes->GetJobAttr(@_);

	return $info{"pcb_class"};

}

#Return class of pcb step, which is saved as job attribute PcbClass
sub GetJobPcbClassInner {

	my $self = shift;

	my %info = CamAttributes->GetJobAttr(@_);

	return $info{"pcb_class_inner"};

}

# Return max or min pcb classs from outer and inner pcb class
sub GetLimJobPcbClass {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $lim   = shift;    # max/min

	my @classes = ();

	push( @classes, $self->GetJobPcbClass( $inCAM, $jobId ) );

	if ( $self->GetSignalLayerCnt( $inCAM, $jobId ) > 2 ) {

		my $inner = $self->GetJobPcbClassInner( $inCAM, $jobId );

		if ( defined $inner && $inner > 0 ) {

			push( @classes, $inner );
		}
	}

	my $resPcbClass = undef;

	if ( $lim eq "max" ) {

		$resPcbClass = max(@classes);
	}
	elsif ( $lim eq "min" ) {

		$resPcbClass = min(@classes);
	}

	return $resPcbClass;
}

#Return class of flex part of pcb saved as job attribute PcbClassFlex
sub GetJobFlexPcbClass {

	my $self = shift;

	my %info = CamAttributes->GetJobAttr(@_);

	return $info{"pcb_class_flex"};

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
				  parameters      => "layer_type+name+type+context+polarity+row"
	);

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gROWname} } ) ; $i++ ) {
		my %info = ();
		$info{"gROWrow"}        = ${ $inCAM->{doinfo}{gROWrow} }[$i];
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

# Return all layers from matrix as array of hash, which are layer_type == board and NC
# which contain info:
# - gROWname
# - gROWlayer_type
# - gROWcontext
sub GetNCLayers {
	my $self = shift;

	my @layers = $self->GetAllLayers(@_);

	@layers = grep { $_->{"gROWcontext"} eq "board" && ( $_->{"gROWlayer_type"} eq "rout" || $_->{"gROWlayer_type"} eq "drill" ) } @layers;

	return @layers;
}

#Return layer names by layer type
sub GetLayerByType {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $type  = shift;

	my @arr = $self->GetBoardLayers( $inCAM, $jobId );

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

# Creates new job
sub CreateJob {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobName = shift;
	my $db      = shift // "incam";

	$inCAM->COM(
				 "new_job",
				 "name"       => $jobName,
				 "db"         => $db,
				 "customer"   => "",
				 "disp_name"  => "",
				 "notes"      => "",
				 "attributes" => ""
	);

}

# Open given job
sub CloseJob {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	if ( $self->IsJobOpen( $inCam, $jobName ) ) {

		$inCam->COM( "close_job", "job" => "$jobName" );
	}
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
	my $inCAM   = shift;
	my $jobName = shift;

	# if 1, test if job is open cross whole site
	# if 0, test if job is open in in current toolkit
	my $wholeSite  = shift;
	my $openByUser = shift;    # if job is open, set which user has opened job

	my $result = 0;

	if ($wholeSite) {

		my $p = EnumsPaths->Client_INCAMTMPOTHER . GeneralHelper->GetGUID();
		$inCAM->COM( "list_open_jobs", "file" => $p );
		my @lines = @{ FileHelper->ReadAsLines($p) };
		unlink($p);

		foreach my $l (@lines) {

			my ( $job, $user ) = $l =~ /^(\w\d+)\s+(.*@.*\..*)/;

			if ( defined $job && $job =~ /$jobName/i ) {
				$result = 1;
				chomp($user);
				$$openByUser = $user;
				last;
			}
		}
	}
	else {

		$inCAM->COM( "is_job_open", "job" => "$jobName" );
		my $reply = $inCAM->GetReply();

		if ( $reply eq "yes" ) {
			$result = 1;
		}
		else {
			$result = 0;
		}
	}

	return $result;

}

# CheckIn job
sub CheckInJob {
	my $self    = shift;
	my $inCam   = shift;
	my $jobName = shift;

	if ( $self->IsJobOpen( $inCam, $jobName ) ) {

		$inCam->COM( "check_inout", "job" => "$jobName", "mode" => "in", "ent_type" => "job" );
	}
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
	my $self  = shift;
	my $inCAM = shift;

	# TODO - smazat log
	use Log::Log4perl qw(get_logger);
	my $logger = get_logger("testService");

	for my $i ( 1 .. 10 ) {

		$inCAM->INFO( "units" => 'mm', "angle_direction" => 'ccw', "entity_type" => 'root', "data_type" => 'JOBS_LIST' );

		if ( !defined $inCAM->{doinfo}{gJOBS_LIST} ) {
			$logger->error("Joblist not defined $i");
			sleep(1);

			# try do some query to INcAM, maybe JOBS_LIST will work than
			$inCAM->COM("get_user_name");
			$logger->error( "Test inCAM call: User is:" . $inCAM->GetReply() );

		}
		else {
			last;
		}
	}

	my $jobListRef = $inCAM->{doinfo}{gJOBS_LIST};

	die "InCAM error, unable to read database jobs from joblist.xml" if ( !defined $jobListRef );

	return @{$jobListRef};

}

# Return if job is imported and exit in incamdb
sub JobExist {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	my @list = $self->GetJobList($inCAM);

	my $exist = scalar( grep { $_ =~ /^$jobId$/i } @list );

	if ( $exist > 0 ) {
		return 1;
	}
	else {
		return 0;
	}

}

# Delete job
sub DeleteJob {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;

	if ( $self->JobExist( $inCAM, $jobId ) ) {
		$inCAM->COM( "delete_entity", "job" => $jobId, "name" => $jobId, "type" => "job" );
		return 1;
	}
	else {
		return 0;
	}
}

# Copy job
sub CopyJob {
	my $self        = shift;
	my $inCAM       = shift;
	my $sourceJobId = shift;
	my $targetJobId = shift;
	my $dbName      = shift // "incam";

	$inCAM->COM(
				 "copy_entity",
				 "type"           => "job",
				 "source_job"     => $sourceJobId,
				 "source_name"    => $sourceJobId,
				 "dest_job"       => $targetJobId,
				 "dest_name"      => $targetJobId,
				 "dest_database"  => $dbName,
				 "remove_from_sr" => "yes"
	);
}

# Return final thick of pcb including plating
# Units [µm]
# Note: Stiffener thickness is not  included!!
sub GetFinalPcbThick {
	my $self      = shift;
	my $inCAM     = shift;
	my $jobId     = shift;
	my $inclStiff = shift // 0;    # include stiffener

	my $thick;

	if ( $self->GetSignalLayerCnt( $inCAM, $jobId ) > 2 ) {

		my $stackup = Stackup->new( $inCAM, $jobId );

		$thick = $stackup->GetFinalThick();
	}
	else {

		$thick = HegMethods->GetPcbMaterialThick($jobId);
		$thick = $thick * 1000;

	}

	if ($inclStiff) {

		my @stiff = grep { $_->{"gROWlayer_type"} eq "stiffener" } $self->GetBoardBaseLayers( $inCAM, $jobId );

		foreach my $stiffL (@stiff) {

			my $side = ( $stiffL->{"gROWname"} =~ /c/ ) ? "top" : "bot";

			my $mInf = HegMethods->GetPcbStiffenerMat( $jobId, $side );
			my $mAdhInf = HegMethods->GetPcbStiffenerAdhMat( $jobId, $side );
			my @nAdh = split( /\s/, $mAdhInf->{"nazev_subjektu"} );

			my $t = $mInf->{"vyska"};
			$t =~ s/,/\./;
			$t *= 1000000;

			my $tAdh = $mAdhInf->{"vyska"};
			$tAdh =~ s/,/\./;
			$tAdh *= 1000000;

			$t += $tAdh;

			# If not core, copper thickness are included in material height
			if ( $mInf->{"dps_type"} !~ /core/i ) {

				if ( $mInf->{"nazev_subjektu"} =~ m/(\d+\/\d+)/ ) {
					my @cu = split( "/", $1 );
					$t -= $cu[0] if ( defined $cu[0] );
					$t -= $cu[1] if ( defined $cu[1] );
				}
			}

			die "Stiffener adhesive material thick was not found at material:" . $mInf->{"nazev_subjektu"}
			  if ( !defined $mInf->{"vyska"} || $mInf->{"vyska"} eq "" || $mInf->{"vyska"} == 0 );

			die "Stiffener thickness was not found at material:" . $mInf->{"nazev_subjektu"}
			  if ( !defined $mAdhInf->{"vyska"} || $mAdhInf->{"vyska"} eq "" || $mAdhInf->{"vyska"} == 0 );

			$thick += $t

		}
	}

	return $thick;
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamJob';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();

	my $jobId = "d152456";

	my @lim = CamJob->GetJobList($inCAM);

	print @lim

}

1;
