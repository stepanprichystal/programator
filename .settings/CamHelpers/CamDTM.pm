#-------------------------------------------------------------------------------------------#
# Description: Helper module for InCAM Drill tool manager
# Author:SPR
#-------------------------------------------------------------------------------------------#
package CamHelpers::CamDTM;

#3th party library
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamLayer';
use aliased 'Enums::EnumsDrill';
use aliased 'Enums::EnumsGeneral';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'CamHelpers::CamDrilling';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

# Return array of all user column names
# column are defined in file "\\hooks\\dtm_user_columns"
sub GetDTMUserColNames {
	my $self  = shift;
	my $inCAM = shift;

	my $usrName = CamHelper->GetUserName($inCAM);

	my @names = ();

	#determine if take user or site file dtm_user_columns
	my $pUserClmn = EnumsPaths->InCAM_users . $usrName . "\\hooks\\dtm_user_columns";

	unless ( -e $pUserClmn ) {
		$pUserClmn = EnumsPaths->InCAM_hooks . "dtm_user_columns";
	}

	#open file and read onlz names of column
	my $f;
	open( $f, $pUserClmn ) or die "Open failed: $!";

	while ( my $row = <$f> ) {

		if ( $row =~ m/NAME=(\w*)/gi ) {

			my $name = $1;
			$name =~ s/\s//g;
			push( @names, $name );
		}
	}

	close($f);

	return @names;
}

# Return value of user column in DTM
# For everz row in DTM, return value of user column in hash
# Result: array of hashes
sub GetDTMUserColumns {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	#get values of user columns for each tool
	if ($breakSR) {
		$inCAM->INFO(
					  units           => 'mm',
					  angle_direction => 'ccw',
					  entity_type     => 'layer',
					  entity_path     => "$jobId/$step/$layer",
					  data_type       => 'TOOL',
					  options         => "break_sr"
		);
	}
	else {
		$inCAM->INFO(
					  units           => 'mm',
					  angle_direction => 'ccw',
					  entity_type     => 'layer',
					  entity_path     => "$jobId/$step/$layer",
					  data_type       => 'TOOL'
		);
	}

	my @gTOOLuser_des = @{ $inCAM->{doinfo}{gTOOLuser_des} };

	my @clmnName = $self->GetDTMUserColNames($inCAM);

	my @a   = ();
	my $cnt = scalar(@gTOOLuser_des);

	#for each tool in DTM,  create hash: column name/column value
	for ( my $i = 0 ; $i < $cnt ; $i++ ) {

		my %info = ();
		my @clmnVal = split( ';', $gTOOLuser_des[$i] );

		#print "Val for tool :" . $gTOOLuser_des[$i] . "\n";

		#print scalar(@clmnName);

		for ( my $j = 0 ; $j < scalar(@clmnName) ; $j++ ) {

			if ( $clmnName[$j] eq EnumsDrill->DTMclmn_DEPTH ) {
				my $depth = $clmnVal[$j];
				if ( defined $depth ) {
					$depth =~ s/,/\./;
					$depth = sprintf( "%.2f", $depth );
					$info{ $clmnName[$j] } = $depth;
				}

			}
			else {
				$info{ $clmnName[$j] } = $clmnVal[$j];
			}

			#print "YDEYDE";
		}

		push( @a, \%info );
	}

	#	print "\n\n==========================BEFOE RETURN =============================================\n\n";
	#
	#	for ( my $i = 0 ; $i < scalar(@a) ; $i++ ) {
	#		print "fff";
	#
	#		my %h = %{ $a[$i] };
	#
	#		#print "Nastroj: ". $h->{"drill_size"}.$h->{"depth"}."\n";
	#
	#		foreach my $key ( keys %h ) {
	#
	#			# do whatever you want with $key and $value here ...
	#			my $value = $h{$key};
	#			print "Nastroj:    $key costs $value\n";
	#		}
	#
	#	}
	#
	#	print "\n\n========================== BEFROE RETURN END===================================\n\n";

	return @a;
}

