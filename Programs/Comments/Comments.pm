
#-------------------------------------------------------------------------------------------#
# Description:
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::Comments;

#3th party library
use strict;
use warnings;
use Switch;

#local library

use aliased 'Programs::Comments::CommLayout::CommLayout';
use aliased 'Programs::Comments::CommLayout::CommSnglLayout';
use aliased 'Helpers::JobHelper';
use aliased 'Programs::Comments::Enums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $self  = {};
	bless $self;

	$self->{"inCAM"} = shift;
	$self->{"jobId"} = shift;

	$self->{"commDir"} = JobHelper->GetJobOutput( $self->{"jobId"} ) . "comments";
	unless ( -e $self->{"commDir"} ) {
		mkdir( $self->{"commDir"} ) or die "$_";
	}

	$self->{"commLayout"} = CommLayout->new();

	$self->__LoadFromJob();

	return $self;
}

sub Save {
	my $self = shift;

}

sub GetOutText {
	my $self = shift;
}

sub GetOutFiles {
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

sub GetCommentById {
	my $self = shift;

	return @{ $self->{"tables"} };

}

sub GetAllComments {
	my $self = shift;

	return @{ $self->{"tables"} };

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

sub GetAllFiles {
	my $self      = shift;
	my $commentId = shift;

	return @{ $self->{"files"} };

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

sub GetAllSuggestions {
	my $self      = shift;
	my $commentId = shift;

	return @{ $self->{"suggestions"} };

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

sub __LoadFromJob {
	my $self = shift;

	# test

	$self->AddComment( Enums->CommentType_QUESTION );
	$self->SetText( 0, "test jfdif djfosdifj fjdi" );
	$self->AddFile( 0, "stakcup", 'c:/Export/test/noImage.png' );
	$self->AddFile( 0, "stakcup", 'c:/Export/test/noImage_.png' );

	$self->AddComment( Enums->CommentType_NOTE );
	$self->SetText( 1, "test jfdif djfosdifj fjdi" );
	$self->AddFile( 1, "stakcup", 'c:/Export/test/noImage.png' );
#	$self->AddComment( Enums->CommentType_QUESTION );
#	$self->SetText( 2, "test jfdif djfosdifj fjdi" );
#		$self->AddFile( 2, "stakcup", 'c:/Export/test/noImage.png' );

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

