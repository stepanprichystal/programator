
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::Comments;

#3th party library
use strict;
use warnings;
use Switch;
use File::Basename;
use File::Copy;
use POSIX qw(strftime);
use File::Path 'rmtree';

#local library

use aliased 'Programs::Comments::CommLayout::CommLayout';
use aliased 'Programs::Comments::CommLayout::CommSnglLayout';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Comments::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorableMngr';
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"}         = shift;
	$self->{"jobId"}         = shift;
	$self->{"addDefaulComm"} = shift // 0;

	$self->{"commDir"} = JobHelper->GetJobOutput( $self->{"jobId"} ) . "comments\\";
	unless ( -e $self->{"commDir"} ) {
		mkdir( $self->{"commDir"} ) or die "$_";
	}

	$self->{"commArchiveDir"} = $self->{"commDir"} . "archive\\";

	$self->{"mainFile"} = $self->{"commDir"} . "comments.json";

	$self->{"commLayout"}  = CommLayout->new();
	$self->{"jsonStrMngr"} = JsonStorableMngr->new( $self->{"mainFile"} );

	$self->__LoadFromJob();

	$self->__AddDefaultComm() if ( $self->{"addDefaulComm"} );

	$self->__ClearOldFiles();

	return $self;
}

# Return 1 if exists at least one comment
sub Exists {
	my $self = shift;

	if ( scalar( $self->{"commLayout"}->GetAllComments() ) ) {
		return 1;
	}
	else {
		return 0;
	}

}

sub CheckBeforeSave {
	my $self    = shift;
	my $errMess = shift;

	my $result = 1;

	# Do some checks

	# 1) Check if files has unique name
	my @comm = $self->{"commLayout"}->GetAllComments();
	for ( my $i = 0 ; $i < scalar(@comm) ; $i++ ) {

		my $commLayout = $comm[$i];

		my @n = ();
		for ( my $j = 0 ; $j < scalar( $commLayout->GetAllFiles() ) ; $j++ ) {

			push( @n, $self->{"commLayout"}->GetFullFileNameById( $i, $j ) );
		}

		my %hash;
		$hash{$_}++ foreach (@n);

		foreach my $duplname ( grep { $hash{$_} > 1 } keys %hash ) {

			push( @{$errMess}, "Duplicate (" . $hash{$duplname} . "x) output file name: $duplname in comment number: " . ( $i + 1 ) );
			$result = 0;
		}
	}

	# 2) Check if text is not empty
	for ( my $i = 0 ; $i < scalar(@comm) ; $i++ ) {

		my $commLayout = $comm[$i];

		my $text = $commLayout->GetText();
		$text =~ s/\s//g;
		if ( !defined $text || $text eq "" ) {

			push( @{$errMess}, "No text in comment number: " . ( $i + 1 ) );
			$result = 0;
		}
	}

	return $result;

}

sub Save {
	my $self = shift;

	my @err = ();

	my $result = $self->CheckBeforeSave( \@err );

	# Do  checks

	# Save on disc
	if ($result) {

		foreach my $comm ( $self->{"commLayout"}->GetAllComments() ) {

			$comm->SetStoredOnDisc(1);
		}

		$result = $self->{"jsonStrMngr"}->StoreData( $self->{"commLayout"} );
	}
	else {

		die "Error during save:" . join( "; ", @err );
	}

	return $result;

}

sub SnapshotCAM {
	my $self     = shift;
	my $directly = shift // 1;
	my $p        = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	unless ($directly) {

		my $mess = "Prepare what you want to snapshot...";
		$inCAM->PAUSE($mess);
	}

	my $fileName = "CAM_" . GeneralHelper->GetNumUID();
	my $pTmp     = $self->{"commDir"} . $fileName;
	$inCAM->COM( "save_snapshot", "path" => $pTmp . ".png" );

	if ( -e $pTmp . ".png" ) {

		# Unlink extra files: .nte;  .txt;
		unlink( $pTmp . ".nte" );
		unlink( $pTmp . ".txt" );

		$$p = $pTmp . ".png";
	}
	else {
		$result = 0;
	}

	return $result;
}

