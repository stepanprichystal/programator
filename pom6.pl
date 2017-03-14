#!/usr/bin/perl -w

#3th party library
use strict;
use warnings;
use utf8;

#use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

#necessary for load pall packagesff
use FindBin;
use lib "$FindBin::Bin/../";
use PackagesLib;

use aliased 'Packages::InCAM::InCAM';


my $inCAM = InCAM->new();

my @arr = GetAttrParams($inCAM);
 
sub GetAttrParams {
	 
	my $inCAM = shift;
	my $jobId = shift;

	my @arr = ();

	$inCAM->INFO(
				  units           => 'mm',
				  angle_direction => 'ccw',
				  entity_type     => 'attributes',
				  #entity_path     => "$jobId",
				  data_type       => 'ATR',
				  parameters      => "name+type"
	);

	for ( my $i = 0 ; $i < scalar( @{ $inCAM->{doinfo}{gATRname} } ) ; $i++ ) {
		my %info = ();
		$info{"gATRname"} = ${ $inCAM->{doinfo}{gATRname} }[$i];
		$info{"gATRtype"} = ${ $inCAM->{doinfo}{gATRtype} }[$i];
		push( @arr, \%info );

	}
	return @arr;
}