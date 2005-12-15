#!/usr/bin/perl -w

use strict;
use lib "../lib";
use Finance::Bank::DE::NetBank;
use Data::Dumper;

$| = 1;

my $account = Finance::Bank::DE::NetBank->new();

$account->Debug(1);
$account->login();

print $account->saldo();
print Dumper($account->statement());

$account->logout();

print "\n";
