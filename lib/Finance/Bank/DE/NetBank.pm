package Finance::Bank::DE::NetBank;

use strict;
use vars qw($VERSION @ISA);
use Finance::Bank::DE::SpardaBank;

@ISA = qw( Finance::Bank::DE::SpardaBank );

$|++;

$VERSION = "0.03";

sub Version { 
    return $VERSION;
}

sub new {
    my $proto  = shift;
    my %values = (
		  BASE_URL => "https://www.netbank-money.de/netbank-banking/view/",
		  BLZ => "20090500",         # NetBank BLZ            
		  CUSTOMER_ID => "demo",     # Demo Login
		  PASSWORD => "",            # Demo does not require a password
		  ACCOUNT => "2777770",      # Demo Account Number (Kontonummer)
                  AGENT_TYPE => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1) ",
		  , @_);

    if ($values{'CUSTOMER_ID'} ne "demo" && $values{'ACCOUNT'} eq "2777770") {
	$values{'ACCOUNT'} = $values{'CUSTOMER_ID'};
    }

    my $class  = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;

    my $self = {};
    bless($self, $class);

    foreach my $key (keys %values) {
	$self->$key("$values{$key}");
    }
    return $self;
}



1;
__END__
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

Finance::Bank::DE::NetBank - Check your NetBank Bank Accounts with Perl

=head1 SYNOPSIS

 use Finance::Bank::DE::NetBank;
 my $account = Finance::Bank::DE::NetBank->new(
						 CUSTOMER_ID => "12345678",
						 ACCOUNT_ID => "12345678",
						 PASSWORD => "ROUTE66",
                                                 );
 $account->connect(); 
 $account->login();
 print $account->saldo();
 $account->logout();

=head1 DESCRIPTION

This module extends the Finance::Bank::DE::SpardaBank module for usage with
the online banking service provided by the german NetBank (www.netbank.de).

All methods are included from Finance::Bank::DE::SpardaBank - only the
constructor is modified to fit with the NetBank Website.

It uses OOD and doesn't export anything.

B<WARNING!> This module is neither offical nor is it tested to be 100% save! 
Because of the nature of web-robots, B<everything may break from one day to
the other> when the underlaying web interface changes.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 METHODS

=head2 new(%values) 

This constructor will set the default values and/or user provided values for
connection and authentication.

my $account = Finance::Bank::DE::NetBank->new (
                  CUSTOMER_ID => "demo",    
                  PASSWORD => "",      
                  ACCOUNT => "2777770",   
	      , @_);

If you don't provide any values the module will automatically use the demo account.

CUSTOMER_ID is your "Kundennummer" and ACCOUNT is the "Kontonummer" 
(if you have only one account you can skip that)

=head2 connect()

This method will create the user agent and connect to the online banking website.
Also this (done by WWW::Mechanize) automagically handles the session-id handling.

    $account->connect();

=head2 login(%values)

This method will try to log in with the provided authentication details. If
nothing is specified the values from the constructor or the defaults will be used.

    $account->login(ACCOUNT => "1234");

=head2 saldo(%values)

This method will return the current account balance called "Saldo".
The method uses the account number if previously set.

You can override/set it:

    $account->saldo(ACCOUNT => "5555555");

=head2 statement(%values)

This method will retrieve an Account Statement (Kontoauszug). You can specify the 
timeframe of the statement by passing different arguments.

The value of TIMEFRAME can be "1" (last day only), "30" (last 30 days only), "alle" (all possible) or "variable" (between
START_DATE and END_DATE only).

 $account->statement(
                                 TIMEFRAME => "variabel",
                                 START_DATE => "10.04.2003",
                                 END_DATE => "02.05.2003",

			    );

=head2 logout()

This method will just log out the website and it's only existent to keep the module logic clean ;-)


=head1 USAGE


 use Finance::Bank::DE::NetBank;
 use Data::Dumper;

 my $account = Finance::Bank::DE::NetBank->new(
                                                 CUSTOMER_ID => "xxxxxxx",
                                                 ACCOUNT => "yyyyyyy",
                                                 PASSWORD => "zzzzzz",
                                                 );
 $account->connect();
 $account->login();
 print Dumper($account->statement(
                                 TIMEFRAME => "variabel",
                                 START_DATE => "10.04.2003",
                                 END_DATE => "02.05.2003",
 				 )
             );
 $account->logout();


=head1 BUGS

Please report bugs via 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-DE-NetBank>

=head1 SUPPORT

Support currently available via eMail to the author.

=head1 HISTORY

0.02 Sun May 04 15:45:00 2003
        - documentation fixes

0.01 Sun May 04 03:00:00 2003
	- original version;

=head1 AUTHOR

 Roland Moriz
 rmoriz@cpan.org && roland@moriz.de
 http://www.roland-moriz.de/

Disclaimer stolen from Simon Cozens' Finance::Bank::LloydsTSB without asking for permission %-)

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Finance::Bank::DE::SpardaBank, WWW::Mechanize, Finance::Bank::LloydsTSB

=cut



