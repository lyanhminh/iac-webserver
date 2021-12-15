# Overview:

This project will create a Jenkins server using Terraform to provision an ec2 instance on AWS and Ansible to then install Java, Python and Jenkins on the new instance.

We assume you have:
    
* AWS account with root/admin authorization

*  Terraform 13+

* Ansible 2.9+

* AWS cli with access keys to root account or admin user priveleges

* jq, the json parser terminal utility

* cLinux OS

## Resource Provisioning with Terraform:

We will first create a backend S3 bucket to store the state file and then later provision the ec2.

```
├── backend
│   ├── s3.tf
│   ├── terraform.tfstate
│   └── variables.auto.tfvars
├── ec2.tf
├── main.tf
├── provider.tf
├── sg.tf
├── variables.auto.tfvars
```
* `backend/s3.tf` defines our S3 backend
*  `./ec2.tf` defines our instance server
*   `./sg.tf` defines our security group for the instance allowing for ssh access and port 8080 access to hit the Jenkins service
*   `./provider.tf` indicates to Terraform we are using an S3 bucket backend as opposed to a local statefile
*    `./main.tf` declares our variables
*    `./variables.auto.tfvars` contain the variable definitions that `./main.tf` declares

### Steps

1\. clone this repo
```
git clone https://github.com/lyanhminh/iac-webserver.git
```
2\. cd into `iac-webserver/terraform/backend`. S3 names are global and you'll have to create a unique name. Change the `bucket = "project1-s3` to something different in `s3.tf` and save the change.

3\. Provision the bucket.
```
#in terraform/backend
terraform init
terraform apply
```

4\. cd back up into `terraform` above. Edit the `provider.tf` file.
```
provider "aws" {
  region = "us-east-1" // Change to match your AWS cli configuration. Run 'aws config' and enter through each parameter to see what region it's set to
}

 terraform {
  backend "s3" {
    bucket = "projec1-s3" //This needs to be the same name as the backend bucket just created in step 2.
    key    = "terraform.tfstate"
    region = "us-east-1" // Match the region above
  }
}
```
Unfortunately, backend configuration files do not admit variables so there is a bit of unnecessary copy/pasting within and across files.

5\. Create a key pair for ssh access to your instance using the aws cli. In your terminal enter
```
key_response=$(aws ec2 create-key-pair --key-name <keyPairName>)
echo $key-response | jq '.KeyMaterial' | sed 's/\"//g' > ~/.ssh/<keyPairName>.pem
```
where both occurences of `<keyPairName>` should be substituted for any reasonable name of your choosing. This will place your rsa key into `~/.ssh/` as `keyPairName.pem`.

6\. cd back up into `terraform` and edit the variable file `variables.template` anywhere there are `XXX`s.
```
project_name = "simplilearn-projec1" //Change to whatever
ami_id = "ami-XXXX"
owner = "XXX" // this number is specific to the chosen AMI above
instance_type = "t2.micro"
key_pair_name = "XXXX" //This should be the same as in step 5. above
vpc_id   = "vpc-XXX" //See the relevant note below
ssh_ip_list = ["XXX.XXX.XXX.XXX/32","XXX.XXX.XXX.XXX/32", ...]
```

Save your edits and rename the file to `variables.auto.tfvars`. The `variables` portion is not so important other than it gives the reader context to what the file does. However, having the `auto.tfvars` suffix is necessary as it tells Terraform to use this file to find the variable definitions.

Some additional notes here:

