#!/usr/bin/perl -w

use strict;
use lib "../lib";
use Finance::Bank::DE::NetBank;
use Data::Dumper;

$| = 1;

my $account = Finance::Bank::DE::NetBank->new();
$account->Debug(1);

$account->connect();
$account->login();
print $account->saldo();
$account->logout();

print "\n";
