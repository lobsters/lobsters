# In order to run lobsters you'll need:
#   1. To update mysql2 to 0.4.10 in your Gemfile.
#   2. To use nixpkgs > 89bed5b604cd40f135d2f6a17273a2c4a4374609 
#        (see <https://github.com/NixOS/nixpkgs/pull/40007>)
with import <nixpkgs> {}; {
  LobstersEnv = stdenv.mkDerivation {
    name = "Lobsters";
    buildInputs = [ nodejs mariadb ruby_2_3 zlib openssl
                    sqlite ];
  };
}
