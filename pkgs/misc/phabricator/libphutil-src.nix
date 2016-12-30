{ stdenv, fetchgit, php, bash, ...  }:

stdenv.mkDerivation rec {
  version = "2016-12-24";
  name = "libphutil-src-${version}";

  src = fetchgit {
      url = git://github.com/facebook/libphutil.git;
      branchName = "stable";
      rev = "0ae0cc00acb1413c22bfe3384fd6086ade4cc206";
      sha256 = "07fnvxc0j40lyfznk04mcyn2sxa21zwbzcgs0hjnmlc3glp7llxr";
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
