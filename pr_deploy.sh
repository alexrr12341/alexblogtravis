 #!/usr/bin/env bash
 if [ “$TRAVIS_PULL_REQUEST” == “false” ]; then
 echo “Not a PR. Skipping surge deployment.”
 exit 0
 fi
 angular build production
 npm i -g surge

 export SURGE_LOGIN=alexrodriguezrojas98@gmail.com
 # Token of a dummy account
 export SURGE_TOKEN=b650e965823fff66ba37382a25920a68

 export DEPLOY_DOMAIN=https://pr-${TRAVIS_PULL_REQUEST}-alexblog.surge.sh
 surge —project ./dist —domain $DEPLOY_DOMAIN;