* AMI availability is region specific. Use this [site](https://cloud-images.ubuntu.com/locator/ec2/) to choose an appropriate region and select the desired Ubuntu AMI. Choose an Ubuntu AMI that is versioned 18+ as the ansible playbooks later on will be expecting this when we configure the ec2 instance. Also we'll need the owner id in the line below. To get this id enter into your terminal: 

      aws ec2 describe-images --image-ids <ami-XXX> | grep Owner
  If you choose `us-east-1` as your region, no change is needed.

* For the vpc, we use the default vpc. Enter this in your terminal to find the default vpc id and copy value outputted to the `vpc_id` variable 

      aws ec2 describe-vpcs --filters Name=isDefault,Values=true | grep VpcId

* Enter the IP's you'll use to access the instance from. A google search of `my IP` will return you your IPv4 or alternatively enter `ifconfig` in your terminal. Make sure to also include the `/32` at the end of each IP as AWS expects the IP to be in CIDR block format.

7\. Initialize and provision :
```
#in terraform/
terraform init
terraform apply --auto-approve
```

Succesful apply will create an ec2 instance. You should be able to log into the AWS console and see your instance launched under the EC2 service.

Note the `public_ip` value outputted in the terminal at the end of the provisioning process. This will be needed in the configuration steps with Ansible. 

## Configuring EC2 with Ansible

Now we'll configure the newly provisioned ec2 with Ansible to install Java11, Python3 and Jenkins. We use a roles based approach requiring a specific directory structure. 

```
├── configure.sh
├── inventory
├── old_ip.txt
├── playbook.yml
└── roles/
    ├── ansible-role-jenkins
    └── ...
    ├── java
    └── ...
    ├── python
    └──  vars/main.yml
    └──  tasks/main.yml
```
* `inventory` specifies the hosts which we want Ansible to configure
*  `playbook.yml` runs the roles we define
*  `configure.sh` is a wrapper for `playbook.yml`. More is said about it below
*  `old_ip.txt` is a dependency of `configure.sh`. It basically stores the ip of the current instance.
*  for each role, there is defined at minimum a `tasks/` and `vars/` directory. 

As Jenkins has a more complicated setup with its many options, plugins and authentication, we use the role provided [here](https://github.com/geerlingguy/ansible-role-jenkins/tree/master/tasks)

### Steps

1\. There is defined a bash script wrapper to update the inventory file and your ssh agent to the new instance IP. To set this up, cd into `ansible/` do the following in the terminal:

```
# if you haven't already made a ssh agent config file
touch ~/.ssh/config

cat << EOF >> ~/.ssh/config
Host null
IdentityFile ~/.ssh/<keyPairName>.pem
User ubuntu
EOF

echo "null" > old_ip.txt
chmod +x configure.sh
```
The `<keyPairName>` is the string you used in the creating a key pair step above (5).


Now, should you destroy your ec2 instance and provision a new one having a new IP, running the `configure.sh` ansible playbook wrapper will update the inventory and ssh agent to the new instance IP.

2\. At this point, `playbook.yml` can run all three roles to install Python, Java and Jenkins. But you might want to first configure Jenkins. For example, try changing the admin and admin password strings. To do this edit the `main.yml` file in the `default/` or add some plugins:
```
22 jenkins_plugins: 
23	  - blueocean
24	  - git
25	  - docker-workflow
26	  - docker-plugin
27	#  - name: influxdb
28	#    version: "1.12.1"
29	
30	jenkins_plugins_state: present
31	jenkins_plugin_updates_expiration: 86400
32	jenkins_plugin_timeout: 30
33	jenkins_plugins_install_dependencies: true
34	jenkins_updates_url: "https://updates.jenkins.io"
36	jenkins_admin_username: admin
37	jenkins_admin_password: admin
```

3\. To configure the instance, run the playbook by issuing `./configure.sh` from the `ansible/` directory.

4\. Navigate to the Jenkins server at <instance_ip>:8080 and login using the credentials defined in the `defaults/main.yml` file.

![](screenshots/jenkins-login)

## Next Steps

Ideas for next steps would be:

* Use a secrets manager. Our Jenkins server configuration should not have such secrets in plain text. Consider using Ansible Vault or AWS secrets manager.
* Configure Jenkins secrets like for github or docker access
* Use that server and run a pipeline
* Alternatively containerize Jenkins in a Docker container and run the container on the instance

