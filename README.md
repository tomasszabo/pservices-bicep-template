# pservices-bicep-template
Bicep template for public PaaS creation.

## Prerequisites
1. Azure CLI installed.
2. Two subscriptions for deployment. One used for HUB resources, second for Spoke resources. Template can be deployed also to 1 subscription, then specify the same subscription ID in `subscriptionXID` parameter in `parameters.json` file.
2. Running deployment script under user with sufficient rights.

## Configuration
To configure deployment, specify mandatory parameters in `parameters.json` file.

## Deploy
To deploy Bicep template, run following command

```zsh
./deploy <region>
```

where `region` should be the same region as parameter `location` in `parameters.json` file.

## License
Distributed under MIT license.