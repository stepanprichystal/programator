#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::InCAM::Helper;

#3th party library
use strict;
use warnings;

#local library
use Packages::InCAM::Errors;
use aliased 'Enums::EnumsPaths';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub GetErrorTextById {
	my $self = shift;
	my $id   = shift;

	my $mess = $Packages::InCAM::Errors::errs{$id};

	unless ($mess) {

		$mess = "Error message from InCAM is not available.";
	}

	return $mess;
}

sub GetFormatedLogByStamp {
	my $self    = shift;
	my $logId   = shift;
	my $stampId = shift;

	my @lines = $self->GetLogLineByStamp( $logId, $stampId );

	# select lines with text "internal"
	$self->__SelectInternal(\@lines);

	my $str = "";

	foreach my $l (@lines) {

		$str .= $l;
	}

	return $str;
}

sub __SelectInternal {
	my $self  = shift;
	my $lines = shift;

	my $maxLen         = 20;
	my $internalFound  = 0;
	my $commandFound   = 0;
	my $formatedLCount = 0;

	my $l;
	for ( my $i = scalar( @{$lines} ) - 1 ; $i >= 0 ; $i-- ) {

		$l = ${$lines}[$i];

		if ( $l =~ /(\*)+\s*internal/i ) {

			$internalFound = 1;
		}

		if ($internalFound) {

		 
				$formatedLCount++;
				${$lines}[$i] = "<r>" . $l . "</r>";
			 
			
			if ( $l =~ /(\*)+\s*command/i || $formatedLCount >= $maxLen ) {
				$internalFound  = 0;
				$commandFound   = 0;
				$formatedLCount = 0;

			}
		}

	}

}

sub GetLogLineByStamp {
	my $self    = shift;
	my $logId   = shift;
	my $stampId = shift;

	my @lines    = ();
	my @errLines = ();

	my $customLog = EnumsPaths->Client_INCAMTMPOTHER . "incamLog." . $logId;

	if ( open( my $fLogCustom, '<', $customLog ) ) {

		@lines = <$fLogCustom>;

		close($fLogCustom);
	}

	if ( scalar(@lines) > 0 ) {

		my $maxLen        = 300;
		my $stampFound    = 0;
		my $nextStamFound = 0;

		my $l;

		for ( my $i = scalar(@lines) - 1 ; $i >= 0 ; $i-- ) {

			$l = $lines[$i];

			if ( $l =~ /ExceptionId:$stampId/i ) {

				$stampFound = 1;
				next;
			}

			if ($stampFound) {

				if ( $l =~ /ExceptionId:/i ) {

					$nextStamFound = 1;
					last;
				}

				if ( scalar(@errLines) < $maxLen ) {
					splice( @errLines, 0, 0, $l );
				}
			}
		}
	}

	return @errLines;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#

if (0) {

	print Packages::InCAM::Helper->GetErrorTextById("1012002");

}

1;