sub SnapshotGS {
	my $self = shift;
	my $p    = shift;

	my $result = 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	my $mess = "1) Prepare what you want to snapshot by GreenShot.  2) Press \"Print Screen\ and store photo via special icon..  3) Press Resume";
	$inCAM->PAUSE($mess);

	my $fileName = "CAM_" . GeneralHelper->GetNumUID();
	$$p = $self->{"commDir"} . $fileName . ".png";

	my $pSrc = EnumsPaths->Client_INCAMTMPOTHER . "snapshot" . ".png";

	if ( -e $pSrc ) {
		move( $pSrc, $$p );

	}
	else {

		$result = 0;

	}

	return $result;
}

sub ChooseFile {
	my $self = shift;
	my $p    = shift;
	my $frm  = shift;

	my $result = 1;

	my $dirDialog = Wx::FileDialog->new( $frm, "Select directory with data", "c:/pcb" );

	if ( $dirDialog->ShowModal() != &Wx::wxID_CANCEL ) {

		$$p = ( $dirDialog->GetPaths() )[0];

	}
	else {

		$result = 0;
	}
	return $result;

}

sub GetLayout {
	my $self = shift;

	return $self->{"commLayout"};
}

# --------------------------------------
# METHODS FOR BUILDING COMMENT general
# --------------------------------------
sub AddComment {
	my $self = shift;
	my $type = shift;

	my $comment = $self->{"commLayout"}->AddComment($type);

	return $comment;
}

sub RemoveComment {
	my $self      = shift;
	my $commentId = shift;

	die "Comment id: $commentId doesn't exist" if ( $commentId < 0 || $commentId >= scalar( $self->{"commLayout"}->GetAllComments() ) );

	$self->{"commLayout"}->RemoveComment($commentId);
}

# Delete all coments
# Move them to archive backup
# Delete old backups from archive
# Save
sub ClearCoomments {
	my $self = shift;

	# 1) Move comment to archive
	my $archRoot = $self->{"commArchiveDir"};
	mkdir($archRoot) or die "File  cannot be created: $!" unless ( -e $archRoot );

	my $now_string = strftime "%Y_%m_%d_%H_%M", localtime;
	my $arch = $self->{"commDir"} . "archive\\$now_string";

	mkdir($arch) or die "File $arch cannot be created: $!" unless ( -e $arch );

	opendir( DIR, $self->{"commDir"} ) or die $!;

	while ( my $file = readdir(DIR) ) {

		next if ( $file !~ /^cam/i && $file !~ /^comments/i );
		copy( $self->{"commDir"} . $file, $arch . "\\$file" );
	}
	close(DIR);

	# 2) Delete old backups from archive (older than one month)
	my $deleteArchive = 1;
	opendir( DIR, $archRoot ) or die $!;

	while ( my $f = readdir(DIR) ) {

		next if ( $f =~ /^\.$/ );
		next if ( $f =~ /^\.\.$/ );

		my $path = $archRoot . $f;

		my @stats = stat($path);

		# remove older than $olderThan months
		if ( ( time() - $stats[10] ) > $deleteArchive * 60 * 60 * 24 * 30 ) {
			rmtree($path);
		}
	}
	close(DIR);

	# 3) Remove all coments
	my @comm = $self->{"commLayout"}->GetAllComments();

	for ( my $i = scalar(@comm) - 1 ; $i >= 0 ; $i-- ) {
		$self->{"commLayout"}->RemoveComment($i);
	}

	# 4) Save
	$self->Save();
	
	$self->__ClearOldFiles();
}

