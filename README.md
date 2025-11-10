# Aurora DevOps Platform

This project is my personal end-to-end DevOps platform.
My goal is to build a realistic, professional system that demonstrates how a CI/CD pipeline can create temporary cloud environments, configure them automatically, deploy applications, run checks, collect logs, and destroy everything when the job is done.

Below is the full chronological log of everything I did so far, including the commands I ran and the purpose behind each action.

Project Setup Log (What I did and why)
## 1. Creating the project structure

I created the following folder layout:
```
aurora-devops-platform/
  app/
  ci/
  infra/
      terraform/
      ansible/
  tests/
  tools/
  README.md
```

Why I did this:
I wanted the repository to look like a real internal DevOps platform. Separating app code, infrastructure code, CI logic, tests, and tools makes the project readable and scalable.

## 2. Initializing Git and creating the GitHub repository

Commands I ran:
```
git init
git add .
git commit -m "Initial project structure for Aurora DevOps Platform"
```

Why:
I created version history from the very beginning so every change is tracked and recoverable.

Then I added my GitHub remote and pushed the repo:
```
git remote add origin https://github.com/<username>/aurora-devops-platform.git
git branch -M main
git push -u origin main
```

Why:
I wanted the project to be visible publicly and backed up online. This also makes it LinkedIn-ready.

## 3. Installing Terraform the correct way

I intentionally avoided the snap version because it is sometimes outdated or broken.

Commands:
```
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install terraform
```

Why:
This installs Terraform from HashiCorp’s official repository, ensuring correct provider compatibility.

I verified it with:

`terraform version`

## 4. Installing AWS CLI v2

I downloaded and installed the AWS CLI manually:
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

Why:
I needed the AWS CLI to authenticate Terraform against AWS and manage resources like EC2, S3, and IAM.

## 5. Creating an AWS access key

From the AWS Console → IAM → Users → My user → Security Credentials, I created a new access key specifically for CLI usage.

Why:
Terraform and AWS CLI require programmatic credentials.
AWS only shows the secret key once, so generating a fresh one ensures security and compatibility.

Then I configured the CLI:
```
aws configure
```

I entered:

My Access Key ID  
My Secret Access Key  
Region: eu-central-1  
Output: json  

I confirmed it worked:
```
aws sts get-caller-identity
```

Why:
This proves the CLI is authenticated and has permission to create resources.

## 6. Creating an SSH key pair for EC2 access

Locally I generated a key:
```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aurora_key
```

This produced:

~/.ssh/aurora_key (private key)  
~/.ssh/aurora_key.pub (public key)  

Why:
Terraform needs a public key to associate with the EC2 instance so I can SSH into it.
Ansible will also depend on this for provisioning.

I imported the public key into AWS:
```
aws ec2 import-key-pair \
  --key-name aurora-key \
  --public-key-material fileb://~/.ssh/aurora_key.pub
```

I verified it:
```
aws ec2 describe-key-pairs --key-name aurora-key
```
## 7. Writing Terraform configuration

Inside infra/terraform/ I created Terraform files:

-versions.tf  
-provider.tf  
-variables.tf  
-data.tf  
-main.tf  
-outputs.tf  

Why:
These files define everything required to create the environment: default VPC lookup, subnets, Ubuntu AMI, security group, S3 bucket, random ID, and an EC2 instance.

I ran:
```
terraform init
```

Why:
To download the AWS provider and initialize the working directory.

I then ran:
```
terraform plan -var "instance_key_name=aurora-key"
```

After correcting file names and updating deprecated data sources, Terraform produced a valid plan showing:

+ 1 EC2 instance to be created  
+ 1 S3 bucket  
+ 1 security group  
+ 1 random suffix ID  

This confirms the infrastructure definition is correct.
