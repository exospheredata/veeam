# Testing

The cookbook secrets_management does not include any executable recipes as it is designed to be an utility cookbook and support other initiatives.  For the purposes of testing and validating this code, we have included a test cookbook with pre-configured recipes.

| **Name** | **Description** |
| ------------- |-------------|
| _Default_ | Roll-up recipe to test all of the functionality of the following recipes - hashivault, chef_vault, data_bag |
| _hashivault_ | Test gathering secrets from Hashicorp Vault environments. |
| _hashivault_with_chef_vault_ | Test gathering secrets from Hashicorp Vault environments by first pulling the information from a ChefVault item. |
| _chef_vault_ | Test gathering secrets from ChefVault bags |
| _data_bag_ | Test gathering secrets from Chef DataBags |

# Hashivault validation

In order to validate the integration with Hashicorp Vault, an existing Hashicorp Vault server must be available and this Test-Kitchen server will need to have access to the same network.

# Test-Kitchen

The test cookbook requires test-kitchen to be installed and that you configure the following environment variables in order to validate recipes.

- ENV['VAULT_TOKEN']
- ENV['VAULT_ADDR']

# General Testing Guidelines
Please refer to
[https://github.com/chef-cookbooks/community_cookbook_documentation/blob/master/TESTING.MD](https://github.com/chef-cookbooks/community_cookbook_documentation/blob/master/TESTING.MD)
