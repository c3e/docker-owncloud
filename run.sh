docker run -i -t --name owncloud -p 80:80 -p 443:443 -v /data/owncloud-storage:/var/www/html/owncloud/data -v /data/owncloud:/var/www/html/owncloud/config owncloud
