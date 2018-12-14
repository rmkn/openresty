FROM rmkn/centos7
MAINTAINER rmkn

RUN yum -y install yum-utils
RUN yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
RUN yum -y install openresty

COPY nginx.conf /usr/local/openresty/nginx/conf/
COPY default.conf security.conf /usr/local/openresty/nginx/conf/conf.d/

EXPOSE 80

CMD ["/usr/bin/openresty", "-g", "daemon off;"]
