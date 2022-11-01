$ docker-compose up -d
$ docker-compose down
$ docker container stop pg_container grafana && docker container rm pg_container grafana && docker image rm bi-shoc-op-log-sim_postgres:latest && sudo rm -rf postgres/data/ && docker-compose down
$ docker-compose up -d && docker logs -f pg_container

# Grafana server
http://localhost:3000/?orgId=1
# Prometheus server (username=admin, password=admin)
http://localhost:9090/
# pgAdmin (username=shoc@shoc.us, password=JustKeepSwimming)
#   Add server, in connection tab set (host=pg_container, username=shoc, password=JustKeepSwimming)
http://localhost:3031/
# jupyterLab
#   To open jupyter lab for the first time you need to pass a token, you can get it by running the command
#   $ docker logs bi-jupyter-container
http://localhost:8889/