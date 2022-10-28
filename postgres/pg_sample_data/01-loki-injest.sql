-- Install the dblink exstension (dblink is a module that 
--		supports connections to other PostgreSQL databases 
--		from within a database session.)
CREATE EXTENSION IF NOT EXISTS dblink;
CREATE EXTENSION IF NOT EXISTS plpython3u;
CREATE EXTENSION IF NOT EXISTS pgagent;
CREATE EXTENSION IF NOT EXISTS plpgsql;

-- Create the postgres superuser role incase it doesn't already
--		exist (we don't create it my default, since the default
--		user was named shoc)
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles  -- SELECT list can be empty for this
      WHERE  rolname = 'postgres') THEN

      CREATE ROLE postgres WITH LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION PASSWORD 'JustKeepSwimming!';
   END IF;
END
$do$;


-- Create the test_db database if it doesn't exist
DO
$do$
BEGIN
   IF EXISTS (SELECT FROM pg_database WHERE datname = 'test_db') THEN
      RAISE NOTICE 'Database already exists';  -- optional
   ELSE
      PERFORM dblink_exec('dbname=' || current_database()  -- current db
                        , 'CREATE DATABASE test_db OWNER=''shoc''');
   END IF;
END
$do$;

-- Switch to the test_db database
SET search_path TO test_db;
\connect test_db



CREATE TABLE IF NOT EXISTS public.loki_injest
(
    imported text COLLATE pg_catalog."default"
)
TABLESPACE pg_default;


CREATE TABLE IF NOT EXISTS public.loki_stream
(
    image_name text COLLATE pg_catalog."default" NOT NULL,
    job text COLLATE pg_catalog."default",
    stream text COLLATE pg_catalog."default",
    tag text COLLATE pg_catalog."default",
    container_id text COLLATE pg_catalog."default",
    container_name text COLLATE pg_catalog."default",
    filename text COLLATE pg_catalog."default",
    image_id text COLLATE pg_catalog."default",
    CONSTRAINT loki_stream_pkey PRIMARY KEY (image_name)
)
TABLESPACE pg_default;

CREATE TABLE IF NOT EXISTS public.loki_value
(
    image_name text COLLATE pg_catalog."default",
    "timestamp" bigint,
    "values" text COLLATE pg_catalog."default",
    "jsonValues" jsonb
)
TABLESPACE pg_default;

CREATE EXTENSION IF NOT EXISTS plpython3u;
select * from pg_language;

CREATE OR REPLACE FUNCTION public.py_pgrest(uri text, body text DEFAULT NULL::text, content_type text DEFAULT 'application/json'::text)
 RETURNS text
 LANGUAGE plpython3u
AS $function$
	import urllib
	from urllib import request, parse
	from urllib.request import urlopen
	from urllib.error import HTTPError, URLError
	
	data = parse.urlencode({'query': '{container_name=~"shoc_log_gen_.+"}'}).encode()
	req =  request.Request(uri, data=data) # this will make the method "POST"
	response = None
	
	try:
		response = request.urlopen(req)
	except HTTPError as e:
		return e
	except URLError as e:
		if hasattr(e, 'reason'):
			return e.reason
		elif hasattr(e, 'code'):
			return e.code
		else:
			return e
	else:
		return response.read()
$function$
;

CREATE OR REPLACE FUNCTION loki_inject_new() RETURNS trigger AS $loki_inject_new$
    BEGIN		
		INSERT INTO public.loki_stream(
			image_name, job, stream, tag, container_id, container_name, filename, image_id)
		(SELECT rec->'stream'->'image_name' as image_name,
				rec->'stream'->'job' as job,
				rec->'stream'->'stream' as stream,
				rec->'stream'->'tag' as tag,
				rec->'stream'->'container_id' as container_id,
				rec->'stream'->'container_name' as container_name,
				rec->'stream'->'filename' as filename,
				rec->'stream'->'image_id' as image_id
		FROM (select json_array_elements((regexp_replace(replace(NEW.imported, '''', ''), '\\\\u001b\[\d\dm', '', 'g'))::json->'data'->'result') as rec 
			  ) as loki) ON CONFLICT DO NOTHING;
		
		INSERT INTO public.loki_value(
			image_name, "timestamp", "values")
		(SELECT 	replace(((rec->'stream'->'image_name')::text), '"', '') as image_name,
				--json_array_elements(rec->'values') as values,
				(replace(((json_array_elements(rec->'values')->0)::text), '"', ''))::bigint as time,
				replace(replace(((json_array_elements(rec->'values')->1)::text), '"', ''), '\', '"') as msg
		FROM (select json_array_elements((regexp_replace(replace(NEW.imported, '''', ''), '\\\\u001b\[\d\dm', '', 'g'))::json->'data'->'result') as rec 
			  from loki_injest) as loki) ON CONFLICT DO NOTHING;
		
		
		UPDATE public.loki_value
			SET "jsonValues"=substr(values, POSITION('{' in values), POSITION('}' in values))::json
			WHERE loki_value."jsonValues" is NULL AND POSITION('{' in values) <> 0 AND 
								POSITION('{' in values) < POSITION('}' in values);
		
        RETURN NEW;
    END;
$loki_inject_new$ LANGUAGE plpgsql;


CREATE TRIGGER loki_inject_new BEFORE INSERT ON loki_injest
    FOR EACH ROW EXECUTE FUNCTION loki_inject_new();
