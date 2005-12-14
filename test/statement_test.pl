#!/usr/bin/perl -w

use strict;
use lib "../lib";
use Finance::Bank::DE::NetBank;
use Data::Dumper;

sub Finance::Bank::DE::NetBank::debug { 1 };
my $account = Finance::Bank::DE::NetBank->new();
$account->Debug(1);
$account->connect();
$account->login();
print Dumper $account->statement();
$account->logout();

print "\n";
