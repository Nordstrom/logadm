logadm_conf_file = '/etc/logadm.conf'

describe file(logadm_conf_file) do
  it { should exist }
  it { should be_file }
  its('mode') { should cmp mode '00644' }
end
