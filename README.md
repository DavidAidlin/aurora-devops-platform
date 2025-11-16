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

## 8. Connecting to the EC2 instance with the SSH key

Using the public IP from Terraform, I connected:

`ssh -i ~/.ssh/aurora_key ubuntu@<public_ip>`


Why:
I tested that my key works and that the instance actually exists and is reachable.
This verifies that both Terraform and the AWS network setup (VPC + SG) are correct.


## 9. Installing Ansible (locally on my DevOps workstation)

Before provisioning the machine, I needed Ansible installed:
```
sudo apt update
sudo apt install ansible-core -y
ansible --version
```

Why:
Ansible will remotely configure the EC2 instance.
Terraform handles “create”, Ansible handles “configure”.

## 10. Creating the Ansible inventory and playbook

Inside infra/ansible/ I created:

inventory.ini  
deploy.yaml  


Contents of inventory.ini:
```ini
[webserver]
<public_ip> ansible_ssh_private_key_file=~/.ssh/aurora_key ansible_user=ubuntu
```

Why:
Ansible needs to know which host to manage, which SSH user it should use (ubuntu), and which key file to use.

Then I wrote deploy.yaml with tasks:

-Update apt cache  
-Upgrade installed packages  
-Install Nginx  
-Ensure Nginx is running  
-Deploy a custom /var/www/html/index.html file  

Why:
This simulates a standard provisioning flow:
OS updates → package installation → service enablement → app deployment.


## 11. Running the Ansible playbook

I executed:

`ansible-playbook -i inventory.ini deploy.yaml`


Ansible printed:

`ok=6  changed=4  failed=0`


Why:
This confirmed the machine was successfully configured: Nginx installed, enabled, and serving my custom HTML page.

## 12. Creating IAM resources for GitHub Actions (OIDC authentication)

To allow GitHub Actions to deploy infrastructure into my AWS account without storing long-lived AWS keys, I set up OpenID Connect (OIDC) authentication.

Inside infra/terraform/iam/ I created three Terraform files:

```
oidc.tf → defines the GitHub OIDC provider
github-actions-policy.tf → permissions that GitHub will have
github-actions-role.tf → IAM role GitHub will assume
github-actions-role-attach.tf → attaches the policy to the role
```
Why:
This configuration lets GitHub request a short-lived AWS token and assume a role securely.
No AWS secret keys are stored in GitHub — this is the modern, recommended method.

I applied these changes with:

`terraform apply`


Terraform created:

- the OIDC provider  
- the GitHub Actions role  
- the custom IAM policy  
- the policy–role attachment  

I verified everything exists with:

`terraform state list | grep github`

## 13. Creating an SSH key for GitHub (to enable git push over SSH)

GitHub rejected HTTPS pushes without a Personal Access Token, so I switched the repo to SSH.

I generated a new SSH key:

`ssh-keygen -t ed25519 -f ~/.ssh/aurora_github`


Then I printed it:

`cat ~/.ssh/aurora_github.pub`


I copied the output and added it to GitHub:
Settings → SSH and GPG keys → New SSH Key

After adding it, I confirmed successful authentication:

`ssh -T git@github.com`

## 14. Switching the repository remote to SSH

I updated my local repo to use SSH instead of HTTPS:

`git remote set-url origin git@github.com:DavidAidlin/aurora-devops-platform.git`


I confirmed:

`git remote -v`


Then I pushed normally:

`git push`


This time the push succeeded using SSH.

## 15. Adding the first GitHub Actions workflow (deploy.yaml)

I created the folder:

`mkdir -p .github/workflows`


Inside it, I added deploy.yaml - a full CI/CD workflow that:

checks out the repo

configures AWS via OIDC

installs Terraform

runs terraform init, plan, apply

shows Terraform outputs

Why:
This is the central automation that will create, configure, and manage my cloud environment on every push.
