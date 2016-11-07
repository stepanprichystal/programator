
#-------------------------------------------------------------------------------------------#
# Description: Cover exporting layers for particular machine, which can procces given nc file
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Scoring::ScoreOptimize::ScoreLayer::ScoreLayer;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Packages::Scoring::ScoreChecker::Enums';
use aliased 'Packages::Scoring::ScoreChecker::Enums' => "ScoEnums";
#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $class = shift;

	my $self = {};
	bless $self;
 
	my @sets = ();
	$self->{"scoreSets"} = \@sets;
	


	return $self;
}

sub GetSets {
	my $self = shift;
	my $dir  = shift;

	my @sets = @{ $self->{"scoreSets"} };

	if ($dir) {

		@sets = grep { $_->GetDirection() eq $dir } @sets;
	}

	return @sets;
}


sub ExistVScore{
	my $self = shift;
	
	my @sets = $self->GetSets(ScoEnums->Dir_VSCORE);
	
	if(scalar(@sets)){
		
		return 1;
	}else{
		return 0;
	}
}

sub ExistHScore{
	my $self = shift;
	
	my @sets = $self->GetSets(ScoEnums->Dir_HSCORE);
	
	if(scalar(@sets)){
		
		return 0;
	}else{
		return 1;
	}
}

sub AddScoreSet {
	my $self = shift;
	my $set  = shift;

	push( @{ $self->{"scoreSets"} }, $set );

}




sub ResetOrigin {
	my $self      = shift;
	
	my %newOrigin = ("x" => 0, "y" => 0);
	
	$self->SetNewOrigin(\%newOrigin);
	
	
}

sub SetNewOrigin {
	my $self      = shift;
	my $origin = shift;	
	
	my %newOrigin = ("x" => $origin->{"x"} *1000, "y" => $origin->{"y"} *1000 );
	
	 

	foreach my $set ( @{ $self->{"scoreSets"} } ) {

		my $dir = $set->GetDirection();

		# set set point
		my $point = $set->GetPoint();

		if ( $dir eq ScoEnums->Dir_HSCORE ) {

			$point -= $newOrigin{"y"}

		}
		elsif ( $dir eq ScoEnums->Dir_VSCORE ) {
			$point -= $newOrigin{"x"};
		}

		# set set score lines
		foreach my $line ( $set->GetLines() ) {

			my $s = $line->GetStartP();
			my $e = $line->GetEndP();

			$s->{"x"} -= $newOrigin{"x"};
			$s->{"y"} -= $newOrigin{"y"};

			$e->{"x"} -= $newOrigin{"x"};
			$e->{"y"} -= $newOrigin{"y"};
		}
	}
}

sub Rotate90 {
	my $self      = shift;
	my $origin = shift;
	my $pnlWidth = shift;
	
	my %newOrigin = ("x" => $origin->{"x"} *1000, "y" => $origin->{"y"} *1000 );
	
	$pnlWidth *= 1000;

	foreach my $set ( @{ $self->{"scoreSets"} } ) {

		my $dir = $set->GetDirection();

		# set set point
		my $point = $set->GetPoint();

		if ( $dir eq ScoEnums->Dir_HSCORE ) {

			$point = $newOrigin{"y"};
		}
		 

		# set set score lines
		foreach my $line (   $set->GetLines()  ) {

			my $s = $line->GetStartP();
			my $e = $line->GetEndP();

			$s->{"x"} = $s->{"y"};
			$s->{"y"} = $pnlWidth - $s->{"x"};
			
			$e->{"x"} = $s->{"y"};
			$e->{"y"} = $pnlWidth - $s->{"x"};
 
		}
	}
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

