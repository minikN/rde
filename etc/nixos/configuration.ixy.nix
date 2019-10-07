# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # Import unstable channel.
  # sudo nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
  # sudo nix-channel --update nixpkgs-unstable
  nixpkgs-unstable = import <nixpkgs-unstable> {};
  nixos-unstable = import <nixos-unstable> {};
in

{
  imports =

    [ # Include the results of the hardware scan.
      ./hardware-configuration.ixy.nix
    ];
  nixpkgs.config.allowUnfree = true;
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  services.tlp = {
    enable = true;
    extraConfig = ''
      START_CHARGE_THRESH_BAT0=75
      STOP_CHARGE_THRESH_BAT0=91
      CPU_SCALING_GOVERNOR_ON_BAT=powersave
      ENERGY_PERF_POLICY_ON_BAT=powersave
  '';
  };

  #######################################################
  # systemd.services.powertop = {                       #
  #   description = ''                                  #
  #     enables powertop's reccomended settings on boot #
  #   '';                                               #
  #   wantedBy = [ "multi-user.target" ];               #
  #   path = with pkgs; [ powertop ];                   #
  #   environment = {                                   #
  #     TERM = "dumb";                                  #
  #   };                                                #
  #  serviceConfig = {                                  #
  #     Type = "idle";                                  #
  #     User = "root";                                  #
  #     ExecStart = ''                                  #
  #       ${pkgs.powertop}/bin/powertop --auto-tune     #
  #     '';                                             #
  #   };                                                #
  # };                                                  #
  #######################################################

#  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 5"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 5"; }
    ];
  };

  #boot.initrd.availableKernelModules = [
  #  "aes_x86_64"
  #  "aesni_intel"
  #  "cryptd"
  #];

  boot.loader = {
    # systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      # efiSysMountPoint = "/boot/efi"; # it's boot now
    };
    grub = {
       enable = true;
       version = 2;
       efiSupport = true;
       # efiInstallAsRemovable = true;
       device = "nodev";
       enableCryptodisk = true;
       gfxmodeEfi = "1024x768";
#       useOSProber = true;
     };
  };

  boot.initrd.luks.devices = [
    {
      name = "enc-pv";
      device = "/dev/disk/by-uuid/26d8adbb-d46d-498d-aa87-b919f40cae94";
      preLVM = true;
      allowDiscards = true;
    }
  ];
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=1
    options iwlwifi power_save=1 d0i3_disable=0 uapsd_disable=0
    options iwldvm force_cam=0
  '';
  boot.kernel.sysctl = {
    "kernel.nmi_watchdog" = 0;
    "vm.dirty_writeback_centisecs" = 6000;
    "vm.laptop_mode" = 5;
    "swappiness" = 1;
  };

  boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];


  environment.variables = {
    BROWSER="qutebrowser";
#    EDITOR="emacs";
    MOZ_ENABLE_WAYLAND="1";
    QT_QPA_PLATFORM="wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION="1";
    _JAVA_AWT_WM_NONREPARENTING="1";
  };

  networking = {
    hostName = "ixy";
    networkmanager.enable = true;
    # firewall.enable = false;
    # firewall.allowedTCPPorts = [3000 5900 5901];
  };
  networking.extraHosts = "127.0.0.1 ${config.networking.hostName}.lan";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  hardware.bluetooth.enable = true;


  services.xserver =
  {
    layout = "us,ru";
    xkbVariant = "dvorak,";
    xkbOptions = "ctrl:nocaps, grp:win_space_toggle, grp:rctrl_switch";
    synaptics = {
      enable = true;
      twoFingerScroll = true;
    };
  };
  i18n.consoleUseXkbConfig = true;
  i18n.consoleFont = "sun12x22";

  time.timeZone = "Europe/Moscow";

  hardware.pulseaudio = {
    enable = true;
    tcp.enable = true; # need for mpd
    package = pkgs.pulseaudioFull;
  };

  systemd.services.thinkpad-fix-sound = {
    description = "Fix the sound on X1 Yoga";
    path = [ pkgs.alsaTools ];
    script = ''
      hda-verb /dev/snd/hwC0D0 0x1d SET_PIN_WIDGET_CONTROL 0x0
    '';
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim htop
    pamixer alsaTools
    powertop
    okular
    xorg.xeyes
    qutebrowser
    nixos-unstable.next
    gnumake
    pavucontrol
    qt5.qtwayland
    unzip p7zip unrar
    nixos-unstable.tdesktop
    firefox
    chromium
    git
    gnupg
    ranger
    ripgrep
    stow
    mpv
  ];



  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.fonts = with pkgs; [
    corefonts  # Micrsoft free fonts
    nixos-unstable.font-awesome
    fira-code
    hack-font
    hasklig
    inconsolata
    iosevka
    source-code-pro
    unifont
    nerdfonts
    ];
  fonts.fontconfig.defaultFonts.monospace = [ "Hack" ];

  users.defaultUserShell = pkgs.zsh;

  programs = {
    light.enable = true;
    sway = {
      enable = true;
      extraPackages = with pkgs; [
        nixos-unstable.swaylock swayidle
	      xwayland
        grim slurp
	      wl-clipboard nixpkgs-unstable.clipman
	      alacritty rxvt_unicode
        rofi dmenu
        i3status i3status-rust
      ];
    };
    ssh.startAgent = true;

    tmux = {
      enable = true;
      keyMode = "vi";
      shortcut = "t";
      terminal = "screen-256color";
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
  };
  security.pam.enableSSHAgentAuth = true;
  virtualisation.docker.enable = true;

  services.emacs = {
    enable = true;
    package = nixos-unstable.emacs;
    defaultEditor = true;
  };

  services.acpid.enable = true;
  services.acpid.handlers.volumeDown = {
    event = "button/volumedown";
    action = "${pkgs.pamixer}/bin/pamixer -d 3";
  };
  services.acpid.handlers.volumeUp = {
    event = "button/volumeup";
    action = "${pkgs.pamixer}/bin/pamixer -i 3";
  };
  services.acpid.handlers.mute = {
    event = "button/mute";
    action = "${pkgs.pamixer}/bin/pamixer -t";
  };
  services.acpid.handlers.cdPlay = {
    event = "cd/play.*";
    action = "${pkgs.mpc_cli}/bin/mpc toggle";
  };
  services.acpid.handlers.cdNext = {
    event = "cd/next.*";
    action = "${pkgs.mpc_cli}/bin/mpc next";
  };
  services.acpid.handlers.cdPrev = {
    event = "cd/prev.*";
    action = "${pkgs.mpc_cli}/bin/mpc prev";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  users.extraUsers.abcdw = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "users" "wheel" "input" "audio" "networkmanager" "docker" "sway"];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
