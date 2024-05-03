# roslyn.nvim

This plugin adds support for the new Roslyn-based C# language server [introduced](https://devblogs.microsoft.com/visualstudio/announcing-csharp-dev-kit-for-visual-studio-code) in the [vscode C# extension](https://github.com/dotnet/vscode-csharp).

## Dependencies

Ideally I would like to depend on the Dotnet SDK and everything else to be optional. But for now:

- Dotnet SDK (Tested with .net7).
- [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig) for some path utility functions.
- Neovim nightly required. Tested on `831d662ac6756cab4fed6a9b394e68933b5fe325` but anything after August 2023 would probably work.

## Setup

Just install `seblj/roslyn.nvim` using your plugin manager.

```lua
require("roslyn").setup({
    capabilities = <capabilities you would pass to nvim-lspconfig>, -- required
})
```

## Usage

Before trying to use the language server you should install it. You can install it via VSCode or manually, and it should be placed in neovims datadir with the name `roslyn` (`~/.local/share/nvim/data/roslyn`);

1. Upon opening a C# file, the plugin will look for a `.sln` file in parent directories until it finds one. Make sure to have a `.sln` file somewhere in a parent dir, there is no support yet for `.csproj` only projects.
2. If it only finds one `.sln` file, it will use that to start the server. If it finds multiple, it will ask you to choose one before starting the server. When multiple `.sln` files are found for a file, you can use the command `:CSTarget` to change the target for the buffer at any point.
3. You'll see two notifications if everything goes well. The first one will say `Roslyn client initialized for target <target>`, which means the server is running, but it will just start indexing your `sln`. The second one will say `Roslyn project initialization complete`, it means that the server indexed your `sln`, only after you see the second notification will the `go to definition` and other lsp features be available.

## Features

Please note that some features from the vscode extension might not yet be supported by this plugin.
