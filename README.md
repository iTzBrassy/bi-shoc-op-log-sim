$ docker-compose up -d
$ docker-compose down

# Grafana server
http://localhost:3000/?orgId=1
# Prometheus server (username=admin, password=admin)
http://localhost:9090/
# pgAdmin (username=shoc@shoc.us, password=JustKeepSwimming)
#   Add server, in connection tab set (host=pg_container, username=shoc, password=JustKeepSwimming)
http://localhost:3031/