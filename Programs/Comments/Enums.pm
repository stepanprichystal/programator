
package Programs::Comments::Enums;

# coupon pad types
use constant {
			   CommentType_NOTE     => "CommentType_NOTE",
			   CommentType_QUESTION => "CommentType_QUESTION"
};

sub GetTypeTitle {
	my $self = shift;
	my $t    = shift;

	my $tit = undef;

	if ( $t eq CommentType_NOTE ) {
		$tit = "Note";
	}
	elsif ( $t eq CommentType_QUESTION ) {
		$tit = "Question";
	}

	return $tit;
}

sub GetTypeKey {
	my $self = shift;
	my $tit  = shift;

	my $key = undef;

	if ( $tit eq "Note" ) {
		$key = CommentType_NOTE;
	}
	elsif ( $tit eq "Question" ) {
		$key = CommentType_QUESTION;
	}

	return $key;
}

1;
