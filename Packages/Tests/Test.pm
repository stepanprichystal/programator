
#-------------------------------------------------------------------------------------------#
# Description: Class for testin modules
# Author:SPR
#-------------------------------------------------------------------------------------------#
package Packages::Tests::Test;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(DiagSTDERR);

#3th party library
use strict;
use warnings;

#local library

#-------------------------------------------------------------------------------------------#
#  Public object method
#-------------------------------------------------------------------------------------------#

sub new {
	my $class = shift;
	my $print = shift // 0;

	my $self = {};

	$self->{"print"} = $print;

	bless $self;
}

sub GetDiag {
	my $class = shift;
	my $print = shift;

	#use aliased 'Packages::Tests::Test';

	my $d = $class->new($print);

	return $d;
}

sub Diag {
	my $self = shift;
	my $text = shift;

	print STDERR $text . "\n" if($self->{"print"});

}



#-------------------------------------------------------------------------------------------#
#  Public Class method
#-------------------------------------------------------------------------------------------#

# Print dierctly to standard error
sub DiagSTDERR {
	my $text = shift;

	print STDERR $text . "\n";
}



#-------------------------------------------------------------------------------------------#
#  Place for testing..
#-------------------------------------------------------------------------------------------#
my ( $package, $filename, $line ) = caller;
if ( $filename =~ /DEBUG_FILE.pl/ ) {

}

1;

