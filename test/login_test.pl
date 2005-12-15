#!/usr/bin/perl -w

use strict;
use lib "../lib";
use Finance::Bank::DE::NetBank;
use Data::Dumper;

$| = 1;

my $account = Finance::Bank::DE::NetBank->new();
$account->Debug(0);

print "working login:";
my $status = $account->login();

if ($status) {
    print "\t - login correct (OK).\n";
} else {
    print "\t - login failure.\n";
}

$account->logout();


print "broken login:";
$account->CUSTOMER_ID("broken");
$status = $account->login();

if ($status) {
    print "\t - login correct.\n";
} else {
    print "\t - login failure (OK).\n";
}

print "statement request with broken login:";
$status = $account->statement();

if ($status) {
    print "\t - got statement (dubious).\n";
} else {
    print "\t - statement failed (OK).\n";
}


$account->logout();

print "\n";
