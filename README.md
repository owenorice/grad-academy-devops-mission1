# GTA 6 DevOps Academy — Mission 1: The Vanilla Deployment

> It's launch day for the *Rockstar Social Hub*. Your first job: get it online.

Your **first Terraform project**. You'll use Infrastructure as Code to deploy a
small web app to **Azure** — a single Linux VM running the app in a Docker
container — then tear it all down again with one command.

## What you'll build

```mermaid
flowchart LR
  Internet --> PIP["Public IP"] --> NSG["NSG (firewall)"] --> NIC --> VM
  subgraph VM["Linux VM"]
    APP["Social Hub container :80"]
  end
```

Your instructor has already created one Azure **Resource Group** per group. You
just point Terraform at yours with a single `prefix` variable; everything you
build lands inside it.

## Repository layout

```
app/                  Node.js "Social Hub" web app
  server.js           A few endpoints that return JSON
  package.json
docker/               How the app is packaged into a container
  Dockerfile
  docker-compose.yml
terraform/            Infrastructure as Code (this is the main event)
  main.tf             EVERYTHING: provider, network, VM, variables, outputs
  cloud-init/         Script that boots the VM and starts the container
  terraform.tfvars.example
```

The whole Terraform config is in **one file** — `terraform/main.tf`. Read it top
to bottom; it's commented section by section.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) — then run `az login`
- An SSH key pair — run `ssh-keygen` if `~/.ssh/id_rsa.pub` doesn't exist

## Step by step

### 1. Log in and set your prefix

```bash
az login
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and set **one value** — your group's prefix. It selects
the pre-made resource group (`<prefix>-rg`) and names everything you create:

```hcl
prefix = "vice-city-01"
```

Then initialise Terraform (downloads the Azure provider):

```bash
terraform init
```

### 2. Preview and deploy

```bash
terraform plan     # shows what Terraform WILL create — read it!
terraform apply    # type "yes" to build it for real
```

When it finishes, Terraform prints your outputs:

```bash
terraform output social_hub_url   # -> http://<public-ip>
```

### 3. See it running

Give the VM **2–3 minutes** to install Docker and start the container, then open
the URL in your browser or curl it:

```bash
curl "$(terraform output -raw social_hub_url)/api/v1/profile?id=42"
```

Want to poke around the box? SSH in:

```bash
$(terraform output -raw ssh_command)
sudo docker ps        # see the running container
exit
```

### 4. Clean up

> Always destroy what you built — Azure charges while it runs.

```bash
terraform destroy    # type "yes"; deletes every resource YOU created
```

This removes the VM, network and IP you built but leaves the pre-made resource
group itself in place for the next session.

## Key concepts

- **Infrastructure as Code:** your whole environment is described in text files
  you can version, review, and recreate.
- **State:** Terraform records what it built in `terraform.tfstate` so it knows
  what to change or destroy next time. (Gitignored — it can contain secrets.)
- **Providers & resources:** `main.tf` declares a *provider* (Azure), looks up
  your resource group with a `data` block, then creates *resources* (network,
  VM, …) inside it. `plan` shows the diff; `apply` makes reality match the code.
