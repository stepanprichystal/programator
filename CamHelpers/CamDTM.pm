#-------------------------------------------------------------------------------------------#
# Description: Helper module for InCAM Drill tool manager
# Author:SPR
#-------------------------------------------------------------------------------------------#

package CamHelpers::CamDTM;


#3th party library
use Genesis;
use strict;
use warnings;

#loading of locale modules

use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';


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

		$row =~ m/NAME=(\w*)/gi;
		if ( $1 && $1 ne "" ) {
			push( @names, $1 );
		}
	}

	close($f);
	
	return @names
}

# Return value of user column in DTM
# For everz row in DTM, return value of user column in hash
# Result: array of hashes
sub GetDTMUserColumns {
	my $self  = shift;
	my $inCAM = shift;
	my $jobId = shift;
	my $step  = shift;
	my $layer = shift;

	#get values of user columns for each tool
	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'layer',
				  entity_path     => "$jobId/$step/$layer",
				  data_type       => 'TOOL',
				  options         => "break_sr"
	);

	my @gTOOLuser_des = @{ $inCAM->{doinfo}{gTOOLuser_des} };

	my @clmnName = CamHelpers::CamDTM->GetDTMUserColNames($inCAM);

	 

	my @a   = ();
	my $cnt = scalar(@gTOOLuser_des);

	#for each tool in DTM,  create hash: column name/column value
	for ( my $i = 0 ; $i < $cnt ; $i++ ) {

		my %info = ();
		my @clmnVal = split( ';', $gTOOLuser_des[$i] );

		#print "Val for tool :" . $gTOOLuser_des[$i] . "\n";

		#print scalar(@clmnName);

		for ( my $j = 0 ; $j < scalar(@clmnName) ; $j++ ) {

			$info{ $clmnName[$j] } = $clmnVal[$j];

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

1;
