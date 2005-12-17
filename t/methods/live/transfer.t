#!perl

use strict;
use warnings;
use Test::More tests => 2;

use Finance::Bank::DE::NetBank;

my %config = (
        CUSTOMER_ID => "demo",        # Demo Login
        PASSWORD    => "",            # Demo does not require a password
        ACCOUNT     => "1234567",     # Demo Account Number (Kontonummer)
);

my $account = Finance::Bank::DE::NetBank->new(%config);

ok( defined($account->login()), 'login with offical demo login works');

ok( defined($account->transfer(
                RECEIVER_NAME => "Bill Gates",
                RECEIVER_ACCOUNT => "999999",
                RECEIVER_BLZ => "99999999",
                RECEIVER_SAVE => 0,
                COMMENT_1 => "WINDOWS",
                COMMENT_2 => "LICENSES",
                AMOUNT => "00.01",
                TAN => "018316")
    ), 'demo transfer' );

