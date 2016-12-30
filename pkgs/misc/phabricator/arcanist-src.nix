{ stdenv, fetchgit, php, bash, ...  }:

stdenv.mkDerivation rec {
  version = "2016-12-24";
  name = "arcanist-src-${version}";

  src = fetchgit {
      url = git://github.com/facebook/arcanist.git;
      branchName = "stable";
      rev = "e17fe43ca3fe6dc6dd0b5ce056f56310ea1d3d51";
      sha256 = "13kpsslcwk52h9l0v1zahvskyabzzyiq549l976k880c3khc09a6";
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
