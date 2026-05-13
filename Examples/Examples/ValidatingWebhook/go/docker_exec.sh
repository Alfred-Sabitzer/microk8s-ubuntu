#!/bin/bash
 docker exec -it validatingwebhook /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/ash || /bin/sh"