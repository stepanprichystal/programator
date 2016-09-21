#-------------------------------------------------------------------------------------------#
# Description: Helper pro obecne operace se soubory
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Helpers::FileHelper;

#3th party library
use English;
use strict;
use File::Basename;
use File::Spec;

#local library

use aliased 'Helpers::GeneralHelper';
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

#Return file name from full path
sub GetFileName {

	my $self = shift;
	my $path = shift;

	if ($path) {

		return basename($path);

	}
}

sub Open {

	my $self  = shift;
	my $path  = shift;
	my $write = shift;

	my $f         = undef;
	my $operation = "<$path";

	if ($write)    #write and create
	{
		$operation = "+>$path";
	}

	if ( open( $f, $operation ) ) {
		return $f;
	}
	else {
		return 0;
	}
}

sub Close {
	my $self = shift;
	my $f    = shift;

	if ( close($f) ) {
		return 1;
	}
	else {
		return 0;
	}
}

#Check if file/directory exists by fullname
sub Exists {
	my $self = shift;
	my $dir  = shift;

	if ( -e $dir ) {
		return 1;
	}
	else {
		return 0;
	}
}

#Check if file/directory exists by pattern
sub ExistsByPattern() {
	my $self     = shift;
	my $path     = shift;
	my $partName = shift;

	$path = GeneralHelper->AddSlash($path);

	if ( glob( $path . "*" . $partName . "*" ) ) {
		return 1;
	}
	else {
		return 0;
	}
}

#Return full path + file name by pattern contain in file name
sub GetFileNameByPattern() {
	my $self     = shift;
	my $path     = shift;
	my $partName = shift;    #for example partial name of file

	#$path = GeneralHelper->AddSlash($path);

	my $pattern = $path . $partName . "*";

	my @files = glob($pattern);
	if (@files) {
		return $files[0];
	}
	else {
		return 0;
	}
}

#Return file content as string
sub ReadAsString {
	my $self = shift;
	my $path = shift;

	my $str = undef;

	my $f = FileHelper->Open($path);
	$str = join( "", <$f> );
	FileHelper->Close($f);

	return $str;
}

#Return file content as array with lines as items
sub ReadAsLines {
	my $self = shift;
	my $path = shift;

	my $l     = undef;
	my $f     = FileHelper->Open($path);
	my @lines = <$f>;

	FileHelper->Close($f);

	return \@lines;
}

#Write lines to begining of file
sub WriteLines {
	my $self  = shift;
	my $path  = shift;
	my @lines = @{ shift(@_) };

	my $f = FileHelper->Open( $path, 1 );

	print $f @lines;

	FileHelper->Close($f);
}

#Write string to begining of file
sub WriteString {
	my $self = shift;
	my $path = shift;
	my $str  = shift;

	my $f = FileHelper->Open( $path, 1 );

	print $f $str;

	FileHelper->Close($f);
}

#Delete file
sub DeleteFile {

	my $self = shift;
	my $path = shift;
	unlink $path;
}

#Delete temp files from Temp directory
sub DeleteTempFiles {

	#my $tempPath = File::Spec->rel2abs(  dirname(dirname( __FILE__ )))."/Temp";

	opendir( DIR, GeneralHelper->Root() . '/Temp/' ) or die $!;
	my $age = 10;    # 3600 seconds in a day

	while ( my $file = readdir(DIR) ) {

		$file = GeneralHelper->Root() . '/Temp/' . $file;

		#get file attributes
		my @stats = stat($file);

		if ( time() - $stats[9] > $age ) {
			FileHelper->DeleteFile($file);
		}
	}
}

#Delete temp files from path EnumsPaths->Client_INCAMTMPSCRIPTS
# only files younger than 2 hours will by kept
sub DeleteScriptTmpFiles {
	my $self    = shift;
	my $fileAge = shift;    #all files older than <$fileAge> will be removed

	unless ( defined $fileAge ) {

		$fileAge = 10;
	}

	$self->DeleteTempFilesFrom( EnumsPaths->Client_INCAMTMPSCRIPTS, $fileAge );

}

