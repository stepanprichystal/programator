#-------------------------------------------------------------------------------------------#
# Description: Wrapper for operations connected with inCam attributes
# Author:SPR
#-------------------------------------------------------------------------------------------#

package Packages::Export::PlotExport::PlotSet::PlotSet;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Export::PlotExport::Enums';
#-------------------------------------------------------------------------------------------#
#   Package methods
#-------------------------------------------------------------------------------------------#
sub new {
	my $class = shift;
	my $self  = {};

	bless $self;
	


	$self->{"resultSet"} = shift; # rule result set
 
	$self->{"layers"}      = shift;
	
		$self->{"jobId"} = shift;

	# Helper propery, when create opfx
	$self->{"outputLayer"} = undef;    #name of final output layer, contain merged layers

	return $self;
}

sub GetLayers {
	my $self = shift;

	return @{ $self->{"layers"} };

}

sub GetOrientation {
	my $self = shift;

	return $self->{"resultSet"}->GetOrientation();

}

sub GetFilmSize {
	my $self = shift;

	return $self->{"resultSet"}->GetFilmSize();

}

# Return string, whic tell size of film e.g. 24x16
sub GetFilmSizeInch {
	my $self = shift;
	
	my $filmSize = $self->GetFilmSize();
	my $str = ""; 
	 

	if ( $filmSize eq Enums->FilmSize_Small ) {

		$str = "24x16";
	}
	elsif ( $filmSize eq Enums->FilmSize_Big ) {
	
		$str = "24x20";
		
	}
	
	return $str;
}
 


# width of all films, placed together (without gap)
sub GetFilmsWidth {
	my $self = shift;

	return $self->{"resultSet"}->GetWidth();

}

sub GetOutputFileName {
	my $self  = shift;
	
	my $jobId = $self->{"jobId"};

	my $fName = "$jobId@";
	my $bigIndicator = $self->GetFilmSize() eq Enums->FilmSize_Big ? "v" : "";

	# Select layer by layer
	foreach my $plotL ( $self->GetLayers() ) {
		$fName .= $plotL->GetName() . $bigIndicator . "_" . $plotL->GetComp();
	}

	return $fName;
}

sub GetOutputLayerName {
	my $self  = shift;
	

	my $lName = $self->GetOutputFileName();
	$lName =~ s/^[a-z]\d*//;
	$lName =~ s/@//;

	return $lName;
}

sub GetOutputItemName {
	my $self  = shift;
	
	my $str = "";

	# Select layer by layer
	foreach my $plotL ( $self->GetLayers() ) {
		
		if($str ne ""){
			$str .= "+";
		}
		
		$str .= $plotL->GetName();
	}

	return $str;
}


sub GetPolarity {
	my $self = shift;

	my $polarity;

	# Select layer by layer
	foreach my $plotL ( $self->GetLayers() ) {
		
		
		
		if( defined $polarity && $plotL->GetPolarity() ne $polarity){
			
			$polarity = "mixed";
			last;
		} 
		
		$polarity = $plotL->GetPolarity();
	}
	
	return $polarity;

}


 

#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;
