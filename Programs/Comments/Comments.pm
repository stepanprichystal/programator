
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

#local library

use aliased 'Programs::Comments::CommLayout::CommLayout';
use aliased 'Programs::Comments::CommLayout::CommSnglLayout';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Comments::Enums';
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ObjectStorable::JsonStorable::JsonStorableMngr';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"commDir"} = JobHelper->GetJobOutput( $self->{"jobId"} ) . "comments\\";
	unless ( -e $self->{"commDir"} ) {
		mkdir( $self->{"commDir"} ) or die "$_";
	}

	$self->{"commLayout"}  = CommLayout->new();
	$self->{"jsonStrMngr"} = JsonStorableMngr->new( $self->{"commDir"} . "comments.json" );

	$self->__LoadFromJob();

	$self->__ClearOldFiles();

	return $self;
}

sub Save {
	my $self = shift;

	$self->{"jsonStrMngr"}->StoreData( $self->{"commLayout"} );

	foreach my $comm ( $self->{"commLayout"}->GetAllComments() ) {

		$comm->SetStoredOnDisc(1);
	}

}

sub SnapshotCAM {
	my $self = shift;
	my $directly = shift // 1;

	my $inCAM = $self->{"inCAM"};
	my $jobId = $self->{"jobId"};

	unless ($directly) {

		my $mess = "Prepare what you want to snapshot...";
		$inCAM->PAUSE($mess);
	}

	my $fileName = "CAM_" . GeneralHelper->GetNumUID();
	my $p        = $self->{"commDir"} . $fileName;
	$inCAM->COM( "save_snapshot", "path" => $p . ".png" );

	# Unlink extra files: .nte;  .txt;
	unlink( $p . ".nte" );
	unlink( $p . ".txt" );

	return $p . ".png";
}

sub SnapshotGS {
	my $self = shift;

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

	die "Comment id: $commentId doesn't exist" if ( $commentId < 0 || $commentId >= scalar( @{ $self->{"comments"} } ) );

	splice @{ $self->{"comments"} }, $commentId, 1;
}

sub MoveUp {
	my $self      = shift;
	my $commentId = shift;

}

sub MoveDown {
	my $self      = shift;
	my $commentId = shift;

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
	my $name      = shift;
	my $path      = shift;

	my $comm = $self->{"commLayout"}->GetCommentById($commentId);

	my $f = $comm->AddFile( $name, $path );

	return $f;
}

sub RemoveFile {
	my $self      = shift;
	my $commentId = shift;
	my $fileId    = shift;

	die "File id: $fileId doesn't exist" if ( $fileId < 0 || $fileId >= scalar( @{ $self->{"files"} } ) );

	splice @{ $self->{"files"} }, $fileId, 1;
}

sub AddSuggestion {
	my $self      = shift;
	my $commentId = shift;
	my $text      = shift;

	push( @{ $self->{"suggestions"} }, $text );

}

sub RemoveSuggestion {
	my $self      = shift;
	my $commentId = shift;
	my $suggId    = shift;

	die "Suggestion id: $suggId doesn't exist" if ( $suggId < 0 || $suggId >= scalar( @{ $self->{"suggestions"} } ) );

	splice @{ $self->{"suggestions"} }, $suggId, 1;
}

# --------------------------------------
# METHODS FOR BUILDING COMMENT file
# --------------------------------------

sub SetFileName {
	my $self      = shift;
	my $commentId = shift;
	my $fileId    = shift;

	$self->{"fileName"} = shift;
}

sub GetFileName {
	my $self      = shift;
	my $commentId = shift;
	my $fileId    = shift;

	return $self->{"fileName"};
}

# --------------------------------------
# Private methods
# --------------------------------------

sub __LoadFromJob {
	my $self = shift;

	if ( $self->{"jsonStrMngr"}->SerializedDataExist() ) {

		$self->{"commLayout"} = $self->{"jsonStrMngr"}->LoadData();
	}

	# Add default comment
	$self->AddComment( Enums->CommentType_QUESTION );
	$self->SetText( 0, "" );

	$self->AddFile( 0, "stakcup", $self->SnapshotCAM() );
	$self->AddFile( 0, "stakcup", 'c:/Export/test/noImage_.png' );

	$self->Save();

	$self->AddComment( Enums->CommentType_NOTE );
	$self->SetText( 1, "test jfdif djfosdifj fjdi" );
	$self->AddFile( 1, "stakcup", 'c:/Export/test/noImage.png' );

	#	$self->AddComment( Enums->CommentType_QUESTION );
	#	$self->SetText( 2, "test jfdif djfosdifj fjdi" );
	#		$self->AddFile( 2, "stakcup", 'c:/Export/test/noImage.png' );

}

sub __ClearOldFiles {
	my $self = shift;

	my @filesP = map { $_->GetFilePath() } map { $_->GetAllFiles() } $self->{"commLayout"}->GetAllComments();

	my @filesN = map { ( fileparse($_) )[0] } @filesP;

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

}

1;

