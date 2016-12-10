{ stdenv, intltool, fetchurl, webkitgtk, webkitgtk24x
, pkgconfig, gtk3, glib, libsoup, gnome3, makeWrapper, sqlite, gdk_pixbuf, nss, nspr }:

stdenv.mkDerivation rec {
  name = "evolution-rss-0.3.95" ;

  src = fetchurl {
    url = "http://gnome.eu.org/${name}.tar.xz";
    sha256 = "3fb28eec798b3192ae155b92d17b852264d0e5e35185a4f0c8f526a8d587eb1f";
  };

  doCheck = true;

  propagatedUserEnvPkgs = [ gnome3.gnome_themes_standard ];

  propagatedBuildInputs = [ gnome3.gtkhtml ];

  buildInputs = [ pkgconfig glib intltool gnome3.evolution libsoup
                  gtk3 gnome3.evolution_data_server sqlite webkitgtk24x
                  gnome3.gtkhtml gnome3.gsettings_desktop_schemas makeWrapper ];

  configureFlags = [ "--with-primary-render=webkit" ];

  makeFlags = [ "PLUGIN_INSTALL_DIR=$$out/lib/evolution/plugins"
    "moduledir=$$out/lib/evolution/modules"
    "ERROR_DIR=$$out/share/evolution/errors"
    "ICON_DIR=$$out/share/evolution/images"
    "EVOLUTION=evolution"
  ];

  patches = [ ./evolution-rss-content-encoding.patch ./evolution-rss-fix-path-to-evolution.patch ];

  NIX_CFLAGS_COMPILE = "-I${nspr.dev}/include/nspr -I${nss.dev}/include/nss -I${glib.dev}/include/gio-unix-2.0";

  enableParallelBuilding = true;

  preFixup = ''
    for f in $out/bin/* $out/libexec/*; do
      wrapProgram "$f" \
        --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE" \
        --prefix XDG_DATA_DIRS : "${gnome3.gnome_themes_standard}/share:$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH"
    done
  '';

}
