#!/usr/local/cpanel/3rdparty/bin/perl
use strict;
use Fcntl			();
use YAML::Syck		();


#Set which languages to edit
my @languages_to_edit = ('en');

foreach my $language (@languages_to_edit){
	#Get our list of Trustwave language keys for the language
	my %new_lang_keys = local_lang_keys($language);
	#Get the list of existing local language keys for the language (if it exists)
	if( -e '/usr/local/cpanel/base/frontend/x3/locale/' . $language . '.yaml.local' ){
		my $existing_lang_keys = load_lang_keys($language);
		my %existing_lang_keys = %{$existing_lang_keys};
		foreach my $existing_lang_key ( keys %existing_lang_keys ){
			foreach my $new_lang_key ( keys %new_lang_keys ){
				if( $existing_lang_key eq $new_lang_key ){	#If there is already a lang key named the same as one of our new keys, we give it a new value
					$existing_lang_keys{$existing_lang_key} = $new_lang_keys{$new_lang_key};
					delete($new_lang_keys{$new_lang_key});
				}
			}
		}
		#Add all keys that do not already exist
		%new_lang_keys = (%existing_lang_keys, %new_lang_keys);
		save_lang_keys($language, %new_lang_keys);
	}else{
		save_lang_keys($language, %new_lang_keys);
	}
	
	
	
}

sub load_lang_keys{
	my $language = shift;
	my $config;
	
	if ( sysopen( my $yaml_fh, '/usr/local/cpanel/base/frontend/x3/locale/' . $language . '.yaml.local' , &Fcntl::O_RDONLY ) ) {
	    flock( $yaml_fh, &Fcntl::LOCK_EX );
	    {
	        local $/;				#read until forever -- $/ is usually \n
			my $data = readline($yaml_fh);
			if($data){
	        	$config = YAML::Syck::Load($data);
	    	}
		}
	    flock( $yaml_fh, &Fcntl::LOCK_UN );
	}else{
		print STDERR "Unable to load existing lang keys \n";
	}
	return $config;
}




sub save_lang_keys{
	my ($language, %lang_keys) = @_;
	
	if ( sysopen( my $yaml_fh, '/usr/local/cpanel/base/frontend/x3/locale/' . $language . '.yaml.local' , &Fcntl::O_CREAT | &Fcntl::O_RDWR ) ) {
	    flock( $yaml_fh, &Fcntl::LOCK_EX );
	    {
	        local $/;				#read until forever -- $/ is usually \n
	        my $config = YAML::Syck::Load(readline($yaml_fh));
				
			$config = \%lang_keys;

	        seek($yaml_fh,0,0); #to top of file
	        print {$yaml_fh} YAML::Syck::Dump($config); #write config file
	    }
	    truncate( $yaml_fh, tell($yaml_fh) );  
	    flock( $yaml_fh, &Fcntl::LOCK_UN );
	}else{
		print STDERR "Unable to save new lang keys \n";
	}
}


sub local_lang_keys{
	my $language = shift;
	
	my %en = (
		"TwoStepAuth_legend"		=> "TwoStepAuth Security Policy",
		"TwoStepAuth_enabled" 		=> "Two Step Auth Enabled",
		"TwoStepAuth_disabled"		=> "Two Step Auth Disabled",
		"TwoStepAuth_enable"		=> "Enable",
		"TwoStepAuth_disable"		=> "Disable",
		"TwoStepAuth"			=> "cPanel Two Step Auth",
		"TwoStepAuth_settings"		=> "Two Step Auth Settings",
		"TwoStepAuth_authentication"	=> "Two Step Authentication",
		"TwoStepAuth_is_not_active"	=> "Two Step Authentication is not enabled.",
		"TwoStepAuth_is_not_configured"	=> "Two Step Authentication has not been configured",

	);
	
	
	
	if($language eq 'en'){
		return %en;
	}	
}
