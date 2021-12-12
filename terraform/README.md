# Overview:

This project will create a Jenkins server using Terraform to provision an ec2 instance on AWS and Ansible to then install Java, Python and Jenkins on the new instance.

We assume you have:
    
* AWS account with root/admin authorization

• Terraform 13+

• Ansible 2.6+

• AWS cli with access keys to root/admin account

* jq, the json parser terminal utility

• Linux OS

## Resource Provisioning with Terraform:
We will first create a backend S3 bucket to store the state file and then later provision the ec2.


1. clone this [ repo ](https://github.com/lyanhminh/iac-webserver.git)
```
git clone https://github.com/lyanhminh/iac-webserver.git
```

2. cd into `iac-webserver/terraform/backend`. S3 names are global and you'll have to create a unique name. Change the `bucket = "project1-s3` to something different in `s3.tf` and save the change.

3. Provision the bucket.
```
#in terraform/backend
terraform init
terraform apply
```

4. cd back up into `terraform` above. Edit the `provider.tf` file.
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

5. Create a key pair for ssh access to your instance using the aws cli. In your terminal enter
```
key_response=$(aws ec2 create-key-pair --key-name <keyPairName>)
echo $key-response | jq '.KeyMaterial' | sed 's/\"//g' > ~/.ssh/<keyPairName>.pem
```
where both occurences of `<keyPairName>` should be substituted for any reasonable name of your choosing. This will place your rsa key into `~/.ssh/` as `keyPairName.pem`.

6. cd back up into `terraform` and edit the variable file `variables.auto.tfvars` anywhere there are `XXX`s.
```
project_name = "simplilearn-projec1" //Change to whatever
ami_id = "ami-XXXX"
owner = "XXX" // this number is specific to the chosen AMI above
instance_type = "t2.micro"
key_pair_name = "XXXX" //This should be the same as in step 5. above
vpc_id   = "vpc-XXX" //See the relevant note below
ssh_ip_list = ["XXX.XXX.XXX.XXX/32","XXX.XXX.XXX.XXX/32", ...]
```

Some notes here:

* AMI availability is region specific. Use this [site](https://cloud-images.ubuntu.com/locator/ec2/) to choose an appropriate region and select the desired Ubuntu AMI. Choose an Ubuntu AMI that is versioned 18+ as the ansible playbooks later on will be expecting this when we configure the ec2 instance. Also copy the owner number as that is needed too. If you choose `us-east-1` as your region no change is needed.

* For the vpc, we can just use the default vpc. Enter this in your terminal to find the default vpc id and copy it to the `vpc_id` variable 
```
aws ec2 describe-vpcs --filters Name=isDefault,Values=true | grep VpcId
```

* Enter the IP's you'll use to access the instance from. A google search of `my IP` will return you your IPv4 IP or alternatively enter `ifconfig` in your terminal. Make sure to also include the `/32` at the end of each IP as AWS expects the IP to be in CIDR block format.
