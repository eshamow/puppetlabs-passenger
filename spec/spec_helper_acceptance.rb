require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'


unless ENV['RS_PROVISION'] == 'no'
  # This will install the latest available package on el and deb based
  # systems fail on windows and osx, and install via gem on other *nixes
  foss_opts = { :default_action => 'gem_install' }

  if default.is_pe?; then install_pe; else install_puppet( foss_opts ); end

  hosts.each do |host|
    if host['platform'] =~ /debian/
      on host, 'echo \'export PATH=/var/lib/gems/1.8/bin/:${PATH}\' >> ~/.bashrc'
    end

    on host, "mkdir -p #{host['distmoduledir']}"
  end
end

UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|
      copy_module_to(host, :source => proj_root, :module_name => 'profile_passenger')
      on host, puppet('module','install','puppetlabs-stdlib','-v','4.1.0'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-apache','-v','1.1.1'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-concat','-v','1.1.1'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-gcc','-v','0.2.0'), { :acceptable_exit_codes => [0,1] }
      if host['platform'] =~ /ubuntu/ && host['platform'] =~ /10/
        install_package host, 'git-core'
      else
        install_package host, 'git'
      end
      on host, "git clone https://github.com/eshamow/puppetlabs-passenger.git /etc/puppet/modules/passenger"
      on host, "cd /etc/puppet/modules/passenger && git checkout 09d181a2a818b177db106917c87327a0d8593dbb"
      on host, "git clone https://github.com/puppetlabs/puppetlabs-ruby.git /etc/puppet/modules/ruby"
      on host, "cd /etc/puppet/modules/ruby && git checkout 734a33bb7f7670136e77179aafeeebb81d8d14d3"

    end
  end
end
