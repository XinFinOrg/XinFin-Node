
# devnet

## observability

The following components and configuration files live in the repository under the observability/ folder:

- Prometheus — metrics collection
  - configs: observability/prometheus.yml and observability/prometheus/prometheus.yml
- Grafana — dashboards and visualization
  - configs: observability/grafana.yml and observability/grafana/grafana.yml
- Dozzle — lightweight container log viewer
  - configs: observability/dozzle.yaml and observability/dozzle/users.yml

Below are concise instructions to the above files when applying changes.

Access
- Grafana: http://<host>:3000 (port configurable in observability/grafana.yml)
- Prometheus: http://<host>:9090 (port configurable in observability/prometheus.yml)
- Dozzle: http://<host>:8080 (port configurable in observability/dozzle.yaml)

### Grafana admin password
- Recommended: set the admin username/password in the Grafana container environment so the password is applied on container start.
  - Edit observability/grafana.yml and add (or update) the environment entries:
    - GF_SECURITY_ADMIN_USER=<your-admin-user>
    - GF_SECURITY_ADMIN_PASSWORD=<YourStrongPassword>

### Dozzle (add password protection)

Dozzle admin credentials for local UI authentication. Each user has an email, display name, and a bcrypt-hashed password. You can generate the hash using:

```bash
docker run -it --rm amir20/dozzle generate --name xfinadmin --email me@xfin.net --password secret admin
```

Save the file as `monitoring/users.yml`

### Prometheus
- The Prometheus scrape configuration and targets live under observability/prometheus.yml and observability/prometheus/prometheus.yml.
- When you add a new service to devnet, add its scrape job to the Prometheus config and reload Prometheus (or restart the container).
