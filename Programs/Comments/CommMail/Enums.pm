
package Programs::Comments::CommMail::Enums;

# Email subject types
use constant {
			   Subject_JOBFINIFHAPPROVAL    => "Approval before production",
			   Subject_JOBPROCESSAPPROVAL   => "Technical question",
			   Subject_OFFERFINIFHAPPROVAL  => "RFQ approval",
			   Subject_OFFERPROCESSAPPROVAL => "RFQ technical question"
};

# Email action types
use constant {
			   EmailAction_SEND => "emailAction_send",
			   EmailAction_OPEN => "emailAction_open",
};

1;
