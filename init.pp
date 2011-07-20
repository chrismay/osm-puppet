$mapnik_user="hudson"
$mapnik_home_dir="/var/${mapnik_user}"
$osm2pgsql_install_dir="${mapnik_home_dir}/bin/osm2pgsql"
$shared_data_dir="/data"
$config_dir="/data"

class packages{
package{[subversion,autoconf,screen,htop]: ensure=>present}

file{["${mapnik_home_dir}/src","${mapnik_home_dir}/bin","${mapnik_home_dir}/planet"]: 

  ensure=>directory,
  owner=>"${mapnik_user}"
}


package{["postgresql-8.4-postgis", "postgresql-contrib-8.4","postgresql-server-dev-8.4",
"build-essential","libxml2-dev","libtool","libgeos-dev", "libpq-dev", "libbz2-dev", "proj"]: ensure=>present}

package{["mapnik-utils","python-mapnik"]:ensure=>present}

}

class osm-build{
exec{"/usr/bin/svn co http://svn.openstreetmap.org/applications/utils/export/osm2pgsql/":
    cwd=>"${mapnik_home_dir}/bin",
    creates=>"${mapnik_home_dir}/bin/osm2pgsql",
    alias=>"svn-get-osm2pgsql"
}

exec{"${mapnik_home_dir}/bin/osm2pgsql/autogen.sh && ${mapnik_home_dir}/bin/osm2pgsql/configure && /usr/bin/make":
    cwd=>"${mapnik_home_dir}/bin/osm2pgsql",
    logoutput=>true,
    require=>Exec["svn-get-osm2pgsql"],
    creates=>"${mapnik_home_dir}/bin/osm2pgsql/osm2pgsql",
    alias=>"build-osm2pgsql"
}
}
class mapnik-build{
    exec{"/usr/bin/svn co  http://svn.openstreetmap.org/applications/rendering/mapnik":
        cwd=>"${mapnik_home_dir}/bin",
        creates=>"${mapnik_home_dir}/bin/mapnik",
        user=>"${mapnik_user}",
        alias=>"svn-get-mapnik-tools"
    }
    file{"${mapnik_home_dir}/bin/mapnik/world_boundaries": 
      ensure=>"${shared_data_dir}/osm_data/world_boundaries",
      require=>Exec["svn-get-mapnik-tools"]
    }
}
class postgres{
    service{"postgresql": ensure=>running}
    file{"/etc/postgresql/8.4/main/postgresql.conf": source=>"${shared_data_dir}/postgresql.conf",
       notify=>Service["postgresql"]
    }
    exec{"/usr/bin/createuser -s ${mapnik_user} && /usr/bin/createdb -E UTF8 -O ${mapnik_user} --template template0 gis && /usr/bin/createlang plpgsql gis && touch /var/lib/postgresql/puppet_made_users":
        creates=>"/var/lib/postgresql/puppet_made_users",
        user=>postgres,
        logoutput=>true,
        alias=>"create-postgis-users"
    }
    exec{"/usr/bin/psql -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql -d gis && touch /var/lib/postgresql/puppet_enabled_gis":
        creates=>"/var/lib/postgresql/puppet_enabled_gis",
        user=>postgres,
        logoutput=>true,
        alias=>"enable-postgis",
        require=>Exec["create-postgis-users"]
    }
    exec{"/bin/echo \"ALTER TABLE geometry_columns OWNER TO ${mapnik_user}; ALTER TABLE spatial_ref_sys OWNER TO ${mapnik_user};\" | /usr/bin/psql -d gis && touch /var/lib/postgresql/puppet_fixed_owners":
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

    exec{"/usr/bin/psql -f ${mapnik_home_dir}/bin/osm2pgsql/900913.sql -d gis && touch /var/lib/postgresql/puppet_enabled_srid":
        creates=>"/var/lib/postgresql/puppet_enabled_srid",
        user=>postgres,
        logoutput=>true,
        require=>Exec["enable-postgis"],
        alias=>"enable-osm-postgis"
    }
}

class import-osm{
exec{"${mapnik_home_dir}/bin/osm2pgsql/osm2pgsql -S default.style --slim -d gis -C 2048 ${shared_data_dir}/nec-gw-gf-2011.osm.bz2 && touch /var/lib/postgresql/puppet_imported_nec":
    user=>postgres,
    logoutput=>true,
    creates=>"/var/lib/postgresql/puppet_imported_nec",
    require=>[Exec["enable-osm-postgis"],Exec["build-osm2pgsql"]],
    cwd=>"${osm2pgsql_install_dir}"
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
