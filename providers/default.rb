#
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

require 'shellwords'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :create do
  if new_resource.manual_command
    cmd = new_resource.manual_command
  else
    cmd = "logadm -w #{new_resource.name} '#{new_resource.path}'"
    args = []
    args << " -a '#{new_resource.postcmd}'" if new_resource.postcmd
    args << " -A '#{new_resource.age}'" if new_resource.age
    args << " -b '#{new_resource.precmd}'" if new_resource.precmd
    args << " -c" if new_resource.copy
    args << " -C #{new_resource.count}" if new_resource.count
    args << " -e #{new_resource.mailaddr}" if new_resource.mailaddr
    args << " -E #{new_resource.expirecmd}" if new_resource.expirecmd
    args << " -f #{new_resource.conffile}" if new_resource.conffile
    args << " -F #{new_resource.timestampfile}" if new_resource.timestampfile
    args << " -g #{new_resource.group}" if new_resource.group
    args << " -l" if new_resource.localtime
    args << " -m #{new_resource.mode}"  if new_resource.mode
    args << " -N " if new_resource.nofileok
    args << " -o #{new_resource.owner}"  if new_resource.owner
    args << " -p #{new_resource.period}"  if new_resource.period
    args << " -p #{new_resource.period}"  if new_resource.period
    args << " -s #{new_resource.size}"  if new_resource.size
    args << " -S #{new_resource.totalsize}"  if new_resource.totalsize
    args << " -t #{new_resource.template}"  if new_resource.template
    args << " -T #{new_resource.logpattern}"  if new_resource.logpattern
    args << " -z #{new_resource.gzip}"  if new_resource.gzip
    cmd  << ' ' + args.join(' ')
  end

  @entry = get_file_entry!
  @file_hash = populate_entry_hash(@entry)
  puts "FILEHASH"
  puts @file_hash
  @new_hash  = populate_entry_hash(cmd)
  puts "NEWHASH"
  puts @new_hash

  Chef::Log.info("logadm command: #{cmd}")

  unless entries_equal?(@file_hash,@new_hash)
    execute "logadm add entry #{new_resource.name}" do
      command cmd
    end
    new_resource.updated_by_last_action(true)
  end
end

action :delete do
  if new_resource.manual_command
    cmd = new_resource.manual_command
  else
    cmd = "logadm -r #{new_resource.name}"
  end

  execute "logadm delete entry #{new_resource.name}" do
    only_if "logadm -V #{new_resource.name}"
    command cmd
  end

  new_resource.updated_by_last_action(true)
end

def load_current_resource
  @current_resource = Chef::Resource::Logadm.new(new_resource.name)
end

# Create a hash of the named entry logadm entry
def get_file_entry!
  if ::File.exists?('/etc/logadm.conf')
    adm_lines = ::File.readlines('/etc/logadm.conf').select { |line| line =~ /^#{new_resource.name}\s/ }
    entry = adm_lines[0]
    puts 'ENTRY'
    puts entry
  else
    entry = ''
  end
  entry
end

def populate_entry_hash(cmd)
  parse_words = {}
  # Types of options.  flags have no parms, other options may have different numbers
  flags = %w(-c -l -N)
  skip = { 'logadm' => 1, '-f' => 2, '-P' => 2, '-w' => 2 }
  # handle -w
  words = Shellwords.split(cmd)
  puts "Shellwords result #{words}"
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
      parse_words[words[i]] = words[i+1]
      i += 2
      next
    end
    parse_words[:path] = words[i]
    i += 1
  end
  puts "PARSEWORDS"
  puts parse_words
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
