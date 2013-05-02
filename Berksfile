site :opscode

metadata

group :integration do
  cookbook "apt"

  # TODO - find a better way around this nastiness
  test_cookbook_base = (Dir.pwd =~ /.kitchen/) ? "../../.." : "."
  cookbook "jenkins-test",
           path: File.expand_path("#{test_cookbook_base}/test/cookbooks/jenkins-test")
end
