# PE templates for Terraform with Platform9 provisioner

## Boxes provided
- Centos 7 master with PE latest
- Centos 7 agents (use `export TF_VAR_agents=5` before running `terraform apply`. Default = 1)
- Centos 7 compile masters (use `export TF_VAR_cms=1` before running `terraform apply`. Default = 0)

## Prep
Platform9 provides OS environment variables. They should be exported.

```
 lmacchi@Pulpo 20:19:26 /tmp>  git clone git@github.com:LMacchi/tf_platform9.git
 Cloning into 'tf_platform9'...
 remote: Counting objects: 22, done.
 remote: Compressing objects: 100% (13/13), done.
 remote: Total 22 (delta 8), reused 22 (delta 8), pack-reused 0
 Receiving objects: 100% (22/22), 4.65 KiB | 4.65 MiB/s, done.
 Resolving deltas: 100% (8/8), done.
 ★ lmacchi@Pulpo 20:20:56 /tmp>  cd tf_platform9/
 ★ lmacchi@Pulpo 20:20:58 /tmp/tf_platform9> (master) source ~/platform9/openstack.rc
 Please enter your OpenStack Password:

 ★ lmacchi@Pulpo 20:21:14 /tmp/tf_platform9> (master)
 ★ lmacchi@Pulpo 20:21:14 /tmp/tf_platform9> (master) env | grep OS
 OS_PROJECT_DOMAIN_ID=xxx
 OS_REGION_NAME=xxx
 OS_AUTH_TOKEN=xxx
 OS_IDENTITY_PROVIDER=xxx
 OS_PROJECT_NAME=xxx
 OS_IDENTITY_API_VERSION=xxx
 OS_AUTH_TYPE=xxx
 OS_PROTOCOL=xxx
 OS_AUTH_URL=xxx
 ```

## Variables

- `agents`: Amount of agent nodes to provide. Defaults to `1`.
- `cms`:    Amount of compile master nodes to provide. Default: `0`.
- `domain`: Fully qualified domain. Default: `platform9.puppet.net`.
- `autosign_pwd`: CSR attribute to allow autosigning. Default: `S3cr3tP@ssw0rd!`.
- `console_pwd`: PE Console passwotd for user `admin`. Defaut: `puppetlabs`.
- `r10K_remote`: Control repo url. Only http/https supported. Default: `https://github.com/LMacchi/my-control-repo.git`.
- `ssh_priv_key_path`: Relative path to your private key. Default: `files/lmacchi_private_key.rsa`

## Usage

- Run `terraform init` to initialize your terraform project

```
★ lmacchi@Pulpo 20:21:19 /tmp/tf_platform9> (master) terraform init

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "openstack" (1.6.0)...
- Downloading plugin for provider "template" (1.0.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.openstack: version = "~> 1.6"
* provider.template: version = "~> 1.0"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

- Update master.tf with your specific data, like `key_pair`, `security_groups`, etc.

- Update `templates/custom-pe.conf.tpl` as needed.

```
★ lmacchi@Pulpo 20:23:09 /tmp/tf_platform9> (master) cp ~/.ssh/id_rsa files/lmacchi_private_key.rsa
```

- Ready to terraform!

```
★ lmacchi@Pulpo 20:24:47 /tmp/tf_platform9> (master) terraform apply
data.template_file.master_userdata: Refreshing state...

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

  Terraform will perform the following actions:

  + openstack_compute_floatingip_associate_v2.master

[...]
```

