with import <nixpkgs> {}; {
  LobstersEnv = stdenv.mkDerivation {
    name = "Lobsters";
    buildInputs = [ nodejs mariadb ruby_2_3 zlib openssl
                    sqlite ];
  };
}
