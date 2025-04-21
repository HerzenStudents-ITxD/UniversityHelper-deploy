FROM rabbitmq:3-management
RUN apt-get update
RUN apt-get install -y curl 

COPY rabbitmq.config /etc/rabbitmq/
COPY definitions.json /etc/rabbitmq/
COPY init.sh /init.sh
RUN chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.config /etc/rabbitmq/definitions.json
RUN chmod +x /init.sh
 
ENV RABBITMQ_PID_FILE /var/lib/rabbitmq/mnesia/rabbitmq
EXPOSE 4369 5671 5672 25672 15671 15672

# Define default command
ENTRYPOINT ["/init.sh"]