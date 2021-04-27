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

use aliased "Enums::EnumsPaths";

my $p = EnumsPaths->Jobs_MDITT;

#my $p  = "c:\\Export\\test\\test\\";

my $dir;
opendir( $dir, $p ) or die $!;

my $exist = 0;

my $i = 0;
my $total = 0;
while ( my $filename = readdir($dir) ) {

	next unless($filename =~ /joblayer\.xml/);
	
	
		my $file = path($p.$filename);

		my $data = $file->slurp_utf8;

			#lower_tolerance_factor="-0.75"

		if ( $data =~ /lower_tolerance_factor="-0.75"/ ) {
			
			$data =~ s/lower_tolerance_factor="-0.75"/lower_tolerance_factor="-0.075"/i;
			
		 
			$file->spew_utf8($data);
			
			$i++;
			
			print "$i: ".$file."\n";
		}

	$total++;

}

print "Total:".$total;

#	foreach my $filename (@xmlFiles) {
#
#		$logger->debug("update file: $filename");
#
#		my $file = path($filename);
#
#		my $data = $file->slurp_utf8;
#
#		if ( $data =~ /(<parts_remaining>)(\d*)(<\/parts_remaining>)/ ) {
#			$logger->debug("parts_remaining found ok");
#		}
#
#		$data =~ s/(<parts_remaining>)(\d*)(<\/parts_remaining>)/$1$parts$3/i;
#		$data =~ s/(<parts_total>)(\d*)(<\/parts_total>)/$1$parts$3/i;
#		$file->spew_utf8($data);
#
#	}

1;

die;

# $jobconfig->insertAfter( $eleml );
#  my  $jobconfig2= ( $doc->findnodes('/jobconfig/job_layer') )[-1];
#   $jobconfig2->addSibling( $eleml2 );
#
#
#
#my $outPath =  "c:\\Export\\test\\Final\\script\\out.xml";
### save
#open my $out, '>', $outPath;
#binmode $out; # as above
#$doc->toFH($out, 2);
### or
##print {$out} $doc->toString();
#
##use XML::LibXML::PrettyPrint;
##
##my $document = XML::LibXML->new->parse_file($outPath);
##my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
###$pp->pretty_print($document); # modified in-place
###
###
##die;
