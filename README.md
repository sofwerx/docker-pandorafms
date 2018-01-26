# pandorafms

This is a docker-compose equivalent to the pandora curl install of docker containers, backed by docker volumes, and linked via DNS by docker networking.

# Usage:

    docker-compose up -d

Then open a browser http to port 80 on your docker-engine. If your browser is on the same host as your docker-engine daemon, that would be:

- http://localhost/pandora_console/

