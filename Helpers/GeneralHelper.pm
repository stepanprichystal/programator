#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::GeneralHelper;

#3th party library
use Data::GUID;
use Cwd;
use Getopt::Std;
use File::Basename;
use File::Spec;
use Devel::StackTrace;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'CamHelpers::CamHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Add error message to special hash to array of error
sub AddError {
	my $self = shift;
	my $err  = shift;
	my $mess = shift;
	my $val  = shift;

	${$err}{"errors"}{"mess"} = $mess;
	${$err}{"errors"}{"val"}  = $val;

}

#Add warning message to special hash to array of error
sub AddWarning {
	my $self = shift;
	my $err  = shift;
	my $mess = shift;
	my $val  = shift;

	${$err}{"warnings"}{"mess"} = $mess;
	${$err}{"warnings"}{"val"}  = $val;
}

#Get absolute path of "root" directory, where are all modules and libraries are putted
# ussually it means like z:\windows\<e99|e101>\all\perl\
sub Root {

	#get path off this file GeneralHelper.pm
	my $generalHelperPath = File::Spec->rel2abs(__FILE__);
	my ( $name, $path2, $suffix ) = fileparse( $generalHelperPath, @suffixlist );

	#get "root" directory, where are all scripts and modules
	return dirname($path2);

}

# Return root direcotry of hooks (server or user hooks)
sub RootHooks {
	my $self = shift;
	my $inCAM = shift;

	my $root;

	# get path off file which is executing

	my $p = Cwd::abs_path($0);

	# script is executed from user hook  
	if ( $p =~ /[\\\/]users[\\\/](\w+)[\\\/]/i ) {
		$root = EnumsPaths->InCAM_users . $1 . "\\hooks\\";

	}
	elsif($p =~ /^c:/i ){
		
		# or it is user local disc c: (not site disc)
		
		$root = EnumsPaths->InCAM_users . CamHelper->GetUserName($inCAM) . "\\hooks\\";
	}
	else {
		$root = EnumsPaths->InCAM_hooks;
	}

	return $root;

}

#Get absolute path of "root" directory, where are all scripts are putted
# ussually it means something like z:\sys\scripts\
sub RootScripts {

	my $path;

	my $ZLoaded = 0;
	foreach my $p (@INC) {
		if ( $p =~ m/z:/ ) {
			$ZLoaded = 1;
		}
	}

	#if z path was not find in @INC, it means, script run in development mode
	#otherwise in deploy mode

	if ($ZLoaded) {

		$path = "$ENV{'GENESIS_DIR'}/sys/scripts/";
	}
	else {

		$path = GeneralHelper->Root() . "\\";
	}

	return $path;

}

#Return unique Id
sub GetGUID {

	my $guid = Data::GUID->new;

	my $guidStr = $guid->as_string;

	return $guidStr;

	#return  int(rand(1000000000000000));

}

#Return unique Id
sub GetNumUID {
	my $self   = shift;
	my $length = shift;

	unless ($length) {

		$length = 10;
	}

	return int( rand( 10**$length ) );

}

#Trim whitespaces "\s"
sub Trim_s() {
	my $self = shift;
	my $str  = shift;

	$str =~ s/\s//g;

	return $str;
}

#Trim whitespaces "\s" and nonalfanumercial chars "\W"
sub Trim_s_W() {
	my $self = shift;
	my $str  = shift;

	$str =~ s/\s|\W//g;

	return $str;
}

#Add slash in the end of string if doesn't exsits
sub AddSlash {
	my $self = shift;
	my $path = shift;

	unless ( substr( $path, -1 ) eq "/" ) {
		$path .= "/";
	}

	return $path;
}

#Equals no case sensitive
#sub EqualsNS {
#	my $self = shift;
#	my $frst = shift;
#	my $sec  = shift;
#
#	if ( $frst =~ /$sec/i ) {
#		return 1;
#	}
#	else {
#		return 0;
#	}
#}

#Compare two variables
sub RegexEquals {
	my $self = shift;
	my $frst = shift;
	my $sec  = shift;

	if ( $frst =~ /$sec/i ) {
		return 1;
	}
	else {
		return 0;
	}
}

#Return hash, where keys are switches and values are values of switches (eg.: perl program.pl -i "d5400")
sub GetCmdArgs {

	my %options = ();
	getopts( "i:", \%options );

	return %options;
}

#Test if environment is deploy
sub DeployEnvironment {
	if ( -e "../Develop" ) {
		return 0;
	}

	return 1;
}

#Test if environment is deploy
sub IsUndef {
	my $self  = shift;
	my $value = shift;

	print $value;

	unless ($value) {

		return 1;
	}
	return 0;
}

#print message with new line to standard output
sub Print {
	my $self = shift;
	my $mess = shift;

	print $mess. "\n";
}

#Special method sets absolute paths to modules.
#Necesserry for debugging in ECLIPSE
sub SetPaths {

	# detection deploy/develop environment
	if ( GeneralHelper->DeployEnvironment() ) {
		print STDERR "Deploy environment!!!\n\n";

		#paths on modules on my computer (SPR)
		#use lib qw( C:/Vyvoj/Perl/prace/Helpers C:/Vyvoj/Perl/prace/Widgets C:/Vyvoj/Perl/prace/Enums);
	}

}



sub GetLastInCAMVersion {
	my $self = shift;

	my $inCAMPath = EnumsPaths->InCAM_serverDisc;
	my @version   = ();

	opendir( DIR, $inCAMPath ) or die "cannot open $inCAMPath " . $!;

	while ( my $file = readdir(DIR) ) {

		my $module;

		if ( $file =~ m/^\./ ) {
			next;
		}

		if ( $file =~ /^(\d+\.\d+)(SP(\d+))?/i ) {
			push( @version, $file );
		}
	}

	my $maxNum = 0;
	my $maxNumName;
	foreach my $file (@version) {

		$file =~ m/^(\d+\.\d+)(SP(\d+))?/i;

		my $num = defined $3 ? $1 . $3 : $1;

		if ( $num > $maxNum ) {
			$maxNum     = $num;
			$maxNumName = $file;
		}
	}

	if ($maxNumName) {

		return $inCAMPath . $maxNumName . "\\";
	}
	else {

		print STDERR "Error when getting latest version of InCAM\n";
		return 0;
	}
}

# Return if script is running on TPV server
# TPV server is computer, which has set ENV variable TPV_ServerVersion
sub IsTPVServer {
	my $self = shift;

	my $serverComp = $ENV{'TPV_ServerComputer'};

	unless ($serverComp) {
		return 0;
	}
	else {
		return 1;
	}

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}
1;
