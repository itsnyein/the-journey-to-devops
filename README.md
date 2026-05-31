# The Journey to DevOps — Packer AMI Build

Builds an AWS AMI on Ubuntu 24.04 with Node.js, PM2, Nginx, AWS CLI v2, and the CodeDeploy agent pre-installed.

---

## Prerequisites

| Tool                                                                              | Install                                          |
| --------------------------------------------------------------------------------- | ------------------------------------------------ |
| [Packer](https://developer.hashicorp.com/packer/install)                          | `brew install packer`                            |
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | see link                                         |
| AWS credentials                                                                   | configured as the `personal` profile (see below) |

**Configure your AWS profile:**

```bash
aws configure --profile personal
```

You will be prompted for your Access Key ID, Secret Access Key, and default region (`ap-southeast-1`).

---

## Step 1 — Install Packer plugins

Run this once after cloning the repo (or after changing `versions.pkr.hcl`):

```bash
packer init .
```

---

## Step 2 — Validate the configuration

Checks HCL syntax and variable references without building anything:

```bash
packer validate .
```

---

## Step 3 — Build the AMI

```bash
packer build .
```

Packer will:

1. Launch a temporary `t3a.micro` EC2 instance in `ap-southeast-1`
2. Run `scripts/run.sh` to install Node.js, PM2, Nginx, AWS CLI, and CodeDeploy agent
3. Stop the instance, snapshot it into an AMI, then terminate the instance

The resulting AMI will appear in your AWS console under **EC2 → AMIs** with the name `the-journey-to-devops-<timestamp>`.

---

## Override variables

You can override any variable at build time with the `-var` flag:

```bash
# Use a different Node.js version
packer build -var="node_version=20" .

# Build in a different region
packer build -var="aws_region=us-east-1" .

# Use a different instance type
packer build -var="instance_type=t3.small" .
```

Or create a `*.pkrvars.hcl` file:

```hcl
# my.pkrvars.hcl
node_version = "20"
aws_region   = "us-east-1"
```

```bash
packer build -var-file="my.pkrvars.hcl" .
```

---

## What gets installed

| Software         | Details                                                             |
| ---------------- | ------------------------------------------------------------------- |
| Node.js          | LTS version set by `node_version` (default: 22) via NodeSource      |
| npm              | Bundled with Node.js                                                |
| PM2              | Global process manager, wired into systemd for auto-start on reboot |
| Nginx            | Reverse proxy, enabled on boot                                      |
| AWS CLI v2       | Latest version                                                      |
| CodeDeploy agent | Enabled and started on boot                                         |

App directory: `/var/www/app` (owned by `ubuntu`)

---

## Variables reference

| Variable           | Default                                                       | Description                       |
| ------------------ | ------------------------------------------------------------- | --------------------------------- |
| `aws_region`       | `ap-southeast-1`                                              | Region to build the AMI in        |
| `aws_profile`      | `personal`                                                    | AWS CLI profile used by Packer    |
| `instance_type`    | `t3a.micro`                                                   | Temporary EC2 instance type       |
| `ami_name_prefix`  | `the-journey-to-devops`                                       | Prefix for the generated AMI name |
| `node_version`     | `22`                                                          | Node.js major version             |
| `ssh_username`     | `ubuntu`                                                      | SSH user for the source AMI       |
| `source_ami_owner` | `099720109477`                                                | Canonical's AWS account ID        |
| `source_ami_name`  | `ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*` | Source AMI name filter            |
