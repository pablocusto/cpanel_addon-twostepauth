package Cpanel::TwoStepAuth::Utils;

use Cpanel::Config                  ();
use Cpanel::Form                    ();
use Cpanel::SafeFile                ();

sub flushConfig {
    my ( $conf, $filename ) = @_;
    my @aconf = map( $_ . '=' . $conf->{$_}, sort keys %{$conf} );
    my $sl = Cpanel::SafeFile::safeopen( \*CONF, '>', $filename ) || return;
    print CONF join( "\n", @aconf );
    print CONF "\n";
    Cpanel::SafeFile::safeclose( \*CONF, $sl );
    return 1;
}

sub load_Config {
    my $file    = shift;
    my $reverse = shift;
    my $conf_ref;
    $conf_ref = {} if !ref $conf_ref;
    $conf_ref = Cpanel::Config::loadConfig( $file, $conf_ref, '\s*[\=]\s*', '^\s*[#]', 0, 0, { 'use_reverse' => $reverse ? 1 : 0, } );
    if ( !defined($conf_ref) ) {
        $conf_ref = {};
    }
    return wantarray ? %{$conf_ref} : $conf_ref;
}

sub dumper {
  my ($logger, $obj, $name) = @_;

  if(ref($obj)) {
    $logger->info("\$" . uc($name) . " = {");
    if(ref($obj) eq 'ARRAY') {
      foreach my $key (@$obj) {
        $logger->info(" '$key',");
      }
    } else {
      foreach my $key (keys %$obj) {
        $logger->info(" '$key' => '".$obj->{$key} ."',");
      }
    }
    $logger->info("};");

  } else {
    $logger->info($obj);
  }
}

1;
