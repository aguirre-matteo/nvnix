{
  stdenvNoCC,
  writeText,
  makeWrapper,
  lib,

  coreutils,
  findutils,
  git,
  gcc,
  neovim,
  nodejs,
  lua5_1,
  lua-language-server,
  ripgrep,
  tree-sitter,

  excludePackages ? [ ],
  extraPackages ? [ ],
  extraConfig ? "",
  chadrcConfig ? "",
  starterConfig,
  extraPlugins ? "return {}",
  lazyLock ? "",

  withDesktopEntry ? true,
  desktopEntryTitle ? "NvChad",
  desktopEntryStyle ? "light",
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nvchad";
  version = "1.0.0";
  src = starterConfig;
  desktopFiles = ./desktop;

  extraConfigFile = if lib.isString extraConfig then writeText "extraConfig.lua" extraConfig else extraConfig;
  extraPluginsFile = if lib.isString extraPlugins then writeText "plugins-2.lua" extraPlugins else extraPlugins;
  newChadrcFile = if lib.isString chadrcConfig then writeText "chadrc.lua" chadrcConfig else chadrcConfig;
  lockFile = if lib.isString lazyLock then writeText "lazy-lock.json" lazyLock else lazyLock;

  newInitFile = writeText "init.lua" ''
    require "init"
    require "extraConfig"
  '';

  newPluginsFile = writeText "init.lua" ''
    M1 = require "plugins.init-1"
    M2 = require "plugins.init-2"
    for i = 1, #M2 do
      M1[#M1 + 1] = M2[i]
    end
    return M1
  '';

  nvimWrapper = writeText "nvchad-nvim-wrapper" ''
    nvim "$@"
  '';

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = let
    defaultPackages = [
      coreutils
      findutils
      git
      gcc
      nodejs
      lua-language-server
      (lua5_1.withPackages (ps: with ps; [ luarocks ]))
      ripgrep
      tree-sitter
    ];
  in lib.unique (
    (lib.filter (e: !(lib.elem e excludePackages)) defaultPackages)
    ++ extraPackages ++ (if neovim == null then [] else [ neovim ])
  );

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,config}
    cp -r $src/* $out/config
    chmod 777 $out/config
    chmod 777 $out/config/lua
    chmod 777 $out/config/lua/plugins
    ${lib.optionalString (chadrcConfig != "") "install -Dm777 $newChadrcFile $out/config/lua/chadrc.lua"}
    mv $out/config/lua/plugins/init.lua $out/config/lua/plugins/init-1.lua
    install -Dm777 $extraPluginsFile $out/config/lua/plugins/init-2.lua
    install -Dm777 $newPluginsFile $out/config/lua/plugins/init.lua
    install -Dm777 $lockFile $out/config/lazy-lock.json
    install -Dm777 $extraConfigFile $out/config/lua/extraConfig.lua;
    mv $out/config/init.lua $out/config/lua/init.lua
    install -Dm777 $newInitFile $out/config/init.lua

    install -Dm777 $nvimWrapper $out/bin/nvim
    wrapProgram $out/bin/nvim --prefix PATH : '${lib.makeBinPath finalAttrs.buildInputs}'
    runHook postInstall
  '';

  postInstall = if withDesktopEntry then ''
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}
    cp $desktopFiles/nvchad.desktop $out/share/applications/
    
    PERMISSIONS=$(stat -c %a $out/share/applications/nvchad.desktop)
    chmod 755 $out/share/applications/nvchad.desktop
    echo "Name=${desktopEntryTitle}" >> $out/share/applications/nvchad.desktop
    echo "Icon=nvchad-${desktopEntryStyle}" >> $out/share/applications/nvchad.desktop
    chmod $PERMISSIONS $out/share/applications/nvchad.desktop

    cp $desktopFiles/*.svg $out/share/icons/hicolor/scalable/apps/
  '' else "";

  meta = {
    description = "Blazing fast Neovim config providing solid defaults and a beautiful UI";
    homepage = "https://nvchad.com/";
    license = lib.licenses.gpl3;
    mainProgram = "nvim";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
