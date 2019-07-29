
#-------------------------------------------------------------------------------------------#
# Description: Widget slouzici pro zobrazovani zprav ruznych typu uzivateli
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Programs::CamGuide::GuideSelector;

#3th party library
use strict;
use warnings;

#local library
use aliased 'Programs::CamGuide::Guides::GuideTypeOne';
use aliased 'Programs::CamGuide::Guides::GuideTypeTwo';
use aliased 'Programs::CamGuide::Guides::GuideTypeFlex';
use aliased 'Programs::CamGuide::Enums';

#use aliased 'Programs::CamGuide::Actions::MillingActions';
#use Programs::CamGuide::Actions::MillingActions;

#-------------------------------------------------------------------------------------------#
#  Package methods
#-------------------------------------------------------------------------------------------#

sub new {

	my $self = shift;    # Create an anonymous hash, and #self points to it.
	$self = {};
	bless $self;         # Connect the hash to the package Cocoa.

	my $pcbId      = shift;
	my $childPcbId = shift;

	my %pcbInfo = ();
	$pcbInfo{"pcbId"}      = $pcbId;
	$pcbInfo{"childPcbId"} = $childPcbId;
	$self->{'pcbInfo'}     = \%pcbInfo;

	$self->__GetPcbProperties();
	$self->__SetTable();

	return $self;    # Return the reference to the hash.
}

sub Get {

	my $self       = shift;
	my $guidId     = shift;
	my $pcbId      = shift;
	my $inCAM      = shift;
	my $messMngr   = shift;
	my $childPcbId = shift;

	my $guid = undef;

	my $guidInfo = ( grep { $_->{"id"} == $guidId } @{ $self->{"guidTypes"} } )[0];

	my $className = $guidInfo->{"class"};

	if ( $guidId == 0 ) {

		$guid = GuideTypeOne->new( $pcbId, $inCAM, $messMngr, $childPcbId );

	}
	elsif ( $guidId == 1 ) {

		$guid = GuideTypeTwo->new( $pcbId, $inCAM, $messMngr, $childPcbId );
	}	elsif ( $guidId == 3 ) {

		$guid = GuideTypeFlex->new( $pcbId, $inCAM, $messMngr, $childPcbId );
	}

	if ( $guidId != $guid->{'guideId'} ) {

		printf STDERR ( Enums->ERR_GUIDEID, $className, $className );
		return 0;
	}

	return $guid;
}

sub __SetTable {
	my $self = shift;

	my @types = (
				  {
					 "id"    => 0,
					 "name"  => "Guid 2vv",
					 "class" => "GuideTypeOne",
				  },
				  {
					 "id"    => 1,
					 "name"  => "Guid 4vv",
					 "class" => "GuideTypeTwo",
				  },
				  				  {
					 "id"    => 3,
					 "name"  => "Guid Flex",
					 "class" => "GuideTypeFlex",
				  }
	);

	$self->{"guidTypes"} = \@types;
}

sub GetGuideTypes {
	my $self = shift;

	return $self->{"guidTypes"};
}

sub __GetPcbProperties {
	my $self  = shift;
	my $pcbId = $self->{'pcbInfo'}->{"pcbId"};

	my %pcbProp = ();

	for my $key (%pcbProp)
	{
		#$self->{'pcbInfo'}->{$key} = %pcbProp->{$key};
	}

}

sub GetGuideId {

	return 0;

}

sub __GetGuideByProperties {

}

1;
