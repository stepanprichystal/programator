
package Connectors::HeliosConnector::MyElements::LogOn;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'http://lcs.cz/webservices/' }

__PACKAGE__->__set_name('LogOn');
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

my %profile_of :ATTR(:get<profile>);
my %username_of :ATTR(:get<username>);
my %password_of :ATTR(:get<password>);
my %language_of :ATTR(:get<language>);
my %options_of :ATTR(:get<options>);

__PACKAGE__->_factory(
    [ qw(        profile
        username
        password
        language
        options

    ) ],
    {
        'profile' => \%profile_of,
        'username' => \%username_of,
        'password' => \%password_of,
        'language' => \%language_of,
        'options' => \%options_of,
    },
    {
        'profile' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'username' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'password' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'language' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'options' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'profile' => 'profile',
        'username' => 'username',
        'password' => 'password',
        'language' => 'language',
        'options' => 'options',
    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

MyElements::LogOn

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
LogOn from the namespace http://lcs.cz/webservices/.







=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * profile

 $element->set_profile($data);
 $element->get_profile();




=item * username

 $element->set_username($data);
 $element->get_username();




=item * password

 $element->set_password($data);
 $element->get_password();




=item * language

 $element->set_language($data);
 $element->get_language();




=item * options

 $element->set_options($data);
 $element->get_options();





=back


=head1 METHODS

=head2 new

 my $element = MyElements::LogOn->new($data);

Constructor. The following data structure may be passed to new():

 {
   profile =>  $some_value, # string
   username =>  $some_value, # string
   password =>  $some_value, # string
   language =>  $some_value, # string
   options =>  $some_value, # string
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut

