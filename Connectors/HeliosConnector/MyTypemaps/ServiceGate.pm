
package Connectors::HeliosConnector::MyTypemaps::ServiceGate;
use strict;
use warnings;

our $typemap_1 = {
               'ProcessXml' => 'Connectors::HeliosConnector::MyElements::ProcessXml',
               'KeepAlive/sessionToken' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'KeepAliveResponse' => 'Connectors::HeliosConnector::MyElements::KeepAliveResponse',
               'KeepAlive' => 'Connectors::HeliosConnector::MyElements::KeepAlive',
               'LogOff/sessionToken' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'ProcessXmlResponse' => 'Connectors::HeliosConnector::MyElements::ProcessXmlResponse',
               'Fault/faultcode' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
               'KeepAliveResponse/KeepAliveResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LogOn/profile' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'ProcessXmlResponse/ProcessXmlResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/faultstring' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault' => 'SOAP::WSDL::SOAP::Typelib::Fault11',
               'LogOnResponse/LogOnResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/faultactor' => 'SOAP::WSDL::XSD::Typelib::Builtin::token',
               'LogOn/username' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'ProcessXml/sessionToken' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'ProcessXml/inputXml' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/detail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LogOn' => 'Connectors::HeliosConnector::MyElements::LogOn',
               'LogOn/language' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LogOn/password' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LogOffResponse' => 'Connectors::HeliosConnector::MyElements::LogOffResponse',
               'LogOff' => 'Connectors::HeliosConnector::MyElements::LogOff',
               'LogOn/options' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LogOffResponse/LogOffResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'LogOnResponse' => 'Connectors::HeliosConnector::MyElements::LogOnResponse'
             };
;

sub get_class {
  my $name = join '/', @{ $_[1] };
  return $typemap_1->{ $name };
}

sub get_typemap {
    return $typemap_1;
}

1;

__END__

__END__

=pod

=head1 NAME

MyTypemaps::ServiceGate - typemap for ServiceGate

=head1 DESCRIPTION

Typemap created by SOAP::WSDL for map-based SOAP message parsers.

=cut

