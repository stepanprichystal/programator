#-------------------------------------------------------------------------------------------#
# Description: Reading information from nif file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::NifFile::NifFile;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'Helpers::FileHelper';

#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;

	$self->{"jobId"} = shift;

	my $nifPath = JobHelper->GetJobArchive( $self->{"jobId"} ) . $self->{"jobId"} . ".nif";

	my %nifData = ();
	$self->{"nifData"}  = \%nifData;
	$self->{"nifExist"} = 0;
	$self->{"nifRows"}  = undef;

	if ( -e $nifPath ) {

		$self->{"nifExist"} = 1;

		my @lines = @{ FileHelper->ReadAsLines($nifPath) };
		$self->{"nifRows"} = \@lines;

		foreach my $l (@lines) {

			if ( $l =~ /.*[^=]=[^=].*/ ) {

				my @splited = split( "=", $l );
				chomp @splited;

				$self->{"nifData"}->{ $splited[0] } = $splited[1];
			}
		}
	}

	return $self;
}

# Return base cu thick by layer
sub Exist {
	my $self = shift;

	if ( $self->{"nifExist"} ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub GetSection {
	my $self        = shift;
	my $sectionName = shift;
	my $lines       = shift;

	my $read = 1;

	for ( my $i = 0 ; $i < scalar( @{ $self->{"nifRows"} } ) ; $i++ ) {

		my $l = $self->{"nifRows"}->[$i];

		if ( $l =~ /.*\[=+\s+SEKCE ([^=]*)\s+=+\].*/i ) {

			# if requested section, read unless another section begin
			if ( $1 =~ /$sectionName/i ) {
				push( @{$lines}, $l );

				while (1) {
					$i++;
					my $lSection = $self->{"nifRows"}->[$i];

					if ( !defined $lSection || $lSection =~ /.*\[=+\s+SEKCE ([^=]*)\s+=+\].*/i) {
						$read = 0;
						last;
					}

					push( @{$lines}, $lSection );
				}
			}
		}

		unless ($read) {
			last;
		}
	}

	# remove line compete = 1 if exist
	
	@{$lines} = grep { $_ !~ /complete/i } @{$lines};

	if ( scalar( @{$lines} ) ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub GetValue {
	my $self      = shift;
	my $attribute = shift;

	chomp($attribute);

	return $self->{"nifData"}->{$attribute};
}

#Return color of mask in hash for top and bot side
sub GetSolderMaskColor {
	my $self = shift;

	my %mask = ();

	$mask{"top"} = $self->GetValue("c_mask_colour");
	$mask{"bot"} = $self->GetValue("s_mask_colour");

	return %mask;
}

#Return color of silk screen in hash for top and bot side
sub GetSilkScreenColor {
	my $self = shift;

	my %silk = ();

	$silk{"top"} = $self->GetValue("c_silk_screen_colour");
	$silk{"bot"} = $self->GetValue("s_silk_screen_colour");

	return %silk;

}

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	use aliased 'Packages::NifFile::NifFile';

	my $nif = NifFile->new("f52456");

	my @lines = ();
	if ( $nif->GetSection( "ostatni2", \@lines ) ) {
		print @lines;
	}
}

1;

