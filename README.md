# evcc-tesla-proxy

This repo contains a script to build an [EVCC](https://evcc.io) container that uses your own Tesla REST API proxy without sponsorship.

Please see the [EVCC documentation](https://docs.evcc.io/en/docs/installation/docker) for instructions on running the container.

You may wish to review my other repos for complimentary tools for developing an app to integrate with Tesla:
- [tesla-http-proxy](https://github.com/speedst3r/tesla-http-proxy) - Dockerfile to build a container that executes the Tesla REST API proxy
- [teslatoken](https://github.com/speedst3r/teslatoken) - simple Python app to handle redirection to Tesla for user authorisation and code exchange for OAuth tokens

## Installation

1. Add your Tesla application client ID to the shell script in this repository, and set the image name you would like to use for the built container (e.g. if you want to push it to a private repository)
1. Edit the patch file, the patch for vehicle/tesla/controller.go specifies the base domain name for your own Tesla REST API proxy.
1. Run the `build-evcc.sh` script
1. Use the built image in your container hosting solution
