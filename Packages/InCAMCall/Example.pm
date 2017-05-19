
#-------------------------------------------------------------------------------------------#
# Description: Example of InCAM call
#
# Author:SPR
#-------------------------------------------------------------------------------------------#

#  ============  HOW to use InCAM call ====================

#	my $paskageName = "Packages::InCAMCall::Example";
#	my @par1        = ( "k" => "1" );
#	my %par2      = ( "par1", "par2" );
	

#	my $call = InCAMCall->new( $paskageName, \@par1, \%par2 );
 
#	my $result = $call->Run();   # return 0, when script fail, else 1
#
#	my %result = $call->GetOutput();

package Packages::InCAMCall::Example;

#3th party library
use threads;
use strict;
use warnings;



#-------------------------------------------------------------------------------------------#
#  Script code
#-------------------------------------------------------------------------------------------#

sub new {
	my $self = shift;
	$self = {};
	bless $self;
	
	print STDERR "Example package NEW method\n";

	return $self;
}

# Mandatory method, contain working code
sub Run {
	my $self       = shift;
	my $inCAM      = shift;             # Incam library connected to incam
	my @params     = @{ shift(@_) };    # parameter, passed to InCAMCall constructor (@params)
	my $resultHash = shift;             # store results here, values can be references (result is tored in json and converted back)

	print STDERR "Example package RUN method\n";
	
	$inCAM->COM("get_user_name");
	my $userName = $inCAM->GetReply();
	print STDERR "Some test answer from incam, user name: ". $userName;

	# sotre some results fo result hash
	my @arr = ( 10, 20 );

	$resultHash->{"userName"} = $userName;
	$resultHash->{"arr"}    = \@arr;
	$resultHash->{"test"}   = "12345";
	$resultHash->{"result"} = 1;
}
 

1;
