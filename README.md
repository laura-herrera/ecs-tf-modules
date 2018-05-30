Terraform Modules
=================

Terraform modules that can be referenced from external repos to create ECS clusters including all the 
networking, security and high availability surround it.

We are currently using Terraform 0.11.0

Modules
-------

These modules include:

- Networking: Creates a new VPC, public and private subnets, routing tables, security groups, internet gateways, NAT gateways, network ACLs, etc.

- Cluster: All that is related to the ECS cluster itself, like internal and external load balancers, listeners, rules, IAM roles, policies and relevant security groups.

- Service: Creates a new ECS service, with a task definition, target group, log group, ecr repository, IAM roles and policies as needed to access all the service's resources.  It also offers the posibility to create external resources for the service like DB, Cloud Front, S3 storage and a Caching service.

- Lambda: Creates the Lambda Function that will update the Custom Metrics within Cloud Watch to trigger the Auto Scaling rules, and it creates an IAM role for it.  It associates various existing aws policies or and creates an inline policy to ensure access to all services needed.


Apply Change Process
--------------------

Right now the build of infrastructure using Terraform is a manual process.
It goes as follows:

- The Partner's Clusters terraform code is in a separate git repository and use these modules to build its own infrastructure

- When a change happens to any of the Terraform Modules, the process is:

    1. Once the change is merged into the modules' code, you'll need to bring the changes onto
       the Cluster's code that is using these modules.

       ``` terraform get -update ```

    2. Then run a ```terraform plan``` and ```terraform apply``` as per usual.
