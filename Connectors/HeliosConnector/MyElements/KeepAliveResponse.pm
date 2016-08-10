
package Connectors::HeliosConnector::MyElements::KeepAliveResponse;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'http://lcs.cz/webservices/' }

__PACKAGE__->__set_name('KeepAliveResponse');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();

use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    SOAP::WSDL::XSD::Typelib::ComplexType
);

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %KeepAliveResult_of :ATTR(:get<KeepAliveResult>);

__PACKAGE__->_factory(
    [ qw(        KeepAliveResult

    ) ],
    {
        'KeepAliveResult' => \%KeepAliveResult_of,
    },
    {
        'KeepAliveResult' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'KeepAliveResult' => 'KeepAliveResult',
    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

MyElements::KeepAliveResponse

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
KeepAliveResponse from the namespace http://lcs.cz/webservices/.







=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * KeepAliveResult

 $element->set_KeepAliveResult($data);
 $element->get_KeepAliveResult();





=back


=head1 METHODS

=head2 new

 my $element = MyElements::KeepAliveResponse->new($data);

Constructor. The following data structure may be passed to new():

 {
   KeepAliveResult =>  $some_value, # string
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut

