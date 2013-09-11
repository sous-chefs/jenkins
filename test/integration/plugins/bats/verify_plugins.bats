@test "the git plugin is installed" {
  test -d /var/lib/jenkins/plugins/git.jpi
}

@test "the git-client plugin is installed" {
  test -d /var/lib/jenkins/plugins/git-client.jpi
}
