package Finance::Bank::DE::NetBank;

use strict;
use vars qw($VERSION $DEBUG);
use base qw(Class::Accessor);
Finance::Bank::DE::NetBank->mk_accessors(
    qw(BASE_URL BLZ CUSTOMER_ID PASSWORD AGENT_TYPE AGENT ACCOUNT));

use WWW::Mechanize;
use HTML::TreeBuilder;
use Text::CSV_XS;
use Data::Dumper;

$| = 1;

$VERSION = "1.03";

sub Version {
    return $VERSION;
}

sub Debug {
    $_[1] ? $DEBUG = $_[1] : return $DEBUG;
}

sub new {
    my $proto  = shift;
    my %values = (
        BASE_URL =>
          "https://www.netbank-money.de/netbank-barrierefrei-banking/view/",
        BLZ         => "20090500",    # NetBank BLZ
        CUSTOMER_ID => "demo",        # Demo Login
        PASSWORD    => "",            # Demo does not require a password
        ACCOUNT     => "1234567",     # Demo Account Number (Kontonummer)
        AGENT_TYPE => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1) ",
        @_
    );

    my $class = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;

    my $self = {};
    bless( $self, $class );

    foreach my $key ( keys %values ) {
        $self->$key("$values{$key}");
    }

    return $self;
}

sub connect {
    my $self  = shift;
    print STDERR "Method connect() is deprecated. Use only login() instead!\n";
    return $self->login(@_);
}

sub login {
    my $self   = shift;
    my %values = (
        CUSTOMER_ID => $self->CUSTOMER_ID(),
        PASSWORD    => $self->PASSWORD(),
        @_
    );
    
    my $url   = $self->BASE_URL() . "index.jsp?blz=" . $self->BLZ();
    my $agent = WWW::Mechanize->new( agent => $self->AGENT_TYPE(), );
    $agent->get($url);
    $self->AGENT($agent);

    $agent->field( "kundennummer", $values{'CUSTOMER_ID'} );
    $agent->field( "pin",          $values{'PASSWORD'} );
    $agent->click();

    print STDERR Dumper( $agent->content ) if Debug();
    
    if ($agent->content =~ /fieldtableerrorred/ig) {
        return undef;
    }

    return 1;
 
}

sub saldo {
    my $self = shift;
    my $data = $self->statement(@_);
   
    if ($data) { 
        print STDERR Dumper($data) if Debug();
        return $data->{'STATEMENT'}{'SALDO'};
    } else {
        return undef;
    }
}

sub statement {
    my $self   = shift;
    my %values = (
        TIMEFRAME => "30"
        , # 1 or 30 days || "alle" = ALL || "variabel" = between START_DATE and END_DATE only
        START_DATE => 0,                  # dd.mm.yyyy
        END_DATE   => 0,                  # dd.mm.yyyy
        ACCOUNT    => $self->ACCOUNT(),
        @_
    );

    # get mainpage
    my $login_status = $self->login();
    return undef unless $login_status;
       
    my $agent = $self->AGENT();

#   If you've problems with your environmet settings activate this and "use encodings"
#   binmode(STDOUT, ":encoding(iso-8859-15)");

    $agent->field( "kontonummer", $values{'ACCOUNT'} );
    $agent->field( "zeitraum",    $values{'TIMEFRAME'} );

    if (   $values{'TIMEFRAME'} eq "variabel"
        && $values{'START_DATE'}
        && $values{'END_DATE'} )
    {
        $agent->field( "startdatum", $values{'START_DATE'} );
        $agent->field( "enddatum",   $values{'END_DATE'} );
    }

    $agent->click();
    $agent->get( $self->BASE_URL() . "/umsatzdownload.do" );

    my $content = $agent->content();
    print STDERR Dumper($content) if Debug();

    my $csv_content = $self->_parse_csv($content);
    return $csv_content;
}

