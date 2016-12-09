#-------------------------------------------------------------------------------------------#
# Description: Script slouzi pro vypocet hlubky vybrusu pri navadeni na vrtackach.
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::NifFile::NifFile;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';

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
	$self->{"nifData"} = \%nifData;
	$self->{"nifExist"} = 0;

	if ( -e $nifPath ) {
		
		$self->{"nifExist"} = 1;
		
		my @lines = @{FileHelper->ReadAsLines($nifPath)};
 
		foreach my $l (@lines){
			
				my @splited = split( "=", $l );
				chomp @splited;
				$self->{"nifData"}->{$splited[0]} = $splited[1];
		}
	}
	 

	return $self;
}

# Return base cu thick by layer
sub Exist {
	my $self = shift;

	if ($self->{"nifExist"} ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub GetValue {
	my $self      = shift;
	my $jobId     = shift;
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

	#use aliased 'Helpers::JobHelper';

	#print JobHelper->GetBaseCuThick("F13608", "v3");

	#print "\n1";
}

1;

