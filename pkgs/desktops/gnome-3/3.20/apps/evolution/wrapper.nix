{ stdenv, symlinkJoin, evolution, makeWrapper, plugins, version }:

let
extraArgs = map (x: x.wrapArgs or "") plugins;
in symlinkJoin {
  name = "evolution-with-plugins-${version}";

  paths = [ evolution ] ++ plugins;

  buildInputs = [ makeWrapper ];

  plugins = map (x: x + "/share/gsettings-schemas/" + x.name ) plugins;

  postBuild = ''
    wrapProgram $out/bin/evolution \
      --suffix-each EVOLUTION_PLUGIN_PATH ':' "$out/lib/evolution/plugins" \
      --prefix XDG_DATA_DIRS : $plugins \
      ${toString extraArgs}
  '';
}
