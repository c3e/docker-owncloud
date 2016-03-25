docker stop owncloud
docker rm owncloud

docker run -i -t -d --name owncloud -p 3443:443 -v /data/owncloud/owncloud-ssl:/etc/nginx/SSL -v /data/owncloud/owncloud-storage:/var/www/html/owncloud/data -v /data/owncloud/owncloud-config:/var/www/html/owncloud/config -v /data/owncloud/logs:/var/log/nginx --entrypoint 'owncloud-bootstrap' owncloud

##docker run -i -t -d --name owncloud -p 3443:443 -v /data/owncloud/owncloud-ssl:/etc/nginx/SSL -v /data/owncloud/owncloud-storage:/var/www/html/owncloud/data -v /data/owncloud/owncloud-config:/var/www/html/owncloud/config -v /data/owncloud/logs:/var/log/nginx --entrypoint '/bin/bash' owncloud
