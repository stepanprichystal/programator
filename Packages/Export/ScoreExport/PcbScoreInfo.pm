
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Export::GerExport::ExportPasteMngr;
 
#3th party library
use strict;
use warnings;
 
#local library
use aliased 'Helpers::GeneralHelper';
use aliased 'Packages::ItemResult::ItemResult';
use aliased 'Enums::EnumsPaths';
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamHelper';
use aliased 'CamHelpers::CamStepRepeat';
use aliased 'Helpers::FileHelper';
use aliased 'Packages::Export::GerExport::Helper';

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;

	$self->{"originX"}     = shift;
	$self->{"originY"}     = shift;
	$self->{"width"}     = shift;
	$self->{"height"} = shift;

	my @v = ();
	 $self->{"vertical"} = \@v;

	my @h = ();
	 $self->{"horizontal"} = \@h;

	return $self;
}

sub AddScorePoint {
	my $self = shift;
	my $type = shift;
	my $pos= shift;
	
	if($type eq Enums->Dir_HSCORE){
		
		
		push(@{$self->{"horizontal"}}, $pos);
		
	}elsif($type eq Enums->Dir_VSCORE){
		
		push(@{$self->{"vertical"}}, $pos);
		
	} 

}
 
 
sub IsScoreOnPos{
	my $self = shift;
	my $type = shift;
	my $pos= shift;
	
	my @positions;
	
	if($type eq Enums->Dir_HSCORE){
 
		@positions = @{$self->{"horizontal"}} ;
		
	}elsif($type eq Enums->Dir_VSCORE){
		
		@positions = @{$self->{"vertical"}} ;
		
	} 
	
	my $exist = 0;
	
	foreach my $p (@positions){
		
		if($p == $pos){
			
			$exist = 1;
		}
		
	}
	
	return $exist;

} 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

	#use aliased 'Packages::Export::NCExport::NCExportGroup';

	#print $test;

}

1;

