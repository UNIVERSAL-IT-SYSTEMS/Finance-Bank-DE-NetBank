#!/usr/bin/perl -w

use strict;
use lib "../lib";
use Finance::Bank::DE::NetBank;
use Data::Dumper;

my $account = Finance::Bank::DE::NetBank->new();
$account->connect();
$account->login();
print Dumper $account->statement();
$account->logout();

print "\n";
