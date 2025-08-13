# Configuration File for CFCLI

To configure the CFCLI tool, you need to create a configuration file named `~/.cfcli.yml` in your home directory. This file will contain the default settings and account information required for the tool to function properly.

## Creating the Configuration File

1. Open a terminal window.
2. Use a text editor to create a new file named `.cfcli.yml` in your home directory. For example, you can use `nano`:

    ```sh
    nano ~/.cfcli.yml
    ```

3. Add the following content to the file:

    ```yaml
    defaults:
        account: <account>
    accounts:
        <account>:
            token: <token>
    ```

    - `defaults`: This section specifies the default account to be used by the CFCLI tool.
    - `account`: The name of the default account. In this example, it is set to `inviqa`.
    - `accounts`: This section contains the account information.
    - `account`: The name of the account. You can replace `inviqa` with your desired account name.
    - `token`: The authentication token for the account. Replace `<token>` with your actual token.

Your CFCLI tool is now configured to use the specified account and token by default.

