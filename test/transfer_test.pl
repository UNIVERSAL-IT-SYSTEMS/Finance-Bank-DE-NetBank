#!/usr/bin/perl -w

use strict;
use lib "../lib";
use Finance::Bank::DE::NetBank;
use Data::Dumper;

my $account = Finance::Bank::DE::NetBank->new();
$account->Debug(1);
$account->connect();
$account->login();
print $account->transfer(

		   RECEIVER_NAME => "Bill Gates",
		   RECEIVER_ACCOUNT => "999999",
		   RECEIVER_BLZ => "99999999",
		   RECEIVER_SAVE => 0,
		   COMMENT_1 => "WINDOWS",
		   COMMENT_2 => "LICENSES",
		   AMOUNT => "00.01",
		   TAN => "018316",
		   
);
$account->logout();

print "\n";
