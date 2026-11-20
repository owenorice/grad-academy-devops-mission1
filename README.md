# GTA 6 DevOps Academy — Mission 1: The Vanilla Deployment

> It's launch day for the *Rockstar Social Club*. Your first job: get it online.

Your **first Terraform project**. You'll use Infrastructure as Code to deploy a
small web app to **Azure**, a single Linux VM running the app in a Docker
container - then tear it all down again with one command.

## What you'll build

```mermaid
flowchart LR
  Internet --> PIP["Public IP"] --> NSG["NSG (firewall)"] --> NIC --> VM
  subgraph VM["Linux VM"]
    APP["Flask Social Club :80"]
  end
```

There's already one Azure **Resource Group** per group. You
just point Terraform at yours with a single `prefix` variable; everything you
build will be inside inside it. Think of it as a room with your server inside.

## Repository layout
For this practical, you only need to worry about what's inside `terraform/`
```
app/                  "Social Club" web app (what you deploy)
  app.py              Routes: / (login page), /login, /health
  requirements.txt    Python deps (Flask)
  templates/          index.html — the Rockstar Social Club login UI
  static/             cover-art images
  Dockerfile          Builds the app image
  docker-compose.yml  Runs the container on port 80
  .env                Fake secrets, committed on purpose (Security challenge)
terraform/            Infrastructure as Code (this is the main event)
  main.tf             EVERYTHING: provider, network, VM, variables, outputs
  cloud-init/         Script that boots the VM, clones this repo, starts the app
```

The whole Terraform config is in **one file** - `terraform/main.tf`. Read it top
to bottom; it's commented section by section.

**How the app gets onto the VM:** cloud-init runs on first boot and `git clone`s
this repo, then `docker compose up`s the app from `app/`.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) - then run `az login`
- An SSH key pair - run `ssh-keygen` if `~/.ssh/id_rsa.pub` doesn't exist

## Step by step

Open your termainal

### 1. Log in and set your prefix

```bash
az login
cd terraform
```

Open `terraform/main.tf` and set **one value** — the `prefix` variable's
`default`. It selects the pre-made resource group (`<prefix>-rg`) and names
everything you create:

```hcl
variable "prefix" {
  ...
  default = "vice-city"   # <- change this to your group's prefix
}
```

Then initialise Terraform (downloads the Azure provider, this will create a folder in your repo):

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

Give the VM **2–3 minutes** to install Docker, clone the repo and start the
container, then open the site in your browser:

```bash
terraform output -raw social_hub_url          # open this URL — the login page
curl "$(terraform output -raw social_hub_url)/health"   # -> {"status":"ok"}
```

Want to poke around the box? SSH in:

```bash
$(terraform output -raw ssh_command)
sudo docker ps        # see the running container
exit
```

### 4. Clean up

> Always destroy what you built - Azure charges while it runs.

```bash
terraform destroy    # type "yes"; deletes every resource YOU created
```

This removes the VM, network and IP you built but leaves the pre-made resource
group in.

## Key concepts

- **Infrastructure as Code:** your whole environment is described in text files
  you can version, review, and recreate.
- **State:** Terraform records what it built in `terraform.tfstate` so it knows
  what to change or destroy next time. (Gitignored - it can contain secrets.)
- **Providers & resources:** `main.tf` declares a *provider* (Azure), looks up
  your resource group with a `data` block, then creates *resources* (network,
  VM, …) inside it. `plan` shows the diff; `apply` makes reality match the code.


## Security challenge: the leaked `.env`

`app/.env` holds fake secrets and was committed on purpose. The `Dockerfile`
uses `COPY . .`, so those secrets get **baked into the image**:

```bash
cd app
docker build -t social-club .
docker run --rm social-club cat /app/.env     # prints the secrets — oops
```

Even adding `RUN rm .env` later wouldn't help: the file still lives in an
earlier image layer (see `docker history`). The only real fix is to keep it out
of the build context in the first place.

**Your task:** stop the `.env` reaching the image — add a `.dockerignore` in
`app/` that excludes `.env`, rebuild, and confirm:

```bash
docker run --rm social-club cat /app/.env     # -> No such file or directory
```
