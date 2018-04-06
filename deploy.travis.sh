#!/bin/bash
if [[ $TRAVIS_COMMIT_MESSAGE == *"[skip deploy]"* ]]
then
	echo "Skipping deploy stage"
else
	source env.travis.sh
	eval "$(ssh-agent -s)"
	chmod 600 ssh.pem
	ssh-add ssh.pem
	ssh -o StrictHostKeyChecking=no ${SSH_USER}@${SSH_REMOTE} mkdir -p aktnmap
	scp .env ${SSH_USER}@${SSH_REMOTE}:~/aktnmap/.env
	scp docker-compose.yml ${SSH_USER}@${SSH_REMOTE}:~/aktnmap/docker-compose.yml
	scp docker-compose.deploy.yml ${SSH_USER}@${SSH_REMOTE}:~/aktnmap/docker-compose.deploy.yml
	scp app.deploy.sh ${SSH_USER}@${SSH_REMOTE}:~/aktnmap/app.deploy.sh
	scp app.remove.sh ${SSH_USER}@${SSH_REMOTE}:~/aktnmap/app.remove.sh
	ssh ${SSH_USER}@${SSH_REMOTE} "cd aktnmap; chmod u+x ./app.remove.sh; ./app.remove.sh; chmod u+x ./app.deploy.sh; ./app.deploy.sh"
fi

