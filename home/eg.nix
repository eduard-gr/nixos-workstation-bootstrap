{ config, pkgs, inputs, ... }:

{
  home = {
    stateVersion = "25.11";
    packages = [
      pkgs.polonium
    ];
  };

  systemd.user.services.dropbox = {
      Unit = {
          Description = "Dropbox service";
      };
      Install = {
          WantedBy = [ "default.target" ];
      };
      Service = {
          ExecStart = "${pkgs.dropbox}/bin/dropbox";
          Restart = "on-failure";
      };
  };

  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];


  /**
   *
   * https://github.com/nix-community/plasma-manager
   */
  programs.plasma = {
    enable = true;

    session = {
      #general = false;
      sessionRestore = {
        restoreOpenApplicationsOnLogin = "startWithEmptySession";
      };
    };

    workspace = {
      lookAndFeel = "org.kde.breezetwilight.desktop";
      theme = "Breeze Twilight";
      colorScheme = "BreezeClassic";
      iconTheme = "breeze-dark";
      cursor = {
        theme = "Breeze";
      };
      wallpaper = "/home/eg/Dropbox/Wallpapers/ibm-retro-mainframe.jpg";
    };

    kwin = {
      scripts.polonium.enable = false;
    };

    input.keyboard.switchingPolicy = "window";

    panels = [
      {
        location = "left";
        height = 48;
        widgets = [
          "org.kde.plasma.kickoff"
          #"org.kde.plasma.taskmanager"
          {
            name = "org.kde.plasma.icontasks";
            config = {
              #behavior.grouping.method = "none";
              groupingStrategy = "none";
              General = {
                launchers = [
                  "applications:org.kde.konsole.desktop"
                  "applications:google-chrome.desktop"
                  "applications:chromium-browser.desktop"
                  "applications:firefox.desktop"
                  "applications:dbeaver.desktop"
                  "applications:phpstorm.desktop"
                  "applications:postman.desktop"
                  "applications:org.kde.dolphin.desktop"
                ];
              };
            };
          }
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];

    shortcuts = {
      kwin = {
        "Polonium: Toggle Tiling" = "Meta+T";

        "Show Desktop Grid" = "Meta+G";
        "Window Quick Tile Right" = "";
        "Window Quick Tile Left" = "";

        "Window to Next Screen" = "Meta+Right";
        "Window to Previous Screen" = "Meta+Left";

        "Window Maximize" = "Meta+F";
        "Maximize Window" = "";
      };

      konsole = {
        "Launch Konsole" = "Meta+Enter";
      };

      # klipper = {
      #   "Copy" = "Ctrl+C";
      #   "Cut" = "Ctrl+X";
      #   "Paste" = "Ctrl+V";
      # };
    };
  };


  programs.zed-editor = {
    enable = true;

    # This populates the userSettings "auto_install_extensions"
    extensions = [ "nix" "toml" "make" "php" "java" "dockerfile" "html" "xml"];

    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          #"ctrl-shift-t" = "workspace::NewTerminal";
          #"copy": "editor::Copy",
          "ctrl-c" = "editor::Copy";
          "ctrl-v" = "editor::Paste";
          "ctrl-x" = "editor::Cut";
          "ctrl-s" = "workspace::Save";
          "ctrl-shift-u" = "editor::ConvertToOppositeCase";
          "ctrl-shift-f6" = "editor::Rename";
          "Ctrl-+" = "editor::ToggleCodeActions";
          #"ctrl-shift-f" = "workspace::SearchInWorkspace";
        };
      }
    ];

    mutableUserKeymaps = false;

    # Everything inside of these brackets are Zed options
    userSettings = {

      preview_tabs = {
        enabled = false;
        enable_preview_from_file_finder = true;
        enable_keep_preview_on_code_navigation = true;
      };

      assistant = {
        enabled = true;
        version = "2";
        default_open_ai_model = null;

        # Provider options:
        # - zed.dev models (claude-3-5-sonnet-latest) requires GitHub connected
        # - anthropic models (claude-3-5-sonnet-latest, claude-3-haiku-latest, claude-3-opus-latest) requires API_KEY
        # - copilot_chat models (gpt-4o, gpt-4, gpt-3.5-turbo, o1-preview) requires GitHub connected
        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-latest";
        };

        # inline_alternatives = [
        #   {
        #     provider = "copilot_chat";
        #     model = "gpt-3.5-turbo";
        #   }
        # ];

      };

  #    node = {
  #      path = lib.getExe pkgs.nodejs;
  #      npm_path = lib.getExe' pkgs.nodejs "npm";
  #    };

      hour_format = "hour24";
      auto_update = false;

      show_completions_on_input = true;
      show_completion_documentation = true;

      auto_signature_help = true;
      show_signature_help_after_edits = true;

      inlay_hints = {
        enabled = true;
        show_parameter_hints = true;
        show_type_hints = true;
        show_other_hints = true;
      };


      terminal = {
        alternate_scroll = "off";
        blinking = "off";
        copy_on_select = false;
        dock = "bottom";
        detect_venv = {
          on = {
            directories = [ ".env" "env" ".venv" "venv" ];
            activate_script = "default";
          };
        };
        env = {
          TERM = "alacritty";
        };
        font_family = "FiraCode Nerd Font";
        font_features = null;
        font_size = null;
        line_height = "comfortable";
        option_as_meta = false;
        button = false;
        shell = "system";
        # shell = {
        #   program = "zsh";
        # };
        toolbar = {
          # title = true;
        };
        working_directory = "current_project_directory";
      };

      lsp = {
        php = {
          language_servers = ["intelephense"];
        };
        rust-analyzer = {
          binary = {
            # path = lib.getExe pkgs.rust-analyzer;
            path_lookup = true;
          };
        };

        nix = {
          binary = {
            path_lookup = true;
          };
        };

      };

      languages = {
        "HEEX" = {
          language_servers = [ "!lexical" "elixir-ls" "!next-ls" ];
          format_on_save = {
            external = {
              command = "mix";
              arguments = [ "format" "--stdin-filename" "{buffer_path}" "-" ];
            };
          };
        };
      };

      vim_mode = false;

      # Tell Zed to use direnv and direnv can use a flake.nix environment
      load_direnv = "shell_hook";
      base_keymap = "VSCode";

      theme = {
        mode = "system";
        light = "Gruvbox Dark";
        dark = "One Dark";
      };

      show_whitespaces = "all";
      ui_font_size = 16;
      buffer_font_size = 16;
    };
  };


  # xdg.configFile."dolphinrc" = {
  #   force = true;
  #   text = ''
  #     [General]
  #     ShowTerminalPanel=true
  #     ShowPlacesPanel=true
  #     ViewMode=Details
  #   '';
  # };



}
