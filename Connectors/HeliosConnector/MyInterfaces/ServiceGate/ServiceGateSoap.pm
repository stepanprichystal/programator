package Connectors::HeliosConnector::MyInterfaces::ServiceGate::ServiceGateSoap;
use strict;
use warnings;
use Class::Std::Fast::Storable;
use Scalar::Util qw(blessed);
use base qw(SOAP::WSDL::Client::Base);

# only load if it hasn't been loaded before
require Connectors::HeliosConnector::MyTypemaps::ServiceGate
    if not Connectors::HeliosConnector::MyTypemaps::ServiceGate->can('get_class');

sub START {
    $_[0]->set_proxy('http://heg.gatema.cz/GatemaA1/ServiceGate.asmx') if not $_[2]->{proxy};
    $_[0]->set_class_resolver('Connectors::HeliosConnector::MyTypemaps::ServiceGate')
        if not $_[2]->{class_resolver};

    $_[0]->set_prefix($_[2]->{use_prefix}) if exists $_[2]->{use_prefix};
}
sub LogOn {
    my ($self, $body, $header) = @_;
    die "LogOn must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'LogOn',
        soap_action => 'http://lcs.cz/webservices/LogOn',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Connectors::HeliosConnector::MyElements::LogOn )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub ProcessXml {
    my ($self, $body, $header) = @_;
    die "ProcessXml must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'ProcessXml',
        soap_action => 'http://lcs.cz/webservices/ProcessXml',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Connectors::HeliosConnector::MyElements::ProcessXml )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub LogOff {
    my ($self, $body, $header) = @_;
    die "LogOff must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'LogOff',
        soap_action => 'http://lcs.cz/webservices/LogOff',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Connectors::HeliosConnector::MyElements::LogOff )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}


sub KeepAlive {
    my ($self, $body, $header) = @_;
    die "KeepAlive must be called as object method (\$self is <$self>)" if not blessed($self);
    return $self->SUPER::call({
        operation => 'KeepAlive',
        soap_action => 'http://lcs.cz/webservices/KeepAlive',
        style => 'document',
        body => {
            

           'use'            => 'literal',
            namespace       => 'http://schemas.xmlsoap.org/wsdl/soap/',
            encodingStyle   => '',
            parts           =>  [qw( Connectors::HeliosConnector::MyElements::KeepAlive )],
        },
        header => {
            
        },
        headerfault => {
            
        }
    }, $body, $header);
}




1;



__END__

=pod

=head1 NAME

MyInterfaces::ServiceGate::ServiceGateSoap - SOAP Interface for the ServiceGate Web Service

=head1 SYNOPSIS

 use MyInterfaces::ServiceGate::ServiceGateSoap;
 my $interface = MyInterfaces::ServiceGate::ServiceGateSoap->new();

 my $response;
 $response = $interface->LogOn();
 $response = $interface->ProcessXml();
 $response = $interface->LogOff();
 $response = $interface->KeepAlive();



=head1 DESCRIPTION

SOAP Interface for the ServiceGate web service
located at http://heg.gatema.cz/GatemaA1/ServiceGate.asmx.

=head1 SERVICE ServiceGate



=head2 Port ServiceGateSoap



=head1 METHODS

=head2 General methods

=head3 new

Constructor.

All arguments are forwarded to L<SOAP::WSDL::Client|SOAP::WSDL::Client>.

=head2 SOAP Service methods

Method synopsis is displayed with hash refs as parameters.

The commented class names in the method's parameters denote that objects
of the corresponding class can be passed instead of the marked hash ref.

You may pass any combination of objects, hash and list refs to these
methods, as long as you meet the structure.

List items (i.e. multiple occurences) are not displayed in the synopsis.
You may generally pass a list ref of hash refs (or objects) instead of a hash
ref - this may result in invalid XML if used improperly, though. Note that
SOAP::WSDL always expects list references at maximum depth position.

XML attributes are not displayed in this synopsis and cannot be set using
hash refs. See the respective class' documentation for additional information.



=head3 LogOn



Returns a L<MyElements::LogOnResponse|MyElements::LogOnResponse> object.

 $response = $interface->LogOn( {
    profile =>  $some_value, # string
    username =>  $some_value, # string
    password =>  $some_value, # string
    language =>  $some_value, # string
    options =>  $some_value, # string
  },,
 );

=head3 ProcessXml



Returns a L<MyElements::ProcessXmlResponse|MyElements::ProcessXmlResponse> object.

 $response = $interface->ProcessXml( {
    sessionToken =>  $some_value, # string
    inputXml =>  $some_value, # string
  },,
 );

=head3 LogOff



Returns a L<MyElements::LogOffResponse|MyElements::LogOffResponse> object.

 $response = $interface->LogOff( {
    sessionToken =>  $some_value, # string
  },,
 );

=head3 KeepAlive



Returns a L<MyElements::KeepAliveResponse|MyElements::KeepAliveResponse> object.

 $response = $interface->KeepAlive( {
    sessionToken =>  $some_value, # string
  },,
 );



=head1 AUTHOR

Generated by SOAP::WSDL on Wed Aug 21 06:54:28 2013

=cut
