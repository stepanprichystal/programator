
#-------------------------------------------------------------------------------------------#
# Description: Layout for tables
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommLayout::CommLayout;
use base qw(Programs::Comments::CommLayout::CommLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::Comments::CommLayout::CommSnglLayout';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"comments"} = [];

	return $self;
}

sub AddComment {
	my $self = shift;
	my $type = shift;

	my $comment = CommSnglLayout->new($type);
	push( @{ $self->{"comments"} }, $comment );

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

	die "Unable to move up comment id: $commentId" if ( $commentId - 1 < 0 );

	my $tmp = splice @{ $self->{"comments"} }, $commentId, 1;
	splice @{ $self->{"comments"} }, $commentId - 1, 0, $tmp;

}

sub MoveDown {
	my $self      = shift;
	my $commentId = shift;

	die "Unable to move down comment id: $commentId"
	  if ( $commentId + 1 >= scalar( @{ $self->{"comments"} } ) );

	my $tmp = splice @{ $self->{"comments"} }, $commentId, 1;
	splice @{ $self->{"comments"} }, $commentId + 1, 0, $tmp;
}

sub GetCommentById {
	my $self   = shift;
	my $commId = shift;

	die "Comment id: $commId doesn't exist" if ( $commId < 0 || $commId >= scalar( @{ $self->{"comments"} } ) );

	return $self->{"comments"}->[$commId];

}

sub GetAllComments {
	my $self = shift;

	return @{ $self->{"comments"} };

}

sub GetFullFileNameById {
	my $self   = shift;
	my $commId = shift;
	my $fileId = shift;

	my $comm = $self->GetCommentById($commId);
	my $f = $comm->GetFileById($fileId);

	my $custName = $f->GetFileCustName();
	$custName.= "_" if(defined $custName && $custName ne "");

	return $f->GetFilePrefix() . ( $commId + 1 ) . $custName .  $f->GetFileSufix();

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

