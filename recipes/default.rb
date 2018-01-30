# Cookbook Name:: logadm
# Recipe:: default
#
# Copyright (C) 2018 Nordstrom Inc.
#
# All rights reserved - Do Not Redistribute
#

template node['logadm']['conf_file'] do
  source node['logadm']['conf_file_template']
  mode 0o644
  only_if { node['logadm']['write_conf_file'] }
end
