#
# Cookbook Name:: delayed_job
# Recipe:: default
#

if node[:dna][:instance_role] == "solo" || (node[:dna][:instance_role] == "util" && node[:dna][:name] !~ /^(mongodb|redis|memcache)/)
  directory "/engineyard/custom" do
    owner "root"
    group "root"
    mode 0755
  end

  template "/engineyard/custom/dj" do
    source "dj.erb"
    owner "root"
    group "root"
    mode 0755
  end

  node[:dna][:applications].each do |app_name,data|
  
    # determine the number of workers to run based on instance size
    if node[:dna][:instance_role] == 'solo'
      worker_count = 1
    else
      case node[:ec2][:instance_type]
      when 'm1.small' then worker_count = 2
      when 'c1.medium' then worker_count = 4
      when 'c1.xlarge' then worker_count = 8
      else 
        worker_count = 2
      end
    end
    
    worker_count.times do |count|
      template "/etc/monit.d/delayed_job#{count+1}.#{app_name}.monitrc" do
        source "dj.monitrc.erb"
        owner "root"
        group "root"
        mode 0644
        variables({
          :app_name => app_name,
          :user => node[:owner_name],
          :worker_name => "#{app_name}_delayed_job#{count+1}",
          :framework_env => node[:dna][:environment][:framework_env]
        })
      end
    end
    
    execute "monit reload" do
       action :run
       epic_fail true
    end
      
  end
end
