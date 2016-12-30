{ stdenv, fetchgit, php, bash, ... }:

stdenv.mkDerivation rec {
  name = "phabricator-src-${version}";
  version = "2016-12-24";

  src = fetchgit {
      url = git://github.com/phacility/phabricator.git;
      branchName = "stable";
      rev = "1cd64f9975d66a5fff516cd064cd076b0eb7b07f";
      sha256 = "1lpgw6qda435i3z5f5p40r82gdk2lv78m0ypv2cfjqy2dac73m1f";
  };

  buildCommand = ''
    cp -R ${src} $out
    chmod u+w -R $out
    patchShebangs $out
  '';

  buildInputs = [ php bash ];

  meta = {
    platforms = stdenv.lib.platforms.unix;
  };
}
