# Hardening the Docker host

In order to satisfy the Docker Security Benchmark, the following measures must be applied at a minimum (starting from a default, non-swarm install of Docker). **Do not forget** to run [docker-bench-security](https://github.com/docker/docker-bench-security) to catch any additional issues.

 * Set the environment variable `DOCKER_CONTENT_TRUST=1` (eg. in .profile or .bashrc)
 * `chmod a+rwx -R logs/ tmp/` (the app container won't work without this!)
 * `chmod a+rw db/schema.rb` (likewise)
 * Make sure that dockerd is launched with the following flags (eg. inspect `service status docker.service` if using systemd): `--icc=false --live-restore --userns-remap=default --userland-proxy=false --no-new-privileges`
