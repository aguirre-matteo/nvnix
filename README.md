<div align="center">
    <img alt="NvNix Logo" width="200" src="logo.svg">
    <br>
    NvNix, a <a href="https://github.com/nix-community/nix4nvchad">nix4nvchad</a> fork with some extra features.
</div>

## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
    - [Installation](#installation)
    - [Configuration](#configuration)
- [License](#license)

## Introduction
This repository offers a Home-Manager module for setting up NvChad in a declarative way. It works by creating an extra phase in Home-Manager's activation script, where the configuration is copied to the user's home directory. It's done this way since NvChad will try to edit the contents of the `lazy-lock.json` file, but that would fail since `/nix/store` is mounted as read-only filesystem.

## Usage

### Installation
The first step is to add this repository to your flake's inputs. Also make sure you override its `nixpkgs` input, or otherwise you'll have to download two different versions of `nixpkgs`.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvnix = {
      url = "github:aguirre-matteo/nvnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Then import the module in your configuration. Make sure you can access the `inputs` argument in your HM config by passing it to `extraSpecialArgs`.

```nix
{ inputs, ... }:

{
  imports = [
    inputs.homeManagerModules.nvnix
  ];
}
```

### Configuration
Now you have some options under `programs.nvchad`. Here's a table with all the options and their respective description.

| Option | Description |
|--------|-------------|
| `enable` | Whether to enable NvChad |
| `package` | The Neovim package to use. Set it to null if you want to use the globally available `nvim` binary |
| `finalPackage` | The final package containing the wrapped Neovim and the NvChad configuration |
| `starterConfig` | The NvChad starter config to use. This allows you to use your own config instead of the one from NvChad |
| `excludePackages` | List of packages to exclude from the default ones included to the wrapper's PATH |
| `extraPackages` | List of extra packages to include as dependencies to the wrapper's PATH |
| `extraPlugins` | Extra plugins to install through `lazy.nvim` |
| `extraConfig` | Extra configuration to be loaded at the end of `init.lua` |
| `chadrcConfig` | Config to be put to `chadrc.lua` |
| `lazyLock` | The `lazy-lock.json` file for pinning the plugins versions |
| `backup` | Whether to backup or not the previous Neovim config. You probably want to disable this in order to save disk space |
| `desktopEntry.enable` | Whether to enable the desktop entry for NvChad |
| `desktopEntry.title` | The title the desktop entry should display |
| `desktopEntry.style` | Which logo the desktop entry should have. Either `light` or `dark` |

## Differences with respect to nix4nvchad
The main differences between this project and the original `nix4nvchad` are:

- No use of a more complex wrapper. The original wrapped `nvim` automatically tried to 
install NvChad's config if there's no an existing config.
- The option `neovim` is renamed to `package`.
- The option `lazy-lock` is renamed to `lazyLock`.
- The option `gcc` is removed. Instead, I encourage you to override `finalPackage`.
- The option `hm-activation` is removed, since it's redundant because when off the module has no effect to the user's environment.
- Added the `desktopEntry` option, so users can opt-out from the desktop entry.
- Added the `starterConfig` option, so users can change it direcly from their configs.
- Added the `excludePackages` option, so users can opt-out from some of the preinstalled packages.
- Code restructuring for making it more readable and maintainable.

## License
All the code in this repository is under the GPL-3.0 license. You can see the details [here](LICENSE).
