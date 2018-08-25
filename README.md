# RTFM blog inrustructure

This repository containes CloudFormation template and Ansible roles for the [RTFM blog](https://rtfm.co.ua/) setup.

You can find post with full decription [here](https://rtfm.co.ua/aws-migraciya-rtfm-3-0-final-cloudformation-i-ansible-roli/) (in Russian for now)

## CloudFormation

[This](https://github.com/setevoy2/rtfm-infrastructure/blob/master/roles/cloudformation/files/rtfm-cf-stack.json) template includes:

* VPC
* PublicSubnet
* Internet Gateway
* EC2 SecurityGroup
* CloudWatchAccessProfile
* Elastic IP
* EC2 instance with two EBS attached

## Ansible

Used to run CloudFormation and [roles](https://github.com/setevoy2/rtfm-infrastructure/tree/master/roles) to install and configure services:

* common (configure EC2 hostname, users etc)
* cloudformation (create or update CloudFormation stack)
* letsencrypt (install client, obtain SSL certificates, add a cronjob for renewal)
* mysql (MariaDB installation, create users/databases etc)
* nginx (install, copy virtual hosts configs etc)
* php-fpm (install, configure FMP-pools)
