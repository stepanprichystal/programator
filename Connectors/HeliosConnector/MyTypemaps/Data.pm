
package Connectors::HeliosConnector::MyTypemaps::Data;
use strict;
use warnings;

our $typemap_1 = {
               'Fault/faultcode' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
               'GetInfoResponse' => 'Connectors::HeliosConnector::MyElements::GetInfoResponse',
               'GetInfo/myValue' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'GetInfo' => 'Connectors::HeliosConnector::MyElements::GetInfo',
               'Fault/detail' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'GetInfoResponse/GetInfoResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault/faultstring' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'GetInfo/myCode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
               'Fault' => 'SOAP::WSDL::SOAP::Typelib::Fault11',
               'Fault/faultactor' => 'SOAP::WSDL::XSD::Typelib::Builtin::token'
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

MyTypemaps::Data - typemap for Data

=head1 DESCRIPTION

Typemap created by SOAP::WSDL for map-based SOAP message parsers.

=cut