#Delete temp files from Temp directory
sub DeleteTempFilesFrom {
	my $self    = shift;
	my $path    = shift;
	my $fileAge = shift;    #all files older than <$fileAge> will be removed

	#my $tempPath = File::Spec->rel2abs(  dirname(dirname( __FILE__ )))."/Temp";

	if ( opendir( DIR, $path ) ) {

		my $age = $fileAge;           # 3600 seconds in a day

		while ( my $file = readdir(DIR) ) {

			$file = GeneralHelper->Root() . '/Temp/' . $file;

			#get file attributes
			my @stats = stat($file);

			if ( time() - $stats[9] > $age ) {
				FileHelper->DeleteFile($file);
			}
		}
	}

}

#Clear all rows from file
sub ClearFile {
	my $self = shift;
	my $path = shift;

	FileHelper->DeleteFile($path);
	my $f = FileHelper->Open( $path, 1 );
	FileHelper->Close($f);
}

#Remove non/printable char from file
sub RemoveNonPrintableChar {
	my $self = shift;
	my $p    = shift;

	unless ( -e $p ) {
		return 0;
	}

	my $fName = GeneralHelper->GetGUID();

	open my $IN, "<$p" or die $!;
	open my $OUT, '>' . GeneralHelper->Root() .. '/Temp/' . $fName or die $!;

	while ( my $l = <$IN> ) {
		$l =~ s/[^[:print:]]+//g;
		print $OUT $l;
	}

	close $OUT;

	return $fName;
}

#Stupid way how to find, if xml contain any nonprintable chars or
#if isn't valid generally
sub IsXMLValid {
	my $self = shift;
	my $p    = shift;
	my $f    = undef;

	eval {

		#try {
		$f = FileHelper->Open($p);
		XMLin($f);
		FileHelper->Close($f);
		return 1;
	};

	#catch {
	if ($@) {
		print STDERR "XML file: " . $p . " isn't probably valid.\n";
		FileHelper->Close($f);
		return 0;
	}

}

#Change encoding from
sub ChangeEncoding {
	my $self    = shift;
	my $p       = shift;
	my $encFrom = shift;
	my $encTo   = shift;

	unless ( -e $p ) {
		return 0;
	}

	my $fName = GeneralHelper->GetGUID();

	open my $IN, "<:encoding($encFrom)", $p or die $!;
	open my $OUT, ">:$encTo", EnumsPaths->Client_INCAMTMPOTHER . $fName or die $!;
	print $OUT $_ while <$IN>;
	close $OUT;

	return $fName;
}

#Create backup from file, save it to Temp/ directory and return unique name.
sub CreateBackup {
	my $self    = shift;
	my $pSource = shift;

	unless ( -e $pSource ) {
		return 0;
	}

	my $bckName = GeneralHelper->GetGUID();
	my $newPath = GeneralHelper->Root() . '/Temp/' . $bckName;
	if ( FileHelper->Copy( $pSource, $newPath ) ) {
		return $bckName;
	}
	else {

		return 0;
	}
}

#make a copy of file
sub Copy {
	my $self    = shift;
	my $pSource = shift;
	my $pDest   = shift;

	unless ( ( -e $pSource ) || ( -f $pDest ) ) {
		return 0;
	}

	open( DATA1, "<$pSource" );
	open( DATA2, ">$pDest" );

	while (<DATA1>) {
		print DATA2 $_;
	}
	close(DATA1);
	close(DATA2);

	return 1;
}

# delete all tmp files in the CNC network disk for job.
# made RVI
sub DeleteCNCfiles {
	my $self           = shift;
	my $jobName        = shift;
	my $CNCnetworkDisk = '//192.168.2.65/f';

	my $folderName = substr( $jobName, 0, 3 );

	opendir( DIR, "$CNCnetworkDisk/$folderName" );
	while ( ( my $fileName = readdir(DIR) ) ) {
		if ( $fileName =~ /^$jobName/ ) {
			unlink "$CNCnetworkDisk/$folderName/$fileName";
		}
		my $bigLetter = uc($jobName);

		if ( $fileName =~ /^$bigLetter/ ) {
			unlink "$CNCnetworkDisk/$folderName/$fileName";
		}
	}
	close DIR;
}

1;
