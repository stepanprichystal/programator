#########################################
#package Trapper;
#########################################
#
##use Log::Log4perl qw(:easy);
#use Log::Log4perl qw(get_logger :levels);
#
#sub TIEHANDLE {
#	my $class = shift;
#	bless [], $class;
#}
#
#sub PRINT {
#	my $self = shift;
#
#	# $Log::Log4perl::caller_depth++;
#	#DEBUG @_;
#	#$Log::Log4perl::caller_depth--;
#	get_logger("stdOutput")->Error(@_);
#}