# Move last comment from archive
# Save
sub RestoreCoomments {
	my $self = shift;

	my $result = 1;

	my $archRoot = $self->{"commArchiveDir"};

	# Get last backup dir
	my $lastMod = undef;
	my $path    = undef;
	opendir( DIR, $archRoot ) or die $!;
	while ( my $file = readdir(DIR) ) {

		next if ( $file =~ /\./ );

		my $lastModCurr = ( stat( $archRoot . $file ) )[9];
		if ( !defined $lastMod || $lastMod < $lastModCurr ) {

			$lastMod = $lastModCurr;
			$path    = $archRoot . $file;
		}

	}
	close(DIR);

	if ( defined $path ) {

		# copy all files to main folder
		opendir( DIR, $path ) or die $!;
		while ( my $file = readdir(DIR) ) {

			next if ( $file =~ /^\.+$/ );

			copy( $path . "\\" . $file, $self->{"commDir"} . $file );
		}

		close(DIR);

		# Remove backup
		rmtree($path);

		$self->__LoadFromJob();
	}
	else {

		$result = 0;
	}

	return $result;

}

sub MoveComment {
	my $self      = shift;
	my $commentId = shift;
	my $type      = shift;

	my $moved = 1;

	if ( $type eq "up" ) {
		if ( $commentId - 1 < 0 ) {
			$moved = 0;
		}
		else {
			$self->{"commLayout"}->MoveUp($commentId);
		}

	}
	else {
		if ( $commentId + 1 >= scalar( $self->{"commLayout"}->GetAllComments() ) ) {
			$moved = 0;
		}
		else {
			$self->{"commLayout"}->MoveDown($commentId);
		}
	}

	return $moved

}

sub ChangeType {
	my $self      = shift;
	my $commentId = shift;
	my $type      = shift;

	$self->{"commLayout"}->GetCommentById($commentId)->SetType($type);

}

# --------------------------------------
# METHODS FOR BUILDING COMMENT single
# --------------------------------------

sub SetType {
	my $self      = shift;
	my $commentId = shift;

	$self->{"type"} = shift;
}

sub SetText {
	my $self      = shift;
	my $commentId = shift;
	my $text      = shift;

	my $comm = $self->{"commLayout"}->GetCommentById($commentId);
	$comm->SetText($text);
}

sub AddFile {
	my $self      = shift;
	my $commentId = shift;
	my $name      = shift // "";
	my $path      = shift;

	my $comm = $self->{"commLayout"}->GetCommentById($commentId);

	my $defName = $name;

	my $f = $comm->AddFile( $defName, $path );

	# Update file customer name if empty

	my $fileCnt = scalar( $comm->GetAllFiles() );
	if ( $fileCnt > 1 ) {

		my @files = $comm->GetAllFiles();
		for ( my $j = 0 ; $j < scalar(@files) ; $j++ ) {

			if ( $files[$j]->GetFileCustName() eq "" ) {

				$files[$j]->SetFileCustName( ( $j + 1 ) );
			}
		}
	}

	return $f;
}

sub RemoveFile {
	my $self      = shift;
	my $commentId = shift;
	my $fileId    = shift;

	my $commSnglLayout = $self->{"commLayout"}->GetCommentById($commentId);

	$commSnglLayout->RemoveFile($fileId);
}

sub EditFile {
	my $self      = shift;
	my $commentId = shift;
	my $fileId    = shift;

	my $commSnglLayout = $self->{"commLayout"}->GetCommentById($commentId);
	my $file           = $commSnglLayout->GetFileById($fileId);

	my $result = 1;

	if ( -e Enums->Path_GREENSHOT ) {

		my $pGS = Enums->Path_GREENSHOT;

		#system( 1, qq{"$pGS"} . " " . $file->GetFilePath() );
		use Win32::Process;
		my $processObj;
		my @cmd = ("Greenshot.exe");
		push( @cmd, $file->GetFilePath() );

		my $cmdStr = join( " ", @cmd );

		Win32::Process::Create( $processObj, $pGS, $cmdStr, 0, (THREAD_PRIORITY_NORMAL), "." )
		  || die "$!\n";

		$processObj->Wait(INFINITE);

	}
	else {

		$result = 0;
	}

	return $result;
}

sub SetFileName {
	my $self      = shift;
	my $commentId = shift;
	my $fileId    = shift;
	my $fileName  = shift;

	my $commSnglLayout = $self->{"commLayout"}->GetCommentById($commentId);
	$commSnglLayout->SetFileCustName( $fileId, $fileName );

}

