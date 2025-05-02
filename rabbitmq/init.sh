#!/bin/sh

# Ensure the nodename doesn't change, e.g. if docker restarts.
# Important because rabbitmq stores data per node name (or 'IP')
echo 'NODENAME=rabbit@localhost' > /etc/rabbitmq/rabbitmq-env.conf

(rabbitmqctl wait --timeout 60 $RABBITMQ_PID_FILE

for i in "UniversityHelper.UserService","1234" "UniversityHelper.RightsService","1234" "UniversityHelper.CommunityService","1234" "UniversityHelper.AuthService","1234" "UniversityHelper.FeedbackService","1234" "UniversityHelper.MapService","1234"; do 
    IFS=","; 
    set -- $i; 
    # echo $1 and $2; 
    RABBITMQ_USER=$1
    RABBITMQ_PASSWORD=$2

    rabbitmqctl add_user $RABBITMQ_USER $RABBITMQ_PASSWORD 2>/dev/null ; \
    rabbitmqctl set_user_tags $RABBITMQ_USER administrator ; \
    rabbitmqctl set_permissions -p / $RABBITMQ_USER  ".*" ".*" ".*" ; \
    echo "*** User '$RABBITMQ_USER' with password '$RABBITMQ_PASSWORD' completed. ***" ; \
    echo "*** Log in the WebUI at port 15672 (example: http:/localhost:15672) ***"
done)
# for databaseName in "UserService_CBE144F5-AD53-4D0D-B6A1-39133E3F7D2D 1234" "UserService_CBE144F5-0000-0000-0000-39133E3F7D2D 5678"; do
  # do something like: echo $databaseName
# done 

# # Create Rabbitmq user
# (rabbitmqctl wait --timeout 60 $RABBITMQ_PID_FILE ; \
# rabbitmqctl add_user $RABBITMQ_USER $RABBITMQ_PASSWORD 2>/dev/null ; \
# rabbitmqctl set_user_tags $RABBITMQ_USER administrator ; \
# rabbitmqctl set_permissions -p / $RABBITMQ_USER  ".*" ".*" ".*" ; \
# echo "*** User '$RABBITMQ_USER' with password '$RABBITMQ_PASSWORD' completed. ***" ; \
# echo "*** Log in the WebUI at port 15672 (example: http:/localhost:15672) ***") &

# $@ is used to pass arguments to the rabbitmq-server command.
# For example if you use it like this: docker run -d rabbitmq arg1 arg2,
# it will be as you run in the container rabbitmq-server arg1 arg2
rabbitmq-server $@