# Return info about tool in DTM
# Result: array of hashes. Each has contain info about row in DTM
sub GetDTMTools {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	# 1) Get tool user columns
	my @userTools = $self->GetDTMUserColumns( $inCAM, $jobId, $step, $layer, $breakSR );

	# 2) get values of user columns for each tool

	my @tools = ();

	if ($breakSR) {
		$inCAM->INFO(
					  units           => 'mm',
					  angle_direction => 'ccw',
					  entity_type     => 'layer',
					  entity_path     => "$jobId/$step/$layer",
					  data_type       => 'TOOL',
					  options         => "break_sr"
		);

	}
	else {
		$inCAM->INFO(
			units           => 'mm',
			angle_direction => 'ccw',
			entity_type     => 'layer',
			entity_path     => "$jobId/$step/$layer",
			data_type       => 'TOOL'

		);
	}

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gTOOLnum} } ) ; $i++ ) {
		my %info = ();
		$info{"gTOOLnum"}         = ${ $inCAM->{doinfo}{gTOOLnum} }[$i];
		$info{"gTOOLcount"}       = ${ $inCAM->{doinfo}{gTOOLcount} }[$i];
		$info{"gTOOLshape"}       = ${ $inCAM->{doinfo}{gTOOLshape} }[$i];
		$info{"gTOOLtype"}        = ${ $inCAM->{doinfo}{gTOOLtype} }[$i];
		$info{"gTOOLtype2"}       = ${ $inCAM->{doinfo}{gTOOLtype2} }[$i];
		$info{"gTOOLmin_tol"}     = ${ $inCAM->{doinfo}{gTOOLmin_tol} }[$i];
		$info{"gTOOLmax_tol"}     = ${ $inCAM->{doinfo}{gTOOLmax_tol} }[$i];
		$info{"gTOOLfinish_size"} = ${ $inCAM->{doinfo}{gTOOLfinish_size} }[$i];
		$info{"gTOOLdrill_size"}  = ${ $inCAM->{doinfo}{gTOOLdrill_size} }[$i];
		$info{"gTOOLbit"}         = ${ $inCAM->{doinfo}{gTOOLbit} }[$i];
		$info{"gTOOLslot_len"}    = ${ $inCAM->{doinfo}{gTOOLslot_len} }[$i];
		$info{"userColumns"}      = $userTools[$i];

		push( @tools, \%info );

	}

	return @tools;
}

# Returnt tool from DTM by type
sub GetDTMToolsByType {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $type    = shift;    # standard, plated, non_plated, press_fit
	my $breakSR = shift;

	my @tools = $self->GetDTMTools( $inCAM, $jobId, $step, $layer, $breakSR );

	@tools = grep { $_->{"gTOOLtype2"} eq $type } @tools;

	return @tools;
}

# Returnt tool type of DTM vrtane/vysledne
sub GetDTMType {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	$inCAM->INFO(
				  "units"           => 'mm',
				  "angle_direction" => 'ccw',
				  "entity_type"     => 'layer',
				  "entity_path"     => "$jobId/$step/$layer",
				  "data_type"       => 'TOOL_USER'
	);

	my $toolType = $inCAM->{doinfo}{"gTOOL_USER"};

	return $toolType;
}

# Return default DTM type for step
# If panel level step has not DTM, go through nested step and inherit type form them
# If neither panel level nor nested steps have DTM type, return undef
sub GetDTMDefaultType {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $breakSR = shift;

	# 1) Get DTM type from step or from child steps
	my $DTMType = $self->GetDTMType( $inCAM, $jobId, $step, $layer );

	if ( $breakSR && ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) ) {

		my @childSteps = CamStepRepeat->GetUniqueNestedStepAndRepeat( $inCAM, $jobId, $step );

		if ( scalar(@childSteps) ) {

			foreach my $s (@childSteps) {
				my $childDTMType = $self->GetDTMType( $inCAM, $jobId, $s->{"stepName"}, $layer );
				if ( $childDTMType eq EnumsDrill->DTM_VRTANE || $childDTMType eq EnumsDrill->DTM_VYSLEDNE ) {
					$DTMType = $childDTMType;
					last;
				}
			}
		}
	}

	# 2) if still type is not known, we can set default type
	# 'vrtane', if layer is nonplated
	if ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) {

		my %l = ( "gROWname" => $layer );
		my @la = ( \%l );

		CamDrilling->AddNCLayerType( \@la );

		if ( !$l{"plated"} ) {
			$DTMType = EnumsDrill->DTM_VRTANE;
		}
	}

	# 3) if still type is not known, some plated layers has predefined type
	if ( $DTMType ne EnumsDrill->DTM_VRTANE && $DTMType ne EnumsDrill->DTM_VYSLEDNE ) {

		my %l = ( "gROWname" => $layer );
		my @la = ( \%l );

		CamDrilling->AddNCLayerType( \@la );

		if (    $l{"type"} eq EnumsGeneral->LAYERTYPE_plt_fDrill
			 || $l{"type"} eq EnumsGeneral->LAYERTYPE_plt_dcDrill
			 || $l{"type"} eq EnumsGeneral->LAYERTYPE_plt_nMill )
		{
			$DTMType = EnumsDrill->DTM_VYSLEDNE;
		}
	}

	return $DTMType;
}

