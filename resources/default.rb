# Copyright (C) 2018 Nordstrom Inc.
#
# All rights reserved - Do Not Redistribute
#
# logadm -w /var/squid/logs/cache.log -C 8 -c -p 1d -t '/var/squid/logs/cache.log.$n' -z 1
#
# Example 6 Rotating the apache Error and Access Logs
#
#      The following example rotates the apache error and access logs
#      monthly to filenames based on current year and month. It keeps
#      the 24 most recent copies and tells apache to restart after
#      renaming the logs.
#
#      This command is run once, and since the -w option is specified,
#      an entry is made in /etc/logadm.conf so the apache logs are
#      rotated from now on.
#
#         % logadm -w apache -p 1m -C 24\
#             -t '/var/apache/old-logs/$basename.%Y-%m'\
#             -a '/usr/apache/bin/apachectl graceful'\
#             '/var/apache/logs/*{access,error}_log'
#
#      This example also illustrates that the entry name supplied with
#      the -w option doesn't have to match the log file name. In this
#      example, the entry name is apache and once the line has been run,
#      the entry in /etc/logadm.conf can be forced to run by executing
#      the following command:
#
#        % logadm -p now apache
#
#      Because the expression matching the apache log file names was
#      enclosed in quotes, the expression is stored in /etc/logadm.conf,
#      rather than the list of files that it expands to. This means that
#      each time logadm runs from cron it expands that expression and
#      checks all the log files in the resulting list to see if they
#      need rotating.
#
#      The following command is an example without the quotes around the
#      log name expression. The shell expands the last argument into a
#      list of log files that exist at the time the command is entered,
#      and writes an entry to /etc/logadm.conf that rotates the files.
#
#        logadm -w apache /var/apache/logs/*_log
#

default_action :create

property :conf_file, kind_of: String
property :name, kind_of: String, name_attribute: true # ~FC108
property :manual_command, kind_of: [String, NilClass], default: nil
property :path, kind_of: String
property :postcmd, kind_of: String
property :age, regex: /^[0-9]+[hdwmy]$/
property :precmd, kind_of: String
property :copy, kind_of: [TrueClass, FalseClass], default: true
property :count, kind_of: Integer
property :mailaddr, kind_of: String
property :expirecmd, kind_of: String
property :timestampfile, kind_of: String
property :conffile, kind_of: String
property :group, kind_of: [String, Integer]
property :localtime, kind_of: [TrueClass, FalseClass], default: false
property :mode, regex: /^0?\d{3,4}$/
property :nofileok, kind_of: [TrueClass, FalseClass], default: false
property :owner, kind_of: [String, Integer]
property :period, regex: /^[0-9]+[hdwmy]$/
property :template, kind_of: String
property :size, regex: /^[0-9]+[bkmg]$/
property :totalsize, regex: /^[0-9]+[bkmg]$/
property :logpattern, kind_of: String
property :gzip, kind_of: Integer

# TODO: Fully implement the -f flag to manage separate logamd conf files.
require 'shellwords'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action_class do
  def whyrun_supported?
    true
  end

  # Create a hash of the named entry logadm entry
  def file_entry!
    # TODO: -f
    if ::File.exist?('/etc/logadm.conf')
      adm_lines = ::File.readlines('/etc/logadm.conf').select { |line| line =~ /^#{new_resource.name}\s/ }
      entry = adm_lines[0]
    else
      entry = ''
    end
    entry
  end

  def populate_entry_hash(cmd)
    parse_words = {}
    # Types of options.  flags have no parms, other options may have different numbers of tokens.
    flags = %w[-gc -l -N]
    skip = { :logadm => 1, '-f' => 2, '-P' => 2, '-w' => 2 }
    words = cmd ? Shellwords.split(cmd) : {}
    i = 0
    while i < words.count
      if skip[words[i]]
        i += skip[words[i]]
        next
      end
      if flags.include?(words[i])
        parse_words[words[i]] = true
        i += 1
        next
      end
      if words[i] =~ /^-/
        parse_words[words[i]] = words[i + 1]
        i += 2
        next
      end
      parse_words[:path] = words[i]
      i += 1
    end
    parse_words
  end

  # Compare two hashes
  def entries_equal?(base, new)
    base.each do |parm, value|
      next if parm == '-P'
      return false unless value == new[parm]
    end
    new.each do |parm, value|
      next if parm == '-P'
      return false unless value == base[parm]
    end
    true
  end
end

action :create do
  use_inline_resources
  if new_resource.manual_command
    cmd = new_resource.manual_command
  else
    cmd = "logadm -w #{new_resource.name} '#{new_resource.path}'"
    args = []
    args << " -a '#{new_resource.postcmd}'" if new_resource.postcmd
    args << " -A '#{new_resource.age}'" if new_resource.age
    args << " -b '#{new_resource.precmd}'" if new_resource.precmd
    args << ' -c' if new_resource.copy
    args << " -C #{new_resource.count}" if new_resource.count
    args << " -e #{new_resource.mailaddr}" if new_resource.mailaddr
    args << " -E #{new_resource.expirecmd}" if new_resource.expirecmd
    args << " -f #{new_resource.conffile}" if new_resource.conffile
    args << " -F #{new_resource.timestampfile}" if new_resource.timestampfile
    args << " -g #{new_resource.group}" if new_resource.group
    args << ' -l' if new_resource.localtime
    args << " -m #{new_resource.mode}"  if new_resource.mode
    args << ' -N ' if new_resource.nofileok
    args << " -o #{new_resource.owner}" if new_resource.owner
    args << " -p #{new_resource.period}"  if new_resource.period
    args << " -p #{new_resource.period}"  if new_resource.period
    args << " -s #{new_resource.size}" if new_resource.size
    args << " -S #{new_resource.totalsize}" if new_resource.totalsize
    args << " -t #{new_resource.template}" if new_resource.template
    args << " -T #{new_resource.logpattern}" if new_resource.logpattern
    args << " -z #{new_resource.gzip}" if new_resource.gzip && node['os_version'] != '5.9'
    cmd  << ' ' + args.join(' ')
  end

  @entry = file_entry!
  @file_hash = populate_entry_hash(@entry)
  @new_hash  = populate_entry_hash(cmd)

  Chef::Log.debug("logadm command: #{cmd} existing #{@file_hash} new #{@new_hash}")

  unless entries_equal?(@file_hash, @new_hash)
    msg = "logadm add entry. command: #{cmd}"
    converge_by(msg) do
      Chef::Log.info(msg)
      shell_out!(cmd)
    end
  end
end

action :delete do
  use_inline_resources
  cmd = if new_resource.manual_command
          new_resource.manual_command
        else
          "logadm -r #{new_resource.name}"
        end

  @entry = file_entry!
  if @entry
    msg = "logadm delete entry #{new_resource.name}"
    converge_by(msg) do
      Chef::Log.info(msg)
      shell_out!(cmd)
    end
  end
end
