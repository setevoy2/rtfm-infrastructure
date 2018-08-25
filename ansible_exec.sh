#!/usr/bin/env bash

HELP="\n\t-c: run CloudFormation role (--tags infra) to create a stack
\n\t-a: run all App roles excluding CF (--tags app), to provision an EC2 instance
\n\t-t: tags to apply, enclosed with double quotes and separated by commas, i.e. \"common, web\"
\n\t-S: skip dry-run
\n\t-e: environment to be used in --limit, defaults to \"rtfm-dev\"
\n\t-v: vault-password file, if none -  default ~/Work/RTFM/Bitbucket/rtfm-infrastructure/aws-credenatials/rtfm_ansible_vault_pass
\n\t-r: RSA key to be used, defaults to ~/Work/RTFM/Bitbucket/rtfm-infrastructure/aws-credenatials/rtfm-dev-eu-west-1a.pem
\n"

[[ "$#" -lt 1 ]] && { echo -e $HELP; exit 1 ; }

### set defaults
# -c == infra, -a == app
TAGS=
# ansible_connection default to ssh
CONN="ansible_connection=ssh"
# -S 
SKIP=0
# -e
ENV="rtfm-dev"
# -v
VAULT="/home/setevoy/Work/RTFM/Bitbucket/rtfm-infrastructure/aws-credenatials/rtfm_ansible_vault_pass"
# -r
RSA_KEY="/home/setevoy/Work/RTFM/Bitbucket/rtfm-infrastructure/aws-credenatials/rtfm-dev-eu-west-1a.pem"

while getopts "caSe:v:r:ht:" opt; do
	case $opt in
		c)
			TAGS=infra
            CONN="ansible_connection=local"
			;;
		a)
			TAGS=app
			;;
        t)
            TAGS=$OPTARG
            ;;
        S)
            SKIP=1
            ;;
		e)
			ENV=$OPTARG
			;;
		v) 
			VAULT=$OPTARG
			;;
        r) 
            RSA_KEY=$OPTARG
            ;;
		h)
			echo -e $HELP
			exit 0
			;;
		?)
			echo -e $HELP && exit 1
			;;
 esac
done

echo -e "\nTags: $TAGS\nEnv: $ENV\nVault: $VAULT\nRSA: $RSA_KEY\n"

read -p "Are you sure to proceed? [y/n] " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

dependencies_install () {

	ansible-galaxy install --role-file requirements.yml
}

syntax_check () {

    local tags=$1
    local env=$2
    local vault=$3
	local rsa=$4
    ansible-playbook --private-key $rsa --tags "$1" --limit=$env rtfm.yml --vault-password-file $vault --syntax-check 
}

ansible_check () {

    local tags=$1
    local env=$2
    local vault=$3
	local rsa=$4
	local connection=$5
	local application=$6
    ansible-playbook --private-key $rsa --tags "$1" --limit=$env rtfm.yml --vault-password-file $vault --check --extra-vars "$connection $application"
}

ansible_exec () {

	local tags=$1
	local env=$2
	local vault=$3
	local rsa=$4
	local connection=$5
	local application=$6
	ansible-playbook --private-key $rsa --tags "$1" --limit=$env rtfm.yml --vault-password-file $vault --extra-vars "$connection $application" 
}

# asserts
[[ $TAGS ]] || { echo -e "\nERROR: no TAGS found. Exit."; exit 1; }
[[ $ENV ]] || { echo -e "\nERROR: no ENV found. Exit."; exit 1; }
[[ $VAULT ]] || { echo -e "\nERROR: no VAULT found. Exit."; exit 1; }

echo -e "\nInstalling dependencies...\n"
if dependencies_install; then
	echo -e "\nDone."
else
    echo -e "Something went wrong. Exit."
    exit 1
fi	

echo -e "\nExecuting syntax-check..."
if syntax_check "$TAGS" $ENV $VAULT $RSA_KEY; then
	echo -e "Syntax check passed.\n"
else
	echo -e "Something went wrong. Exit."
	exit 1
fi

if [[ $SKIP == 0 ]]; then
	echo -e "Running dry-run..."
	if ansible_check "$TAGS" $ENV $VAULT $RSA_KEY $CONN $APP;then
    	echo -e "Dry-run check passed.\n"
	else
    	echo -e "Something went wrong. Exit."
	    exit 1
	fi
else
	echo -e "Skipping dry-run.\n"
fi

read -p "Are you sure to proceed? [y/n] " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo -e "Applying roles..."
if ansible_exec "$TAGS" $ENV $VAULT $RSA_KEY $CONN $APP;then
    echo -e "Provisioning done.\n"
else
    echo -e "Something went wrong. Exit."
    exit 1
fi
