
#-------------------------------------------------------------------------------------------#
# Description: Interface, allow build nif section
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::Comments::CommLayout::CommSnglLayout;
use base qw(Programs::Comments::CommLayout::CommLayoutBase);

use Class::Interface;
&implements('Packages::ObjectStorable::JsonStorable::IJsonStorable');

#3th party library
use strict;
use warnings;

#use List::Util qw(first);
#use List::MoreUtils qw(uniq first_index);

#local library
use aliased 'Programs::Comments::CommLayout::CommFileLayout';
use aliased 'Programs::Comments::Enums';

#-------------------------------------------------------------------------------------------#
#  Public method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $type  = shift;

	my $self = {};
	$self = $class->SUPER::new(@_);
	bless $self;

	$self->{"type"}         = $type;
	$self->{"text"}         = "";
	$self->{"storedOnDisc"} = 0;

	$self->{"suggestions"} = [];
	$self->{"files"}       = [];

	return $self;
}

sub GetStoredOnDisc {
	my $self = shift;

	return $self->{"storedOnDisc"};
}

sub SetStoredOnDisc {
	my $self = shift;

	$self->{"storedOnDisc"} = shift;
}

sub SetType {
	my $self = shift;

	$self->{"type"} = shift;

	# set new type to filename prefix

	foreach my $f ( $self->GetAllFiles() ) {

		my $prefix;

		if ( $self->{"type"} eq Enums->CommentType_NOTE ) {
			$prefix = "N";
		}
		elsif ( $self->{"type"} eq Enums->CommentType_QUESTION ) {
			$prefix = "Q";
		}
		$f->SetFilePrefix($prefix);
	}
	
	$self->SetStoredOnDisc(0);
}

sub GetType {
	my $self = shift;

	return $self->{"type"};
}

sub SetText {
	my $self = shift;

	$self->{"text"} = shift;
	
	$self->SetStoredOnDisc(0);
}

sub GetText {
	my $self = shift;

	return $self->{"text"};
}

sub AddFile {
	my $self = shift;
	my $name = shift;
	my $path = shift;

	my $prefix = "";

	if ( $self->GetType() eq Enums->CommentType_NOTE ) {
		$prefix = "N";
	}
	elsif ( $self->GetType() eq Enums->CommentType_QUESTION ) {
		$prefix = "Q";
	}

	my $suffix = "";

	if ( $path =~ m/(\.\w+)$/ ) {
		$suffix = $1;
	}

	my $f = CommFileLayout->new( $name, $prefix, $suffix, $path );

	push( @{ $self->{"files"} }, $f );
	
	$self->SetStoredOnDisc(0);

	return $f;
}

sub RemoveFile {
	my $self   = shift;
	my $fileId = shift;

	die "File id: $fileId doesn't exist" if ( $fileId < 0 || $fileId >= scalar( @{ $self->{"files"} } ) );

	splice @{ $self->{"files"} }, $fileId, 1;
	
	$self->SetStoredOnDisc(0);
}

sub GetAllFiles {
	my $self = shift;

	return @{ $self->{"files"} };

}

sub GetFileById {
	my $self   = shift;
	my $fileId = shift;

	die "File id: $fileId doesn't exist" if ( $fileId < 0 || $fileId >= scalar( @{ $self->{"files"} } ) );

	return $self->{"files"}->[$fileId];

}



sub SetFileCustName {
	my $self   = shift;
	my $fileId = shift;
	my $name = shift;

	die "File id: $fileId doesn't exist" if ( $fileId < 0 || $fileId >= scalar( @{ $self->{"files"} } ) );

	$self->{"files"}->[$fileId]->SetFileCustName($name);
	
	$self->SetStoredOnDisc(0);

}

sub AddSuggestion {
	my $self = shift;
	my $text = shift;

	push( @{ $self->{"suggestions"} }, $text );
	
	$self->SetStoredOnDisc(0);

}

sub RemoveSuggestion {
	my $self   = shift;
	my $suggId = shift;

	die "Suggestion id: $suggId doesn't exist" if ( $suggId < 0 || $suggId >= scalar( @{ $self->{"suggestions"} } ) );

	splice @{ $self->{"suggestions"} }, $suggId, 1;
	
	$self->SetStoredOnDisc(0);
}

sub GetAllSuggestions {
	my $self = shift;

	return @{ $self->{"suggestions"} };

}

sub GetSuggestionById {
	my $self   = shift;
	my $suggId = shift;

	die "Suggestion id: $suggId doesn't exist" if ( $suggId < 0 || $suggId >= scalar( @{ $self->{"suggestions"} } ) );

	return $self->{"suggestions"}->[$suggId];

}

sub SetSuggestion {
	my $self   = shift;
	my $suggId = shift;
	my $text = shift;

	die "Suggestion id: $suggId doesn't exist" if ( $suggId < 0 || $suggId >= scalar( @{ $self->{"suggestions"} } ) );

	$self->{"suggestions"}->[$suggId] = $text;
	
	$self->SetStoredOnDisc(0);

}
 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

