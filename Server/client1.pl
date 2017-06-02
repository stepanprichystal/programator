#!/usr/bin/perl
#tcpclient.pl

use IO::Socket::INET;

# flush after every write
$| = 1;

my ( $socket, $client_socket );

# creating object interface of IO::Socket::INET modules which internally creates
# socket, binds and connects to the TCP server running on the specific port.
$socket = new IO::Socket::INET(
								PeerHost => '127.0.0.1',
								PeerPort => '1200',
								Proto    => 'tcp',
) or die "ERROR in Socket Creation : $!\n";


# write on the socket to server.
$data = "DATA from Client 1";
print $socket "$data\n";

# receive some data
my $receive =  <$socket>;
print "Data froom server $receive\n";

# we can also send the data through IO::Socket::INET module,
# $socket->send($data);

sleep(2);
$socket->close();
