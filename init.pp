class packages{
package{[subversion,autoconf,screen,htop]: ensure=>present}

file{["/home/vagrant/src","/home/vagrant/bin","/home/vagrant/planet"]: ensure=>directory}


package{["postgresql-8.4-postgis", "postgresql-contrib-8.4","postgresql-server-dev-8.4",
"build-essential","libxml2-dev","libtool","libgeos-dev", "libpq-dev", "libbz2-dev", "proj"]: ensure=>present}

package{["libltdl3-dev", "libpng12-dev", "libicu-dev",
"libboost-python1.40-dev" ,"python-cairo-dev", "python-nose",
"libboost1.40-dev" ,"libboost-filesystem1.40-dev",
"libboost-iostreams1.40-dev" ,"libboost-regex1.40-dev", "libboost-thread1.40-dev",
"libboost-program-options1.40-dev" ,
"libfreetype6-dev" ,"libcairo2-dev", "libcairomm-1.0-dev",
"libgeotiff-dev" ,"libtiff4", "libtiff4-dev", "libtiffxx0c2",
"libsigc++-dev" ,"libsigc++0c2", "libsigx-2.0-2", "libsigx-2.0-dev",
"libgdal1-dev" ,"python-gdal",
"imagemagick" ,"ttf-dejavu"
]:ensure=>installed}
}

class osm-build{
exec{"/usr/bin/svn co http://svn.openstreetmap.org/applications/utils/export/osm2pgsql/":
    cwd=>"/home/vagrant/bin",
    creates=>"/home/vagrant/bin/osm2pgsql",
    alias=>"svn-get-osm2pgsql"
}

exec{"/home/vagrant/bin/osm2pgsql/autogen.sh && /home/vagrant/bin/osm2pgsql/configure && /usr/bin/make":
    cwd=>"/home/vagrant/bin/osm2pgsql",
    logoutput=>true,
    require=>Exec["svn-get-osm2pgsql"],
    creates=>"/home/vagrant/bin/osm2pgsql/osm2pgsql",
    alias=>"build-osm2pgsql"
}
}
class mapnik-build{
exec{"/usr/bin/svn co  http://svn.mapnik.org/tags/release-0.7.1/ mapnik":
    cwd=>"/home/vagrant/src",
    creates=>"/home/vagrant/src/mapnik",
    alias=>"svn-get-mapnik"
}
exec{"/usr/bin/python scons/scons.py configure INPUT_PLUGINS=all OPTIMIZATION=3 SYSTEM_FONTS=/usr/share/fonts/truetype/ &&
/usr/bin/python scons/scons.py &&
/usr/bin/python scons/scons.py install &&
/sbin/ldconfig":
    cwd=>"/home/vagrant/src/mapnik",
    alias=>"build-mapnik",
    require=>Exec["svn-get-mapnik"],
    logoutput=>true
    
}
}
class postgres{
    service{"postgresql-8.4": ensure=>running}
    file{"/etc/postgresql/8.4/main/postgresql.conf": source=>"/vagrant/postgresql.conf",
       notify=>Service["postgresql-8.4"]
    }
    exec{"/usr/bin/createuser -s mapnik && /usr/bin/createdb -E UTF8 -O mapnik --template template0 gis && /usr/bin/createlang plpgsql gis && touch /var/lib/postgresql/puppet_made_users":
        creates=>"/var/lib/postgresql/puppet_made_users",
        user=>postgres,
        logoutput=>true,
        alias=>"create-postgis-users"
    }
    exec{"/usr/bin/psql -f /usr/share/postgresql/8.4/contrib/postgis.sql -d gis && touch /var/lib/postgresql/puppet_enabled_gis":
        creates=>"/var/lib/postgresql/puppet_enabled_gis",
        user=>postgres,
        logoutput=>true,
        alias=>"enable-postgis",
        require=>Exec["create-postgis-users"]
    }
    exec{"/bin/echo \"ALTER TABLE geometry_columns OWNER TO mapnik; ALTER TABLE spatial_ref_sys OWNER TO mapnik;\" | /usr/bin/psql -d gis && touch /var/lib/postgresql/puppet_fixed_owners":
        creates=>"/var/lib/postgresql/puppet_fixed_owners",
        user=>postgres,
        logoutput=>true,
        require=>Exec["enable-postgis"]
    }
        
    exec{"/usr/bin/psql -f /usr/share/postgresql/8.4/contrib/_int.sql -d gis && touch /var/lib/postgresql/puppet_enabled_int":
        creates=>"/var/lib/postgresql/puppet_enabled_int",
        user=>postgres,
        logoutput=>true,
        require=>Exec["enable-postgis"]
    }

    exec{"/usr/bin/psql -f /home/vagrant/bin/osm2pgsql/900913.sql -d gis && touch /var/lib/postgresql/puppet_enabled_srid":
        creates=>"/var/lib/postgresql/puppet_enabled_srid",
        user=>postgres,
        logoutput=>true,
        require=>Exec["enable-postgis"],
        alias=>"enable-osm-postgis"
    }
}

class import-osm{
exec{"/home/vagrant/bin/osm2pgsql/osm2pgsql -S default.style --slim -d gis -C 2048 /vagrant/nec-gw-gf-2011.osm.bz2 && touch /var/lib/postgresql/puppet_imported_nec":
    user=>postgres,
    logoutput=>true,
    creates=>"/var/lib/postgresql/puppet_imported_nec",
    require=>[Exec["enable-osm-postgis"],Exec["build-osm2pgsql"]]
}
}


class startup{
        exec{"/usr/bin/apt-get update && touch /etc/apt-updated": creates=>"/etc/apt-updated" }
}
stage { "first": before => Stage[packages] }
stage { "packages": before=>Stage[main]}

class {"startup": stage=>first}
class {"packages": stage=>packages}
include startup
include packages
include osm-build
include postgres
include import-osm
include mapnik-build
