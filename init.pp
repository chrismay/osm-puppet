package{[
 screen,pv,bzip2,subversion,python-cairo-dev,"libcairomm-1.0-dev",
 iotop,unzip,build-essential,libxml2-dev,libgeos-dev,libpq-dev,libbz2-dev,proj,
 "postgresql-8.4-postgis",apache2,
 strace, gdb, git-core,
 ttf-unifont,gdal-bin,libgdal1-dev,libcpanplus-perl]:
ensure=>present}


exec{"/usr/bin/aptitude build-dep mapnik libapache2-mod-python && touch /var/log/build-deps-done":

  creates=>"/var/log/build-deps-done"
}

exec {"/usr/bin/cpanp -i WWW::Mechanize": creates=>"/usr/local/lib/perl/5.10.1/auto/WWW/Mechanize"}
exec {"/usr/bin/cpanp -i HTML::TableParser::Grid": creates=>"/usr/local/lib/perl/5.10.1/auto/HTML/TableParser/Grid"}
exec {"/usr/bin/cpanp -i YAML::Syck": creates=>"/usr/local/lib/perl/5.10.1/auto/YAML/SYCK"}
exec {"/usr/bin/cpanp -i App::Ack": creates=>"/usr/local/lib/perl/5.10.1/auto/App/Ack"}



