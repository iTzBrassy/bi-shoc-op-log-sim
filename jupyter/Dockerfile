# Use the jupyter datascience-notebook
FROM jupyter/datascience-notebook

# Switch to root user
RUN whoami
USER root

# Add the libpq-dev library
RUN apt-get update && apt-get install --assume-yes libpq-dev

# Switch back to jovyan
USER jovyan

# Install the psycopg2 library
RUN pip install psycopg2