# encoding: utf-8
# Copyright (c) 2013 ModCloth, Inc.
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# TODO: Fully implement the -f flag to manage separate logamd conf files.
require 'shellwords'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut
def whyrun_supported?
  true
end

action :create do
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
    args << " -o #{new_resource.owner}"  if new_resource.owner
    args << " -p #{new_resource.period}"  if new_resource.period
    args << " -p #{new_resource.period}"  if new_resource.period
    args << " -s #{new_resource.size}"  if new_resource.size
    args << " -S #{new_resource.totalsize}"  if new_resource.totalsize
    args << " -t #{new_resource.template}"  if new_resource.template
    args << " -T #{new_resource.logpattern}"  if new_resource.logpattern
    args << " -z #{new_resource.gzip}"  if new_resource.gzip && node[:os_version] != '5.9'
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
      new_resource.updated_by_last_action(true)
    end
  end
end

action :delete do
  if new_resource.manual_command
    cmd = new_resource.manual_command
  else
    cmd = "logadm -r #{new_resource.name}"
  end

  @entry = file_entry!
  if @entry
    msg = "logadm delete entry #{new_resource.name}"
    converge_by(msg) do
      Chef::Log.info(msg)
      shell_out!(cmd)
      new_resource.updated_by_last_action(true)
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::Logadm.new(new_resource.name)
end

# Create a hash of the named entry logadm entry
def file_entry!
  # TODO: -f
  if ::File.exists?('/etc/logadm.conf')
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
  flags = %w(-c -l -N)
  skip = { 'logadm' => 1, '-f' => 2, '-P' => 2, '-w' => 2 }
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
