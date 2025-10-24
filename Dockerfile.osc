FROM grafana/grafana-enterprise

USER root
COPY osc-entrypoint.sh /usr/local/bin/osc-entrypoint.sh
RUN chmod +x /usr/local/bin/osc-entrypoint.sh
USER 472
ENTRYPOINT [ "osc-entrypoint.sh" ]