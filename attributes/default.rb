# Copyright (C) 2018 Nordstrom Inc.
#
# All rights reserved - Do Not Redistribute
#

cookbook_name = 'logadm'

default[cookbook_name]['write_conf_file'] = true
default[cookbook_name]['conf_file'] = '/etc/logadm.conf'
default[cookbook_name]['conf_file_template'] = 'logadm.conf.erb'

default[cookbook_name]['enabled_patterns']['smf'] = true
default[cookbook_name]['enabled_patterns']['apache'] = false
default[cookbook_name]['enabled_patterns']['lighttpd'] = false
default[cookbook_name]['enabled_patterns']['nginx'] = false
default[cookbook_name]['enabled_patterns']['mysql'] = false

default[cookbook_name]['patterns']['smf'] = '-C 3 -c -s 1m /var/svc/log/*.log'
default[cookbook_name]['patterns']['apache'] = '-C 5 -c -s 100m /var/log/httpd/*.log'
default[cookbook_name]['patterns']['lighttpd'] =
  "-C 5 -c -s 100m '/var/log/lighttpd/{access,error}.log'"
default[cookbook_name]['patterns']['nginx'] =
  "-C 5 -c -s 100m '/var/log/nginx/{access,error}.log'"
default[cookbook_name]['patterns']['mysql'] =
  "-C 5 -c -s 100m '/var/log/mysql/{error,slowquery}.log'"
