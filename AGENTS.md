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
