use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Finance::Bank::DE::NetBank',
    VERSION_FROM => 'lib/Finance/Bank/DE/NetBank.pm', # finds $VERSION
    ABSTRACT     => 'Check your NetBank Bank Accounts with Perl',
  
    PREREQ_PM    => {	
	"Finance::Bank::DE::SpardaBank" => "0.03",
	"WWW::Mechanize" => "0.39",
	"Class::Accessor" => 0,
	"HTML::TreeBuilder" => 0,
	"Text::CSV_XS" => 0,
	"Encode" => 0,
	"base" => 0,
	
    },	      

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Finance/Bank/DE/NetBank.pm', # retrieve abstract from module
       AUTHOR        => 'Roland Moriz (rmoriz@cpan.org)') : ()),
	      

);
