set -e

# (HOME=/var/lib/couchdb; cd /tmp && exec gosu couchdb couchdb -b); wait
(HOME=/var/lib/couchdb; cd /tmp && couchdb -b); wait

REGISTRY=http://localhost:5984/registry

cd /usr/src/npm-registry-couchapp
echo "npm-registry-couchapp:couch=$REGISTRY" > .npmrc

# fix for no-auth
sed -i 's/\([[:blank:]]*\)"\${auth\[@\]}" \\/\1${auth[@]} \\/' copy.sh

# attempt to connect to couchdb for 5ish seconds
ATTEMPTS=5
while ! curl -sX GET $REGISTRY > /dev/null; do
  #(( ATTEMPTS-- ))
  ATTEMPTS=`expr $ATTEMPTS - 1`
  if [ $ATTEMPTS -eq 0 ]; then
    echo "$LINENO: Failed to connect to couchdb."
    exit 1
  fi
  sleep 1
done

RESULT=`curl -s -w "%{http_code}" -X PUT $REGISTRY -o /dev/null`
if [ "$RESULT" != "201" ] && [ "$RESULT" != "412" ]; then
  echo "$LINENO: Unable to create database \"registry\". Server responded with status code $RESULT."
  exit 1
fi

export DEPLOY_VERSION=v$NPM_REGISTRY_COUCHAPP_VERSION

npm start
npm run load
NO_PROMPT=1 npm run copy

# (HOME=/var/lib/couchdb; cd /tmp && exec gosu couchdb couchdb -d); wait
(HOME=/var/lib/couchdb; cd /tmp && couchdb -d); wait
