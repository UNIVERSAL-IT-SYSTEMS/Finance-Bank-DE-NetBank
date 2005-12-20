require 5.6.1;
use ExtUtils::MakeMaker qw( WriteMakefile );
use File::Spec;
use strict;

my $enable_livetest = grep /--livetest/i, @ARGV;
my @tests = glob File::Spec->catfile( 't', '*.t' );
push( @tests, glob File::Spec->catfile( 't', 'methods', '*.t' ) );
push( @tests, glob File::Spec->catfile( 't', 'methods', 'live', '*.t' ) ) if $enable_livetest;



my $params = {
    NAME          => 'Finance::Bank::DE::NetBank',
    ABSTRACT_FROM => 'lib/Finance/Bank/DE/NetBank.pm', # retrieve abstract from module
    VERSION_FROM  => 'lib/Finance/Bank/DE/NetBank.pm', # finds $VERSION
    AUTHOR        => 'Roland Moriz (rmoriz@cpan.org)',
    PREREQ_PM    => {	
        "WWW::Mechanize"    => "1.16",
        "Class::Accessor"   => "0.22",
        "Text::CSV_XS"      => "0.23",
    },	      
    test            => { TESTS => join( " ", @tests ) },
};

if (MM->can('signature_target')) {
    $params->{'SIGN'} = 1;
}

WriteMakefile( %$params );