# Set new tools to DTM
sub SetDTMTools {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my @tools   = @{ shift(@_) };
	my $DTMType = shift;            # vysledne, vrtane

	my @userClmns = CamHelpers::CamDTM->GetDTMUserColNames($inCAM);    # User column name

	CamHelper->SetStep( $inCAM, $step );
	CamLayer->WorkLayer( $inCAM, $layer );

	unless ( defined $DTMType ) {
		$DTMType = $self->GetDTMType( $inCAM, $jobId, $step, $layer );
	}

	$inCAM->COM('tools_tab_reset');

	foreach my $t (@tools) {

		# change type values ( command tool return values non_plated and plated, but tools_tab_set consum plate, nplate)
		my $toolType = $t->{"gTOOLtype"};
		$toolType =~ s/^plated$/plate/;
		$toolType =~ s/^non_plated$/nplate/;

		# Prepare user column values
		my @vals = ();
		foreach my $userClmn (@userClmns) {

			my $v = $t->{"userColumns"}->{$userClmn};
			unless ( defined $v ) {
				$v = "";
			}
			push( @vals, $v );
		}

		my $userColumns = join( "\\;", @vals );

		$inCAM->COM(
					 'tools_tab_add',
					 "num"         => $t->{"gTOOLnum"},
					 "type"        => $toolType,
					 "type2"       => $t->{"gTOOLtype2"},
					 "min_tol"     => $t->{"gTOOLmin_tol"},
					 "max_tol"     => $t->{"gTOOLmax_tol"},
					 "bit"         => $t->{"gTOOLbit"},
					 "finish_size" => $t->{"gTOOLfinish_size"},
					 "drill_size"  => $t->{"gTOOLdrill_size"},
					 "shape"       => $t->{"gTOOLshape"},
					 "user_des"    => $userColumns
		);

		#		$inCAM->INFO(
		#					  units           => 'mm',
		#					  angle_direction => 'ccw',
		#					  entity_type     => 'layer',
		#					  entity_path     => "$jobId/$step/$layer",
		#					  data_type       => 'TOOL',
		#					  options         => "break_sr"
		#		);

	}

	$inCAM->COM( 'tools_set', layer => $layer, thickness => '0', user_params => $DTMType );

	# toto tady musi byt, jinak po tools_set nefunguje spravne shape slot/hole v DTM
	$inCAM->COM( 'tools_show', "layer" => "$layer" );

	#$inCAM->COM('tools_recalc');

	#				$inCAM->INFO(
	#							  units           => 'mm',
	#							  angle_direction => 'ccw',
	#							  entity_type     => 'layer',
	#							  entity_path     => "$jobId/$step/$layer",
	#							  data_type       => 'TOOL',
	#							  options         => "break_sr"
	#				);

	#print 1;

	#$inCAM->COM( 'tools_set', layer => $layer, thickness => '0', user_params => $DTMType );

	#$inCAM->COM('tools_recalc');

	#print STDERR "ddd";

	# smayat

}

# Set new tools to DTM
sub SetDTMTable {
	my $self    = shift;
	my $inCAM   = shift;
	my $jobId   = shift;
	my $step    = shift;
	my $layer   = shift;
	my $DTMType = shift;    # vysledne, vrtane

	$inCAM->COM( 'tools_set', layer => $layer, thickness => '0', user_params => $DTMType );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'CamHelpers::CamDTM';
	use aliased 'Packages::InCAM::InCAM';

	my $inCAM = InCAM->new();
	my $jobId = "f13608";

	#my $step  = "mpanel_10up";

	my @result = CamDTM->GetDTMTools( $inCAM, $jobId, "o+1", "m" );
	@result = CamDTM->GetDTMToolsByType( $inCAM, $jobId, "o+1", "m", "press_fit" );

	#my $self             = shift;

	print 1;

}

1;
