#gem_dependency_packages = [
#  "libxml2",
#  "libxml2-dev",
#  "libxslt-dev",
#  "make"
#]
#
#gem_dependency_packages.each do |pkg|
#  pkg_r = package pkg do
#    action :nothing
#  end
#  pkg_r.run_action(:install)
#end
#
#chef_gem "jenkins_api_client"

cookbook_file "/var/jenkins_test_job.xml" do
  source "test_job.xml"
end

jenkins_job "kannan" do
  config "/var/jenkins_test_job.xml"
  action :create
end

jenkins_job "kannan" do
  action :build
end

ruby_block "sleep 70" do
  block do
    sleep 70
  end
end

jenkins_job "kannan" do
  action :disable
end

jenkins_job "kannan" do
  action :enable
end

jenkins_job "kannan" do
  action :delete
end
