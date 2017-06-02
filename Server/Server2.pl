# TCP port forwarder with logging
  # Works on Win32!
  
  use strict;
  use Net::Socket::NonBlock;

  $|++;
  
  my $LocalPort   = 2222;
       # or die "Usage: $0 <LocalPort> <RemoteHost:RemotePort>\n";
  my $RemoteHost  = 'localhost';
       # or die "Usage: $0 <LocalPort> <RemoteHost:RemotePort>\n";
  
  my $SockNest = Net::Socket::NonBlock::Nest->new(SelectT  => 0.1,
                                                  SilenceT => 0,
                                                  debug    => $^W,
                                                  BuffSize => 10240,
                                                 )
        or die "Error creating sockets nest: $@\n";
  
  $SockNest->Listen(LocalPort => $LocalPort,
                    Proto     => 'tcp',
                    Accept    => \&NewConnection,
                    SilenceT  => 0,
                    #ClientsST => 10,
                    Listen    => 10,)
        or die "Could not listen on port '$LocalPort': $@\n";
  
  my %ConPool = ();

  while($SockNest->IO())
        {
        my $Pstr = '';
        my $ClnSock = undef;
        my $SrvSock = undef;
        while (($ClnSock, $SrvSock) = each(%ConPool))
                {
                my $ClientID = sprintf("%15.15s:%-5.5s", $SockNest->PeerAddr($ClnSock), $SockNest->PeerPort($ClnSock));
                my $Str = undef;
                while(($Str = $SockNest->Read($ClnSock)) && length($Str))
                        {
                        $Pstr .= "  $ClientID From CLIENT ".SafeStr($Str)."\n";
                        $SrvSock->Puts($Str);
                        };
                if (!defined($Str))
                        {
                        $Pstr .= "  $ClientID CLIENT closed\n"; 
                        $SockNest->Close($ClnSock); # Old-style method call
                        $SrvSock->Close();          # OO-style method call
                        delete($ConPool{$ClnSock});
                        next;
                        };
                while(($Str = $SrvSock->Read()) && length($Str))
                        {
                        $Pstr .= "  $ClientID From SERVER ".SafeStr($Str)."\n";
                        $SockNest->Puts($ClnSock, $Str);
                        };
                if (!defined($Str))
                        {
                        $Pstr .= "  $ClientID SERVER closed\n"; 
                        $SockNest->Close($ClnSock);
                        $SrvSock->Close();
                        delete($ConPool{$ClnSock});
                        next;
                        };
                };
        if (length($Pstr))
                { print localtime()."\n".$Pstr; };
        };              
  
  sub NewConnection
        {
        my ($ClnSock) = shift
                or return;

        $ConPool{$ClnSock} = $SockNest->Connect(PeerAddr => $RemoteHost, PeerPort => 2222, Proto => 'tcp',);
        if(!$ConPool{$ClnSock})
                {
                warn "Can not connect to '$RemoteHost': $@\n";
                $ClnSock->Close();
                delete($ConPool{$ClnSock});
                return;
                };
        return 1;
        };

  sub SafeStr
        {
        my $Str = shift
                or return '!UNDEF!';
        $Str =~ s{ ([\x00-\x1f\xff\\]) } { sprintf("\\x%2.2X", ord($1)) }gsex;
        return $Str;
        };