sub GetFileName {
	my $self      = shift;
	my $commentId = shift;
	my $fileId    = shift;

	return $self->{"fileName"};
}

sub AddSuggestion {
	my $self      = shift;
	my $commentId = shift;
	my $text      = shift;

	my $commSnglLayout = $self->{"commLayout"}->GetCommentById($commentId);

	$commSnglLayout->AddSuggestion($text);
}

sub SetSuggestion {
	my $self      = shift;
	my $commentId = shift;
	my $suggId    = shift;
	my $text      = shift;

	my $commSnglLayout = $self->{"commLayout"}->GetCommentById($commentId);
	$commSnglLayout->SetSuggestion( $suggId, $text );
}

sub RemoveSuggestion {
	my $self      = shift;
	my $commentId = shift;
	my $suggId    = shift;

	my $commSnglLayout = $self->{"commLayout"}->GetCommentById($commentId);
	$commSnglLayout->RemoveSuggestion($suggId);
}

# --------------------------------------
# Other public method
# --------------------------------------

# Return path of main comments directory
sub GetCommDir {
	my $self = shift;

	return $self->{"commDir"};
}

# Return path of comm archive
sub GetCommArchiveDir {
	my $self = shift;
	return $self->{"commArchiveDir"};
}

# --------------------------------------
# Private methods
# --------------------------------------

sub __LoadFromJob {
	my $self = shift;

	if ( $self->{"jsonStrMngr"}->SerializedDataExist() ) {

		$self->{"commLayout"} = $self->{"jsonStrMngr"}->LoadData();
	}

	#	# Add default comment
	#	$self->AddComment( Enums->CommentType_QUESTION );
	#	$self->SetText( 0, "" );
	#
	#	$self->AddFile( 0, "stakcup", $self->SnapshotCAM() );
	#	$self->AddFile( 0, "stakcup", 'c:/Export/test/noImage_.png' );
	#
	#	$self->Save();
	#
	#	$self->AddComment( Enums->CommentType_NOTE );
	#	$self->SetText( 1, "test jfdif djfosdifj fjdi" );
	#	$self->AddFile( 1, "stakcup", 'c:/Export/test/noImage.png' );
	#
	#	$self->AddComment( Enums->CommentType_NOTE );
	#	$self->SetText( 1, "test jfdif djfosdifj fjdi" );

	#	$self->AddComment( Enums->CommentType_QUESTION );
	#	$self->SetText( 2, "test jfdif djfosdifj fjdi" );
	#		$self->AddFile( 2, "stakcup", 'c:/Export/test/noImage.png' );

}

sub __AddDefaultComm {
	my $self = shift;

	# Add default comment
	$self->AddComment( Enums->CommentType_QUESTION );

	my $commCnt = scalar( $self->{"commLayout"}->GetAllComments() );

	$self->SetText( $commCnt - 1, "" );
	my $p = "";
	if($self->SnapshotCAM(1, \$p)){
		
		$self->AddFile( $commCnt - 1, "", $p );
	}
	

}

sub __ClearOldFiles {
	my $self = shift;

	my @filesP = map { $_->GetFilePath() } map { $_->GetAllFiles() } $self->{"commLayout"}->GetAllComments();

	my @filesN = map { ( fileparse($_) )[0] } @filesP;
	push( @filesN, ( fileparse( $self->{"mainFile"} ) )[0] );    # not delete main json file

	opendir( DIR, $self->{"commDir"} ) or die $!;

	while ( my $file = readdir(DIR) ) {

		my ( $name, $path, $suffix ) = fileparse($file);

		unless ( scalar( grep { $_ eq $name } @filesN ) ) {
			unlink( $self->{"commDir"} . "$file" );
		}
	}

	close(DIR);
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Programs::Comments::Comments';
	use aliased 'Packages::InCAM::InCAM';

	my $jobId = "d288054";
	my $inCAM = InCAM->new();

	my $c = Comments->new( $inCAM, $jobId );
	$c->ClearCoomments();

}

1;

