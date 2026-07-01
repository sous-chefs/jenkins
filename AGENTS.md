---
description: chef rspec quickstart
---

<!-- markdownlint-disable MD041 -->
# Chef RSpec quickstart
<!-- markdownlint-enable MD041 -->


## Running the ChefSpec suite

1. Ensure Chef Workstation binaries are available on your PATH. In this repo we do that via `.mise.toml`, which prepends `/opt/chef-workstation/bin`.
1. Activate the mise environment (Fish shell example):

    ```fish
    eval (mise env)
    ```

1. Bootstrap the Chef environment in your shell so `chef exec` uses the embedded ruby:

    ```fish
    eval (chef shell-init fish)
    ```

1. Run the tests:

    - Full suite with embedded Chef ruby:

        ```fish
        chef exec rspec
        ```

    - Direct RSpec (after `chef shell-init`):

        ```fish
        rspec
        ```

1. If you need deterministic ordering, pass a seed:

    ```fish
    chef exec rspec --seed 1234
    ```


## Troubleshooting

- **Missing Chef Workstation install**: Install Chef Workstation (<https://www.chef.io/products/chef-workstation>) so `/opt/chef-workstation` exists.
- **PATH not updated**: Re-run `eval (mise env)` or restart the shell.
- **Chefspec not found**: Ensure you invoked `chef shell-init` before calling `rspec` directly; otherwise use `chef exec rspec`.

## Known Limitations

This cookbook now treats Jenkins as a secured Linux controller with authenticated resource management. The current support and test matrix is based on the official Jenkins installation guidance and current upstream platform lifecycles.

## Upstream constraints

- The official Jenkins package repositories cover Debian/Ubuntu (`apt`) and Red Hat-family distributions (`rpm`). Source: [Installing Jenkins on Linux](https://www.jenkins.io/doc/book/installing/linux/).
- Jenkins requires a supported Java runtime. The current Jenkins install guidance targets Java 17 or Java 21. Source: [Installing Jenkins on Linux](https://www.jenkins.io/doc/book/installing/linux/), [WAR install guide](https://www.jenkins.io/doc/book/installing/war-file/).
- WAR installs remain the fallback for environments that cannot use the official package repos, but this cookbook only integration-tests systemd-based Linux controllers.
- This cookbook keeps the Windows agent resource API, but it does not integration-test a Windows controller.

## Matrix decisions

- `ubuntu-20.04` was dropped from the active Kitchen/CI matrix because its standard support ended in May 2025. Source: [Ubuntu lifecycle](https://endoflife.date/ubuntu).
- `opensuse-leap-15` was dropped from the active matrix because the official Jenkins Linux packaging guidance no longer documents an openSUSE package path and the Leap 15 line is no longer a good baseline for active coverage. Sources: [Installing Jenkins on Linux](https://www.jenkins.io/doc/book/installing/linux/), [openSUSE lifecycle](https://endoflife.date/opensuse).
- Debian 12/13, Ubuntu 22.04/24.04, Amazon Linux 2023, AlmaLinux 8/9/10, CentOS Stream 9/10, Oracle Linux 8/9, Rocky Linux 8/9/10, and Fedora latest remain in the matrix because they are still viable upstream Linux targets for package- or WAR-based Jenkins installs.

## Security expectations

- Jenkins security must stay enabled in integration coverage. The cookbook no longer ships or tests an anonymous-admin bootstrap path.
- Plugin installs against secured controllers rely on authenticated CLI operations and authenticated update-center postback, not on disabling security to make convergence succeed.