sub transfer {
    my $self   = shift;
    my %values = (
        SENDER_ACCOUNT   => $self->ACCOUNT(),
        RECEIVER_NAME    => "",
        RECEIVER_ACCOUNT => "",
        RECEIVER_BLZ     => "",
        RECEIVER_SAVE    => "false",
        COMMENT_1        => "",
        COMMENT_2        => "",
        AMOUNT           => "0.00",
        TAN              => "",
        @_
    );
    
    # get mainpage
    my $login_status = $self->login();
    return undef unless $login_status;

    my $agent = $self->AGENT();
    my $url   = $self->BASE_URL();

    $agent->get( $url . "ueberweisung_per_heute_neu.do" );

    ( $values{'AMOUNT_EURO'}, $values{'AMOUNT_CENT'} ) =
      split( /\.|,/, $values{'AMOUNT'} );
    
    $values{'AMOUNT_CENT'} = sprintf( "%02d", $values{'AMOUNT_CENT'} );
    $agent->field( "auftraggeberKontonummer", $values{'SENDER_ACCOUNT'} );
    $agent->field( "empfaengerName", $values{'RECEIVER_NAME'} );
    $agent->field( "empfaengerBankleitzahl", $values{'RECEIVER_BLZ'} );
    $agent->field( "empfaengerKontonummer",  $values{'RECEIVER_ACCOUNT'} );
    $agent->field( "betragEuro", $values{'AMOUNT_EURO'} );
    $agent->field( "betragCent", $values{'AMOUNT_CENT'} );
    $agent->field( "verwendungszweck1", $values{'COMMENT_1'} );
    $agent->field( "verwendungszweck2", $values{'COMMENT_2'} );
    $agent->click("btnNeuSpeichern");

    # sure it's right ...
    $agent->field( "ubo", $values{'TAN'} );
    $agent->click("btnBestaetigen");

    # lazy error checking

    if ( $agent->content() =~ m|<span class="error">(.*)30017(.*)</span>| ) {
        $agent->content() =~ m|<span class="error">(.*?)</span>|;
        my $error = $1;
        print "ERROR: $error";
        return undef;
    } else {
        my $content = $agent->content();
        return $agent->content();
    }

}

sub logout {
    my $self  = shift;
    my $agent = $self->AGENT();
    my $url   = $self->BASE_URL();
    $agent->get( $url . "logout.do" );
}

sub _parse_csv {
    my $self        = shift;
    my $csv_content = shift;
    $csv_content =~ s/\r//gmi;
    $csv_content =~ s/\f//gmi;
    my @lines = split( "\n", $csv_content );
    my %data;

    my $csv = Text::CSV_XS->new(
        {
            sep_char => "\t",
            binary   => 1,      ### german umlauts...
        }
    );

    my $line_count = 0;

    foreach my $line (@lines) {
        my $status  = $csv->parse($line);
        my @columns = $csv->fields();
        $line_count++;

        ### Account Details ########################
        if ( $line_count > 3 && $line_count < 6 ) {
            $columns[0] =~ s/://;
            $data{"ACCOUNT"}{ uc( $columns[0] ) } = $columns[1];
        }

        ### Statement Details ######################
        if ( $line_count == 9 ) {
            $data{"STATEMENT"}{"START_DATE"} = $columns[0];
            $data{"STATEMENT"}{"END_DATE"}   = $columns[1];
            $data{"STATEMENT"}{"ACCOUNT_ID"} = $columns[2];
            $data{"STATEMENT"}{"SALDO"}      = $columns[3];
            $data{"STATEMENT"}{"WAEHRUNG"}   = $columns[4];
        }

        ### Transactions ###########################
        if ( $line_count > 12 && $line_count <= $#lines ) {
            my $row = $line_count - 13;
            $data{"TRANSACTION"}[$row]{"BUCHUNGSTAG"}      = $columns[0];
            $data{"TRANSACTION"}[$row]{"WERTSTELLUNGSTAG"} = $columns[1];
            $data{"TRANSACTION"}[$row]{"VERWENDUNGSZWECK"} = $columns[2];

            $columns[3] =~ s/\.//;
            $columns[3] =~ s/,/\./;

            $data{"TRANSACTION"}[$row]{"UMSATZ"}           = $columns[3];
            $data{"TRANSACTION"}[$row]{"WAEHRUNG"}         = $columns[4];
            $data{"TRANSACTION"}[$row]{"NOT_YET_FINISHED"} = $columns[5]
              if ( defined( $columns[5] ) && $columns[5] =~ m/^[^\s]$/ig );
        }
    }

    return \%data;
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
						 ACCOUNT => "12345678",
						 PASSWORD => "ROUTE66",
                                                 BLZ => "70090500",
                                                 );
 $account->login();
 print $account->saldo();
 $account->logout();

