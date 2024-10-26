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
Step 1: Create Policy
From Aruze Portal definition policy using policy rule is provided (policy-rule.json)

Step 2: Register app and get client_id, client_secret
az ad sp create-for-rbac --name "name" --role "Contributor" --scopes "/subscriptions/{subscriptions_id}"


Step 3: Create image by Packer
1. Define server.json packer template
2. variabales: Use a file or use environment variables to set variables (client_id, client_secret take from step 2)
3. Build packer image by running packer build server.json (if uing Azure poral Bash please upload file before)

Step 4: Deploy Server by Terraform
1. Define Terraform templates (main.tf and vars.tf)
2. Execute terraform init
3. Open vars.tf file and change the information as your needs
 - prefix: prefix name of all components created.
 - location:Choose a location based on your needs to save costs. This location applies to all components.
 - admin_username and admin_password: The username and password is the credential of all virtual machines created
 - VMnum: Number of VM resources to be created behind the load balancer.

4. Update image in the main.tf file(Image is created form step 2)
4. Execute terraform plan -out solution.plan. It will ask your variables
5. Execute terraform applly "solution.plan"
6. Open browser and access to the Azure Web Server by load balancer public IP adress (you can take from Portal or the terraform apply output)
7. Execute terraform destroy if needs

### Output
1: Check policy is created
- Execute az policy assignment list
- result will be list as my capture (Capture folder: 1 - Policy-result.PNG)

2: Check image is created
- Execute az image list
- result will be list as my capture (Capture folder: 3 - Image-result.PNG)

3, Check server is deployed
- After you run terraform apply "solution.plan" , you can go to Azure Portal to check (Capture folder)