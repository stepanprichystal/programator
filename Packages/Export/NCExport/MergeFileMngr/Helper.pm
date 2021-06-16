
#-------------------------------------------------------------------------------------------#
# Description: Cover merging, spliting and checking before exporting NC files
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::NCExport::MergeFileMngr::Helper;

#3th party library
use strict;
use warnings;
use File::Copy;
use Try::Tiny;
use List::MoreUtils qw(uniq);
use List::Util qw[max min first];

#local library
use aliased 'Enums::EnumsGeneral';
use aliased 'Enums::EnumsPaths';
use aliased 'Enums::EnumsDrill';
use aliased 'Connectors::HeliosConnector::HegMethods';
use aliased 'Packages::TifFile::TifNCOperations';
use aliased 'Helpers::GeneralHelper';
use aliased 'CamHelpers::CamRouting';
use aliased 'Packages::Stackup::Stackup::Stackup';
use aliased 'CamHelpers::CamJob';
use aliased 'Packages::CAMJob::Dim::JobDim';
use aliased 'CamHelpers::CamDrilling';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Packages::CAM::UniRTM::UniRTM';
use aliased 'Packages::CAM::UniDTM::UniDTM';
use aliased 'Packages::CAM::UniDTM::Enums' => 'DTMEnums';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-----
# Helper function which move M47 messsage on right place in rout files
# Reason: for rout file, we request for every tool with G83 display info
# message, but messages are placed together above "body" lines after export
sub PutMessRightPlace {
	my $self = shift;
	my $file = shift;
	my @mess = ();

	#find and delete all m47 mess from body
	for ( my $i = scalar( @{ $file->{"body"} } ) - 1 ; $i >= 0 ; $i-- ) {

		my $l = @{ $file->{"body"} }[$i];
		if ( $l->{"line"} =~ /M47,\s*.*/ ) {
			unshift( @mess, $l );
			splice @{ $file->{"body"} }, $i, 1;
		}
	}

	#push mess on right place
	my $messPrev = undef;
	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) + scalar(@mess) ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];
		if ( $l->{"tool"} ) {
			my $m = shift(@mess);

			my $lVal = quotemeta $m->{"line"};

			# if message is same as previous message, do not add message
			if ( !( defined $messPrev && $messPrev->{"line"} =~ $lVal ) ) {

				$m->{"line"} = "\n" . $m->{"line"} . "\n";
				splice @{ $file->{"body"} }, $i, 0, $m;
				$i++;    #skip right added line
			}

			$messPrev = $m;

			unless ( scalar(@mess) ) {
				last;
			}
		}
	}
}

# Helper function add G82 command, where tool has defined G83 command
# Reason: In rout files G82 is missing - bug in InCAM
sub AddG83WhereMissing {
	my $self = shift;
	my $file = shift;

	my $search      = 0;
	my $searchStart = 0;
	my $extraCnt    = 0;
	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) + $extraCnt ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];

		if ( !$search && $l->{"tool"} ) {

			if ( $l->{"line"} =~ /G83/ ) {

				#search for G82 OR next TOOL
				$search      = 1;
				$searchStart = $i;
				next;
			}
		}

		if ( $search && ( $l->{"line"} =~ /G82/ || $l->{"tool"} ) ) {

			# tool was searched before G82
			# it means, G82 is missing
			if ( $l->{"tool"} ) {
				my %g82 = ( "line" => "G82\n" );

				#find place, where new line could be added
				for ( my $j = $i - 1 ; $j >= $searchStart ; $j-- ) {

					my $l2 = @{ $file->{"body"} }[$j];

					if ( $l2->{"line"} =~ /M47,.*/ || $l2->{"line"} =~ /^[\n\t\r]*$/ ) {
						next;
					}
					else {
						splice @{ $file->{"body"} }, $j + 1, 0, \%g82;
						$extraCnt++;
						last;
					}
				}
			}

			$search = 0;
		}
	}
}