=head1 DESCRIPTION


This module provides a very limited interface to the webbased online banking
interface of the German "NetBank e.G." operated by Sparda-Datenverarbeitung e.G..
It will only work with German NetBank accounts - e.g. the Austrian Sparda Bank 
Accounts will not work.

It uses OOD and doesn't export anything.

B<WARNING!> This module is neither offical nor is it tested to be 100% save! 
Because of the nature of web-robots, B<everything may break from one day to
the other> when the underlaying web interface changes.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

You can find some basic test scripts for manual testing against the demo-banking
accounts within the directory "test" in the source directry.

=head1 METHODS

=head2 my $account = Finance::Bank::DE::NetBank->new(%values) 

This constructor will set the default values and/or user provided values for
connection and authentication.

    my $account = Finance::Bank::DE::NetBank->new (
                  BASE_URL => "https://www.bankingonline.de/sparda-banking/view/",
                  BLZ => "70090500",        
                  CUSTOMER_ID => "demo",    
                  PASSWORD => "",      
                  ACCOUNT => "2777770",   
                  AGENT_TYPE => "Internet Explorer 6",
	      , @_);

If you don't provide any values the module will automatically use the demo account.

CUSTOMER_ID is your "Kundennummer" and ACCOUNT is the "Kontonummer" 
(if you have only one account you can skip that)


=head2 $account->Version()

returns the module version

=head2 $account->Debug($value)

Set $value to 1 to get some Data::Dumper outputs on STDERR.

=head2 $account->connect()

deprecated. use only $account->login()

=head2 $account->login(%values)

This method will try to log in with the provided authentication details. If
nothing is specified the values from the constructor or the defaults will be used.

    $account->login(ACCOUNT => "1234");

Returns undef on error.

=head2 $account->saldo(%values)

This method will return the current account balance called "Saldo".
The method uses the account number if previously set. 

You can override/set it:

    $account->saldo(ACCOUNT => "5555555");

Returns undef on error.

=head2 $account->statement(%values)

This method will retrieve an account statement (Kontoauszug) and return a hashref.

You can specify the timeframe of the statement by passing different arguments:
The value of TIMEFRAME can be "1" (last day only), "30" (last 30 days only), "alle" (all possible) or "variable" (between
START_DATE and END_DATE only).

    $account->statement(
                                 TIMEFRAME => "variabel",
                                 START_DATE => "10.04.2005",
                                 END_DATE => "02.05.2005",
			    );

Returns undef on error.

=head2 $account->transfer()

Returns undef on error.

=head2 $account->logout()

This method will just log out the website and it only exists to keep the module logic clean ;-)

=head1 USAGE

 use Finance::Bank::DE::NetBank;
 use Data::Dumper;

 my $account = Finance::Bank::DE::NetBank->new(
                                                 BLZ => "70090500",
                                                 CUSTOMER_ID => "xxxxxxx",
                                                 ACCOUNT => "yyyyyyy",
                                                 PASSWORD => "zzzzzz",
                                                 );
 $account->connect();
 $account->login();
 print Dumper($account->statement(
                                 TIMEFRAME => "variabel",
                                 START_DATE => "10.04.2005",
                                 END_DATE => "02.05.2005",
 				 )
             );
 $account->logout();

=head1 BUGS

Please report bugs via 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-DE-NetBank>
or email the author.

=head1 HISTORY

1.02 Wed Dec 14 15:00:00 2005
    - fixed pod errors
    - enhanced pod
        
1.00 Wed Dec 14 00:43:00 2005
    - changed URL to barrier free version (works without that new captcha)
    - replaced buggy html scraping of saldo(). saldo() now uses statement() to retrive the value.
        
0.02 Sun May 04 15:45:00 2003
    - documentation fixes

0.01 Sun May 04 03:00:00 2003
    - original version;

=head1 THANK YOU

 Torsten Mueller (updated URL, saldo() bug reporting)
 Sascha Stock (reported bad example in POD)

=head1 AUTHOR

 Roland Moriz
 rmoriz@cpan.org
 http://www.perl-freelancer.de/

Disclaimer stolen from Simon Cozens' Finance::Bank::LloydsTSB without asking for permission %-)

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Finance::Bank::DE::SpardaBank, WWW::Mechanize, Finance::Bank::LloydsTSB

=cut

