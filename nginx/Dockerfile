FROM nginx
COPY ./nginx.conf /etc/nginx/conf.d/proxy.conf
RUN rm /etc/nginx/conf.d/default.conf
# COPY --from=build /app/build /usr/share/nginx/html