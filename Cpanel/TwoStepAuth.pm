package Cpanel::TwoStepAuth;

use strict;
use Cpanel::SafeFile             ();
use Cpanel::SafeDir              ();
use Cpanel::FileUtils::TouchFile ();
use Cpanel::Logger               ();
use Cpanel::Config               ();
use Cpanel::Locale               ();
use Cpanel::Hostname		();
use Cpanel::Locale ();
use Digest::MD5                qw(md5_hex);
use Cpanel::TwoStepAuth::Utils;
our $VERSION = '1.0';

my $logger = Cpanel::Logger->new();
my $CP_CONF_FILE = '/usr/local/cpanel/base/3rdparty/twostepauth/twostepauth.conf';
my $users_dir = $Cpanel::homedir . '/.twostepauth/';

sub TwoStepAuth_init {
  my $settings_file = $users_dir . 'conf';
  if(!-e $users_dir) {
	Cpanel::SafeDir::safemkdir( $users_dir, '0700' );
  }
  if(!-e $settings_file) {
      my $conf = { 'enabled' => 0, 'salt' => Cpanel::Rand::getranddata(32) };
      Cpanel::TwoStepAuth::Utils::flushConfig($conf, $settings_file);
      chmod 0600, $settings_file;
      my ($login,$pass,$uid,$gid) = getpwnam($Cpanel::user)
	or die "$Cpanel::user not in passwd file";
      chown $uid, $gid, $settings_file;
  }


  return 1;
}

sub TwoStepAuth_switch {
    #if ( !main::hasfeature("ipdeny") ) { return; }

    my $active = _active();

    if($active) {
      _active(0);
      $active = 0;
    } else {
      _active(1);
      $active = 1;
    }

    return;
}


sub TwoStepAuth_show_form {
  my $locale = Cpanel::Locale->get_handle();

  my $active = $locale->maketext('TwoStepAuth_disabled') . "  <input type='submit' name='switch' value='" . $locale->maketext('TwoStepAuth_enable') . "'>";

  if(_active()) {
    $active = $locale->maketext('TwoStepAuth_enabled') . " <input type='submit' name='switch' value='" . $locale->maketext('TwoStepAuth_disable') . "'>";
  }
  
  my $extra = "";

  if (-e $CP_CONF_FILE) {
    my $config = Cpanel::TwoStepAuth::Utils::load_Config($CP_CONF_FILE);

    if (!$config->{'policy'}) {
	print  $locale->maketext('TwoStepAuth_is_not_active');
      return;
    }
  } else {
    return;
  }
  $extra = TwoStepAuth_registration_qr();

  my $form =<<EOF;
<form method="POST">
<h2>$active</h2>
<br>
$extra
EOF
  print $form;
  return;
}

sub TwoStepAuth_active {
  return _active();
}

sub TwoStepAuth_show_help {
my $HTML=<<HTML;
	<div>
	<h2>Help</h2>
	<p><b>Important:</b> Before enabling take note of the one time recover codes, print them off and put them somewhere safe.</p>
	<p>Scan the above QR code with your mobile phone's TOTP (Timed-based One Time Password) application, Google Authenticator is recommended.</p>
	<p>Enable the feature by clicking the button above, your account is now protected.</p>
	<p>When prompted use the code displayed on your mobile phone screen to log into cPanel securely.</p>
	</div>
HTML
print $HTML;
}

sub TwoStepAuth_registration_qr {

      my $config = Cpanel::TwoStepAuth::Utils::load_Config($users_dir . 'conf');
      my $hash = md5_hex($config->{'salt'} . $Cpanel::user);
      my $hostname = Cpanel::Hostname::gethostname();
      my $cmd = "/usr/local/cpanel/base/3rdparty/twostepauth/gauth.php -c=qr -t='cPanel $Cpanel::user $hostname' -p=$hash";
      my $out = `$cmd`;
      print "<img src='$out'>";
      return;
}

sub _active {
  my ($value) = @_;

  my $settings_file = $users_dir . 'conf';

  if (-e $settings_file ) {
    my $conf = Cpanel::TwoStepAuth::Utils::load_Config($settings_file);

    if (defined $value) {
      $conf->{'salt'} = ($conf->{'salt'} ? $conf->{'salt'}:Cpanel::Rand::getranddata(32));
      $conf->{'enabled'} = $value;
      Cpanel::TwoStepAuth::Utils::flushConfig($conf, $settings_file);
    }
    return $conf->{'enabled'};
  } 
  return 0;
}