# Helper function renumber TOOLs in whole program
# First tool in program => T01, next T02, etc...
# Sort program footer tool definitions ASC T01, T02, etc
sub RenumberToolASC {
	my $self = shift;
	my $file = shift;

	my %th     = ();      #translate table for head tools
	my %tb     = ();      #translate table for body tools
	my $prefix = "@%";    # helper substitute symbol for renumbering tool

	my $startNumber = 1;

	# Check if there are tools in header
	for ( my $i = 0 ; $i < scalar( @{ $file->{"header"} } ) ; $i++ ) {

		my $l = @{ $file->{"header"} }[$i];

		my $tool = ( $l =~ m/^T(\d+)$/gm )[0];    # gm ignore new lines

		if ( defined $tool && !exists $tb{ int($tool) } ) {

			my $tNew = $startNumber + scalar( keys %tb );
			$tb{ int($tool) } = $tNew;
		}
	}

	# 1) Build translate table
	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];

		if ( $l->{"tool"} && !exists $tb{ $l->{"tool"} } ) {

			my $tNew = scalar( keys %tb ) + 1;
			$tb{ $l->{"tool"} } = $tNew;
		}
	}

	# 2) Renumber tools in "header"

	for ( my $i = 0 ; $i < scalar( @{ $file->{"header"} } ) ; $i++ ) {

		my $l = @{ $file->{"header"} }[$i];

		my $tool = ( $l =~ m/^T(\d+)$/gm )[0];

		if ( defined $tool && defined $tb{ int($tool) } ) {

			my $new = sprintf( "%02d", $tb{ int($tool) } );

			$file->{"header"}->[$i] =~ s/T$tool/$prefix$new/;
		}
	}

	# 3) Renumber tools in "body"

	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		if ( $file->{"body"}->[$i]->{"tool"} ) {

			my $old = sprintf( "%02d", $file->{"body"}->[$i]->{"tool"} );
			my $new = sprintf( "%02d", $tb{ $file->{"body"}->[$i]->{"tool"} } );

			$file->{"body"}->[$i]->{"line"} =~ s/T$old/$prefix$new/;

			# update tool in parsed file
			$file->{"body"}->[$i]->{"tool"} = $tb{ $file->{"body"}->[$i]->{"tool"} };
		}
	}

	# 4) Renumber tools in  "footer"
	for ( my $i = 0 ; $i < scalar( @{ $file->{"footer"} } ) ; $i++ ) {

		my $old = sprintf( "%02d", $file->{"footer"}->[$i]->{"tool"} );
		my $new = sprintf( "%02d", $tb{ $file->{"footer"}->[$i]->{"tool"} } );

		$file->{"footer"}->[$i]->{"line"} =~ s/T$old/$prefix$new/;

		# update tool in parsed file
		$file->{"footer"}->[$i]->{"tool"} = $tb{ $file->{"footer"}->[$i]->{"tool"} };
	}

	#  sustitute prefix with "T"

	for ( my $i = 0 ; $i < scalar( @{ $file->{"header"} } ) ; $i++ ) {

		$file->{"header"}->[$i] =~ s/$prefix/T/;

	}

	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		$file->{"body"}->[$i]->{"line"} =~ s/$prefix/T/ if ( $file->{"body"}->[$i]->{"tool"} );

	}

	for ( my $i = 0 ; $i < scalar( @{ $file->{"footer"} } ) ; $i++ ) {

		$file->{"footer"}->[$i]->{"line"} =~ s/$prefix/T/;
	}

	# Sort footer tools
	my @sorted = sort { $a->{"tool"} <=> $b->{"tool"} } @{ $file->{"footer"} };

	$file->{"footer"} = \@sorted;

}

# search drilled number in file and change:
# - Cu thickness mark
# - Add core mark, if exist
sub ChangeDrilledNumber {
	my $self        = shift;
	my $file        = shift;
	my $cuThickMark = shift;
	my $coreMark    = shift;

	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];

		if ( $l->{"line"} =~ m/(m97,[a-f][\d]+)([\/\-\:\+]{0,2})(\D*)/i ) {

			my $pcbid   = $1;
			my $machine = $3;

			my $newDrillNum = $pcbid . $cuThickMark . $machine . " " . $coreMark;

			$newDrillNum =~ s/[\n\t\r]//;
			$newDrillNum .= "\n";

			#$l
			@{ $file->{"body"} }[$i]->{"line"} =~ s/(m97,[a-f][\d]+)([\/\-\:\+]{0,2})(\D*)/$newDrillNum/i;

			last;
		}
	}
}

sub RemoveDrilledNumber {
	my $self = shift;
	my $file = shift;

	for ( my $i = 0 ; $i < scalar( @{ $file->{"body"} } ) ; $i++ ) {

		my $l = @{ $file->{"body"} }[$i];

		if ( $l->{"line"} =~ m/(m97,[a-f][\d]+)([\/\-\:\+]{0,2})(\D*)/i ) {

			splice @{ $file->{"body"} }, $i, 1;

			last;
		}
	}
}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#print $test;

}

1;

