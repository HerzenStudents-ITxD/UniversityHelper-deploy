FROM rabbitmq:3-management
RUN apt-get update
RUN apt-get install -y curl 

# Create necessary directories
RUN mkdir -p /etc/rabbitmq

# Copy configuration files
COPY rabbitmq.config /etc/rabbitmq/rabbitmq.config
COPY definitions.json /etc/rabbitmq/definitions.json
COPY init.sh /init.sh

# Set permissions
RUN chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.config /etc/rabbitmq/definitions.json
RUN chmod +x /init.sh
 
ENV RABBITMQ_PID_FILE=/var/lib/rabbitmq/mnesia/rabbitmq
EXPOSE 4369 5671 5672 25672 15671 15672

# Define default command
ENTRYPOINT ["/init.sh"]