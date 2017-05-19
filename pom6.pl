#use Log::Log4perl qw(:easy);
use Log::Log4perl qw(get_logger :levels);
#
#Log::Log4perl->easy_init(
#	{
#	  level  => $DEBUG,
#	  file   => 'test.out',        # make sure not to use stderr here!
#	  layout => "%d %M: %m%n",
#	}
#);

my $mainLogger = get_logger("test");
$mainLogger->level($DEBUG);

# Appenders
my $appenderFile = Log::Log4perl::Appender->new(
												 'Log::Log4perl::Appender::File::FixedSize',
												 filename => "test.out2",
												 mode     => "append",
												 size     => '1Kb'
);

my $layout = Log::Log4perl::Layout::PatternLayout->new("%d> %m%n ");
$appenderFile->layout($layout);

$mainLogger->add_appender($appenderFile);

tie *STDERR, "Trapper";
tie *STDOUT, "Trapper";

print STDERR "test";
print STDERR "test";
print STDERR "test2";
print STDERR "test2";

########################################
package Trapper;
########################################

#use Log::Log4perl qw(:easy);
use Log::Log4perl qw(get_logger :levels);

#use Log::Log4perl qw(:easy);

sub TIEHANDLE {
	my $class = shift;
	bless [], $class;

}

sub PRINT {
	my $self = shift;

	#$Log::Log4perl::caller_depth++;
	get_logger("test")->Error(@_);

	#$Log::Log4perl::caller_depth--;
}

1;
