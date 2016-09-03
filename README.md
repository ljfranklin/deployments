## No Snowflakes ~~❄~~!

A place to store reproducible deployment configs.

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

**Generate self-signed vault cert:**

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 30 -nodes -subj "/C=US/ST=CA/O=YOUR_NAME/CN=YOUR_DOMAIN"
```
