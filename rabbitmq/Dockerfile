FROM rabbitmq:3-management
RUN apt-get update
RUN apt-get install -y curl 


ADD rabbitmq.config /etc/rabbitmq/
ADD definitions.json /etc/rabbitmq/
RUN chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.config /etc/rabbitmq/definitions.json

# ENV RABBITMQ_PID_FILE /var/lib/rabbitmq/mnesia/rabbitmq

# ADD init.sh /init.sh
# RUN chmod +x /init.sh
# EXPOSE 15672
EXPOSE 4369 5671 5672 25672 15671 15672

# Define default command
# ENTRYPOINT ["/init.sh"]
ENTRYPOINT [ "rabbitmq-server" ]