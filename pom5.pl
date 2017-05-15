
use lib qw( C:\Perl\site\lib\TpvScripts\Scripts );

######### System initialization section ###
use Log::Log4perl qw(get_logger :levels);

my $food_logger = get_logger("Groceries");
$food_logger->level($DEBUG);

# Appenders
my $appenderFile = Log::Log4perl::Appender->new(
												 "Log::Dispatch::File",
												 filename => "test.log",
												 mode     => "append",
);

my $appenderScreen = Log::Log4perl::Appender->new(
	 
		   'Log::Dispatch::Screen',
		   #min_level => 'debug',
		   stderr    => 1,
		   newline   => 1
		 
);

$food_logger->add_appender($appenderFile);
$food_logger->add_appender($appenderScreen);

# Layouts
my $layout = Log::Log4perl::Layout::PatternLayout->new("%d %p> %F{1}:%L %M - %m%n");
$appenderFile->layout($layout);
$appenderScreen->layout($layout);
######### Run it ##########################
my $food = Groceries::Food->new("Sushi");
$food->consume();

######### Application section #############
package Groceries::Food;

use Log::Log4perl qw(get_logger);

sub new {
	my ( $class, $what ) = @_;
	my $logger = get_logger("Groceries::Food");

	if ( defined $what ) {
		$logger->debug("New food: $what");
		return bless { what => $what }, $class;
	}

	$logger->error("No food defined");
	return undef;
}

sub consume {
	my ($self) = @_;

	my $logger = get_logger("Groceries::Food");
	$logger->info("Eating $self->{what}");
}
