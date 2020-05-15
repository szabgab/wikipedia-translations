FROM perl:5.30.2
RUN cpanm --notest DBI DBD::MariaDB JSON

RUN cpanm --notest LWP::Simple Path::Tiny

WORKDIR /wikipedia
COPY wt.pl languages.json /wikipedia/
