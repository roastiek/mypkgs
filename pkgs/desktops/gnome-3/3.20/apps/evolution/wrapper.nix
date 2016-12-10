{ stdenv, symlinkJoin, evolution, makeWrapper, plugins, version
, gnome3, buildInputs_ }:

let
extraArgs = map (x: x.wrapArgs or "") plugins;
in symlinkJoin {
  name = "evolution-with-plugins-${version}";

  paths = [ evolution ] ++ plugins;

  buildInputs = buildInputs_ ++ [ evolution ] ++ plugins;

  postBuild = ''
    rm $out/bin/evolution
    mv $out/bin/.evolution-wrapped $out/bin/evolution
    wrapProgram $out/bin/evolution \
      --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE" \
      --suffix-each EVOLUTION_PLUGIN_PATH ':' "$out/lib/evolution/plugins" \
      --prefix XDG_DATA_DIRS : "${gnome3.gnome_themes_standard}/share:$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH"
  '';
}
