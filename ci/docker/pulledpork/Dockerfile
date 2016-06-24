FROM perl:latest

WORKDIR /opt

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm LWP::UserAgent Crypt::SSLeay

ADD pulledpork-0.7.0.tar.gz /opt/
