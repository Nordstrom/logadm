Logadm Cookbook
=================
Provides a `logadm` resource to create/delete cron jobs for log rotation
and management.

Requirements
============

Chef version 0.10.10+.

Platform
--------

* SmartOS (presumably other SunOS)

Resources/Providers
===================

`logadm`
--------

Manage logadm.

### Actions

- :create: create a named log entry
- :delete: delete a named log entry

### Attribute Parameters

- :conf_file: Configuration file to use. 
- :name: name attribute. Name of the log to set logadm rules to manage
- :manual_command: override all settings with one-liner command
- :path: path to log
- :postcmd: Command to run after logrotation
- :age: Delete versions that have not been modified for the time specified.
- :precmd: Command to run before rename a log file.
- :copy: Rotate the log file by copying it and truncating the origin file.
- :count: number of 
- :mailaddr: Send error messages to the mail address.
- :expirecmd: Execute this command to expire a file rather than deleting it.
- :group: Create the empty file using this group
- :localtime: Use local time for timestamps on rotated files
- :mode: Create the empty file using this mode
- :nofileok: No error message if the file doesn't exist
- :owner: Create the empty file using this owner
- :period: time period to rotate logs
- :template: template for naming of logs
- :size: size is number followed by bytes...kilobytes...etc
- :totalsize: Allowed maximum size of all the log filess.
- :logpattern: Pattern for the log files.
- :gzip: specify count of which log to start compressing ( default 1 )

### Providers

- **Chef::Provider::Logadm**: shortcut resource `logadm`


Usage
=====

### Examples

``` ruby
# create a logadm entry
logadm "chef-client" do
  path "/var/log/chef/client.log"
  copy true
  size "1b"
  period "7d"
  action :create  
end

# nginx -C 5 -c -s 100m '/var/log/nginx/{access,error}.log'
logadm "nginx" do
  path "/var/log/nginx/{localhost.access,error}.log"
  copy true
  size "100m"
  count 5
  gzip 1
  action :create	
end
```
