## No Snowflakes ~~❄~~!

A place to store reproducible deployment configs.

#### Director setup

**Login to GCP:**
```bash
export GCE_PROJECT_ID=<YOUR_PROJECT_ID>
gcloud init
gcloud iam service-accounts create terraform-bosh
gcloud projects add-iam-policy-binding ${GCE_PROJECT_ID} \
  --member serviceAccount:terraform-bosh@${GCE_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/editor
gcloud iam service-accounts keys create ./tmp/terraform-bosh.key.json \
  --iam-account terraform-bosh@${GCE_PROJECT_ID}.iam.gserviceaccount.com
export GOOGLE_CREDENTIALS=$(cat ./tmp/terraform-bosh.key.json)
```

**Add SSH key:**

```bash
ssh-keygen -t rsa -b 4096 -C "<YOUR_EMAIL>" -N "" -f ./tmp/vcap.pem
mv ./tmp/vcap.pem.pub ./tmp/vcap.pub
```

Manually add a public wide SSH key with username `vcap`: https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#project-wide

**Terraform environment:**

```bash
terraform apply -var projectid=${GCE_PROJECT_ID}
```

**Generate an SSL cert:**

Self-signed:
```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 30 -nodes -subj "/C=US/ST=CA/O=YOUR_NAME/CN=YOUR_BOSH_DOMAIN"
```

OR

Let's Encrypt via CloudFlare:
```bash
go get -u github.com/xenolf/lego
CLOUDFLARE_API_KEY=<YOUR_API_KEY> CLOUDFLARE_EMAIL=<YOUR_EMAIL> lego --accept-tos --email="<YOUR_EMAIL>" --domains="<YOUR_BOSH_DOMAIN>" --dns="cloudflare" run
```

**Deploy director:**

```bash
bosh create-env ./bosh/director.yml -l ./tmp/bosh-director-creds.yml
bosh upload-cloud-config ./bosh/cloud-config.yml
bosh upload-stemcell https://storage.googleapis.com/bosh-cpi-artifacts/light-bosh-stemcell-3262.12-google-kvm-ubuntu-trusty-go_agent.tgz
```

#### Concourse Setup

**Setup GitHub OAuth:**

http://concourse.ci/teams.html#github-auth

**BOSH deploy:**

```bash
bosh upload-release http://bosh.io/d/github.com/concourse/concourse
bosh upload-release http://bosh.io/d/github.com/cloudfoundry/garden-runc-release
bosh deploy -d concourse -l ./tmp/concourse-creds.yml ./concourse/concourse.yml
```

#### Vault Setup

**Generate consul certs:**

```bash
wget https://raw.githubusercontent.com/cloudfoundry-incubator/consul-release/master/scripts/generate-certs
chmod +x ./generate-certs
./generate-certs
```

**Generate consul encryption key:**

```bash
brew install consul
consul keygen
```
