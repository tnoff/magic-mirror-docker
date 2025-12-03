# Magic Mirror Docker

Run magic mirror on docker.

Also installs a virtualenv dir with `oci-cli` installed.

## Config File

Assumes you have a `config.js` file mounted in the `/opt/mirror/env` directory.

Will run `envsubst` from `/opt/mirror/env/config.js` to the config.js file used in the config, so you can drop environment variables in the config easily.
