
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

}

sub MoveDown {
	my $self      = shift;
	my $commentId = shift;

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

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

