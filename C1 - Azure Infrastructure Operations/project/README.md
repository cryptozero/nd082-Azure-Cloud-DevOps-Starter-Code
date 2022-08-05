# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

* Login to your Azure account
    ```
    az login
    ```

* Create Azure policy definition to deny deployment of untagged resources from policy folder.
    ```
    az policy definition create --name deny-creation-untagged-resources --display-name "Deny creation of untagged indexed resources" --description "This policy deny the creation of untagged indexed resources" --rules tagging-policy.rules.json --mode Indexed
    ```
* Assign policy to subscription
    ```
    az policy assignment create --name tagging-policy --policy deny-creation-untagged-resources
    ```
* (Optional) Verify the assignment
    ```
    az policy assignment list
    ```
* Create packer image with webserver demo configuration using the template on packer folder

    First authenticate to your account, the template contains enviromental variable definitions to use with Azure credentials.

    Then create the vm image
    ```
    packer build server.json
    ```
    or alternatively if the image is already created
    ```
    packer build -force server.json
    ```
* Create cloud infrastructure using the template in terraform folder

    Set up the deployment variables documented in variables.tf

    Initialize terraform
    ```
    terraform init
    ```
    Visualize the plan for the deployment
    ```
    terraform plan
    ```
    or generate a plan file
    ```
    terraform plan -out solution.plan
    ```
    Apply the changes
    ```
    terraform apply
    ```
    or using the generated plan file
    ```
    terraform apply solution.plan
    ```
* Using the public ip assigned to the load balancer (assigned dynamically
    1. Find the address using az CLI or azure portal)
    2. Check the web servers are running properly with an http client or web browser.

### Output
The web page will show the following message:
```
Hello, World!
```