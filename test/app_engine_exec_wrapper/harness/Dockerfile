FROM app-engine-exec-wrapper
RUN apt-get update -y && \
    apt-get install -y -q --no-install-recommends ruby && \
    rm /buildstep/cloud_sql_proxy
COPY fake_cloud_sql_proxy.rb /buildstep/cloud_sql_proxy
