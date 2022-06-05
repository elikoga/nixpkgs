{ lib
, mkYarnPackage
, stdenv
, fetchFromGitHub
, makeWrapper
, pkgs
, withPostgresql ? true, postgresql
# , withMysql ? false, mysql # untested
}:

mkYarnPackage rec {
  pname = "umami";
  version = "1.31.0";

  nativeBuildInputs = [
    postgresql
  ];

  src = fetchFromGitHub {
    owner = "mikecao";
    repo = "umami";
    rev = "v${version}";
    hash = "sha256-KPcmMOAiWJaoouqSgm4SrDUKn+nxH+3Ompc2UDuMTqg=";
  };

  yarnFlags = [ "--offline" ];

  preBuild = ''
    initdb -A trust $NIX_BUILD_TOP/postgres >/dev/null
    postgres -D $NIX_BUILD_TOP/postgres -k $NIX_BUILD_TOP >/dev/null &
    export PGHOST=$NIX_BUILD_TOP

    echo "Waiting for PostgreSQL to be ready.."
    while ! psql -l >/dev/null; do
      sleep 0.1
    done

    psql -d postgres -tAc 'CREATE USER "umami"'
    psql -d postgres -tAc 'CREATE DATABASE "umami" OWNER "umami"'
    psql 'umami' -tAc "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    psql 'umami' -tAc "CREATE EXTENSION IF NOT EXISTS hstore"

    # Create a temporary home dir to stop bundler from complaining
    mkdir $NIX_BUILD_TOP/tmp_home
    export HOME=$NIX_BUILD_TOP/tmp_home

    # populate DATABASE_URL
    export DATABASE_URL="postgres://umami:umami@$NIX_BUILD_TOP"
  '';

  buildPhase = ''
    runHook preBuild

    yarn build
  '';

  packageJSON = "${src}/package.json";
  yarnLock = "${src}/yarn.lock";
  yarnNix = ./yarn.nix;

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "simple, easy to use, self-hosted web analytics solution";
    homepage = "https://umami.is/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
