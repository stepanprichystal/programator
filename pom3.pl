#!/usr/bin/perl

#-------------------------------------------------------------------------------------------#
# Description: Do final routing = 2mm with compensation left and suitable start of chain
# Author:SPR
#-------------------------------------------------------------------------------------------#

#3th party library
use strict;
use warnings;
use Path::Tiny qw(path);
use Log::Log4perl qw(get_logger :levels);
use aliased 'Helpers::JobHelper';
use aliased 'CamHelpers::CamJob';
 
my %t = get();

my @v = values(%t);

die "test";

sub get{
	my %test = ( "t" => 1, "t2" => 3 );

	return %test;
}
