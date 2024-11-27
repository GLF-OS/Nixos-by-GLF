#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#   SPDX-FileCopyrightText: 2022 Victor Fuentes <vmfuentes64@gmail.com>
#   SPDX-FileCopyrightText: 2019 Adriaan de Groot <groot@kde.org>
#   SPDX-License-Identifier: GPL-3.0-or-later
#
#   Calamares is Free Software: see the License-Identifier above.
# ------------------------------------------------------------------------------

import libcalamares
import os
import subprocess
import re
import tempfile

import gettext

_ = gettext.translation(
    "calamares-python",
    localedir=libcalamares.utils.gettext_path(),
    languages=libcalamares.utils.gettext_languages(),
    fallback=True,
).gettext

# ====================================================
# Configuration.nix (Modified)
# ====================================================

cfghead = """
{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan + GLF modules
      ./hardware-configuration.nix
      ./glf
    ];

"""
cfgbootefi = """  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

"""

cfgbootbios = """  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "@@bootdev@@";
  boot.loader.grub.useOSProber = true;

"""

cfgbootnone = """  # Disable bootloader.
  boot.loader.grub.enable = false;

"""

cfgbootgrubcrypt = """  # Setup keyfile
  boot.initrd.secrets = {
    "/boot/crypto_keyfile.bin" = null;
  };
  boot.loader.grub.enableCryptodisk = true;

"""

cfgnetwork = """  networking.hostName = "GLF-OS"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

"""

cfgnetworkmanager = """  # Enable networking
  networking.networkmanager.enable = true;

"""

cfgtime = """  # Set your time zone.
  time.timeZone = "@@timezone@@";

"""

cfglocale = """  # Select internationalisation properties.
  i18n.defaultLocale = "@@LANG@@";

"""

cfglocaleextra = """  i18n.extraLocaleSettings = {
    LC_ADDRESS = "@@LC_ADDRESS@@";
    LC_IDENTIFICATION = "@@LC_IDENTIFICATION@@";
    LC_MEASUREMENT = "@@LC_MEASUREMENT@@";
    LC_MONETARY = "@@LC_MONETARY@@";
    LC_NAME = "@@LC_NAME@@";
    LC_NUMERIC = "@@LC_NUMERIC@@";
    LC_PAPER = "@@LC_PAPER@@";
    LC_TELEPHONE = "@@LC_TELEPHONE@@";
    LC_TIME = "@@LC_TIME@@";
  };

"""

cfggnome = """  # Enable the X11 windowing system.
  services.xserver.enable = true;
 
  services.xserver.excludePackages = [ pkgs.xterm ];
  

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
"""

cfgkeymap = """  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "@@kblayout@@";
    variant = "@@kbvariant@@";
  };

"""
cfgconsole = """  # Configure console keymap
  console.keyMap = "@@vconsole@@";

"""

cfgusers = """  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.@@username@@ = {
    isNormalUser = true;
    description = "@@fullname@@";
    extraGroups = [ @@groups@@ ];
  };

"""

cfgautologin = """  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "@@username@@";

"""

cfgautologingdm = """  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

"""

cfgautologintty = """  # Enable automatic login for the user.
  services.getty.autologinUser = "@@username@@";

"""

cfgtail = """  
  system.stateVersion = "@@nixosversion@@"; # DO NOT TOUCH 
}
"""

# =================================================
# Required functions
# =================================================

def env_is_set(name):
    envValue = os.environ.get(name)
    return not (envValue is None or envValue == "")

def generateProxyStrings():
    proxyEnv = []
    if env_is_set('http_proxy'):
        proxyEnv.append('http_proxy={}'.format(os.environ.get('http_proxy')))
    if env_is_set('https_proxy'):
        proxyEnv.append('https_proxy={}'.format(os.environ.get('https_proxy')))
    if env_is_set('HTTP_PROXY'):
        proxyEnv.append('HTTP_PROXY={}'.format(os.environ.get('HTTP_PROXY')))
    if env_is_set('HTTPS_PROXY'):
        proxyEnv.append('HTTPS_PROXY={}'.format(os.environ.get('HTTPS_PROXY')))

    if len(proxyEnv) > 0:
        proxyEnv.insert(0, "env")

    return proxyEnv

def pretty_name():
    return _("Installing GLF-OS.")

status = pretty_name()

def pretty_status_message():
    return status

def catenate(d, key, *values):
    """
    Sets @p d[key] to the string-concatenation of @p values
    if none of the values are None.
    This can be used to set keys conditionally based on
    the values being found.
    """
    if [v for v in values if v is None]:
        return

    d[key] = "".join(values)

# ==================================================================================================
#                                       GLF-OS Install function
# ==================================================================================================

def run():
    """NixOS Configuration."""

    global status
    status = _("Configuring NixOS")
    libcalamares.job.setprogress(0.1)

    # Create initial config file
    cfg = cfghead
    gs = libcalamares.globalstorage
    variables = dict()

    # Setup variables
    root_mount_point = gs.value("rootMountPoint")
    config = os.path.join(root_mount_point, "etc/nixos/configuration.nix")
    fw_type = gs.value("firmwareType")
    bootdev = (
        "nodev"
        if gs.value("bootLoader") is None
        else gs.value("bootLoader")["installPath"]
    )

# ================================================================================
# Bootloader
# ================================================================================

    # Check bootloader
    if fw_type == "efi":
        cfg += cfgbootefi
    elif bootdev != "nodev":
        cfg += cfgbootbios
        catenate(variables, "bootdev", bootdev)
    else:
        cfg += cfgbootnone

# ================================================================================
# Setup encrypted swap devices. nixos-generate-config doesn't seem to notice them.
# ================================================================================

    for part in gs.value("partitions"):
        if (
            part["claimed"] is True
            and (part["fsName"] == "luks" or part["fsName"] == "luks2")
            and part["device"] is not None
            and part["fs"] == "linuxswap"
        ):
            cfg += """  boot.initrd.luks.devices."{}".device = "/dev/disk/by-uuid/{}";\n""".format(part["luksMapperName"], part["uuid"])

    # Check partitions
    root_is_encrypted = False
    boot_is_encrypted = False
    boot_is_partition = False

    for part in gs.value("partitions"):
        if part["mountPoint"] == "/":
            root_is_encrypted = part["fsName"] in ["luks", "luks2"]
        elif part["mountPoint"] == "/boot":
            boot_is_partition = True
            boot_is_encrypted = part["fsName"] in ["luks", "luks2"]

    # Setup keys in /boot/crypto_keyfile if using BIOS and Grub cryptodisk
    if fw_type != "efi" and (
        (boot_is_partition and boot_is_encrypted)
        or (root_is_encrypted and not boot_is_partition)
    ):
        cfg += cfgbootgrubcrypt
        status = _("Setting up LUKS")
        libcalamares.job.setprogress(0.15)
        try:
            libcalamares.utils.host_env_process_output(
                ["mkdir", "-p", root_mount_point + "/boot"], None
            )
            libcalamares.utils.host_env_process_output(
                ["chmod", "0700", root_mount_point + "/boot"], None
            )
            # Create /boot/crypto_keyfile.bin
            libcalamares.utils.host_env_process_output(
                [
                    "dd",
                    "bs=512",
                    "count=4",
                    "if=/dev/random",
                    "of=" + root_mount_point + "/boot/crypto_keyfile.bin",
                    "iflag=fullblock",
                ],
                None,
            )
            libcalamares.utils.host_env_process_output(
                ["chmod", "600", root_mount_point + "/boot/crypto_keyfile.bin"], None
            )
        except subprocess.CalledProcessError:
            libcalamares.utils.error("Failed to create /boot/crypto_keyfile.bin")
            return (
                _("Failed to create /boot/crypto_keyfile.bin"),
                _("Check if you have enough free space on your partition."),
            )

        for part in gs.value("partitions"):
            if (
                part["claimed"] is True
                and (part["fsName"] == "luks" or part["fsName"] == "luks2")
                and part["device"] is not None
            ):
                cfg += """  boot.initrd.luks.devices."{}".keyFile = "/boot/crypto_keyfile.bin";\n""".format(
                    part["luksMapperName"]
                )
                try:
                    # Grub currently only supports pbkdf2 for luks2
                    libcalamares.utils.host_env_process_output(
                        [
                            "cryptsetup",
                            "luksConvertKey",
                            "--hash",
                            "sha256",
                            "--pbkdf",
                            "pbkdf2",
                            part["device"],
                        ],
                        None,
                        part["luksPassphrase"],
                    )
                    # Add luks drives to /boot/crypto_keyfile.bin
                    libcalamares.utils.host_env_process_output(
                        [
                            "cryptsetup",
                            "luksAddKey",
                            "--hash",
                            "sha256",
                            "--pbkdf",
                            "pbkdf2",
                            part["device"],
                            root_mount_point + "/boot/crypto_keyfile.bin",
                        ],
                        None,
                        part["luksPassphrase"],
                    )
                except subprocess.CalledProcessError:
                    libcalamares.utils.error(
                        "Failed to add {} to /boot/crypto_keyfile.bin".format(
                            part["luksMapperName"]
                        )
                    )
                    return (
                        _("cryptsetup failed"),
                        _(
                            "Failed to add {} to /boot/crypto_keyfile.bin".format(
                                part["luksMapperName"]
                            )
                        ),
                    )

# ================================================================================
# Writing cfg modules to configuration.nix
# ================================================================================

    status = _("Configuring NixOS")
    libcalamares.job.setprogress(0.18)
   
    # Network
    cfg += cfgnetwork
    cfg += cfgnetworkmanager

    # Hostname
    if gs.value("hostname") is None:
        catenate(variables, "hostname", "GLF-OS")
    else:
        catenate(variables, "hostname", gs.value("hostname"))

    # Internationalisation properties
    if gs.value("locationRegion") is not None and gs.value("locationZone") is not None:
        cfg += cfgtime
        catenate(
            variables,
            "timezone",
            gs.value("locationRegion"),
            "/",
            gs.value("locationZone"),
        )
    if gs.value("localeConf") is not None:
        localeconf = gs.value("localeConf")
        locale = localeconf.pop("LANG").split("/")[0]
        cfg += cfglocale
        catenate(variables, "LANG", locale)
        if (
            len(set(localeconf.values())) != 1
            or list(set(localeconf.values()))[0] != locale
        ):
            cfg += cfglocaleextra
            for conf in localeconf:
                catenate(variables, conf, localeconf.get(conf).split("/")[0])

    # Choose desktop environment
    if gs.value("packagechooser_packagechooser") == "gnome":
        cfg += cfggnome

    # Keyboard layout settings
    if (
        gs.value("keyboardLayout") is not None
        and gs.value("keyboardVariant") is not None
    ):
        cfg += cfgkeymap
        catenate(variables, "kblayout", gs.value("keyboardLayout"))
        catenate(variables, "kbvariant", gs.value("keyboardVariant"))

        if gs.value("keyboardVConsoleKeymap") is not None:
            try:
                subprocess.check_output(
                    ["pkexec", "loadkeys", gs.value("keyboardVConsoleKeymap").strip()],
                    stderr=subprocess.STDOUT,
                )
                cfg += cfgconsole
                catenate(
                    variables, "vconsole", gs.value("keyboardVConsoleKeymap").strip()
                )
            except subprocess.CalledProcessError as e:
                libcalamares.utils.error("loadkeys: {}".format(e.output))
                libcalamares.utils.error(
                    "Setting vconsole keymap to {} will fail, using default".format(
                        gs.value("keyboardVConsoleKeymap").strip()
                    )
                )
        else:
            kbdmodelmap = open("/run/current-system/sw/share/systemd/kbd-model-map", "r")
            kbd = kbdmodelmap.readlines()
            out = []
            for line in kbd:
                if line.startswith("#"):
                    continue
                out.append(line.split())
            # Find rows with same layout
            find = []
            for row in out:
                if gs.value("keyboardLayout") == row[1]:
                    find.append(row)
            if find != []:
                vconsole = find[0][0]
            else:
                vconsole = ""
            if gs.value("keyboardVariant") is not None:
                variant = gs.value("keyboardVariant")
            else:
                variant = "-"
            # Find rows with same variant
            for row in find:
                if variant in row[3]:
                    vconsole = row[0]
                    break
                # If none found set to "us"
            if vconsole != "" and vconsole != "us" and vconsole is not None:
                try:
                    subprocess.check_output(
                        ["pkexec", "loadkeys", vconsole], stderr=subprocess.STDOUT
                    )
                    cfg += cfgconsole
                    catenate(variables, "vconsole", vconsole)
                except subprocess.CalledProcessError as e:
                    libcalamares.utils.error("loadkeys: {}".format(e.output))
                    libcalamares.utils.error("vconsole value: {}".format(vconsole))
                    libcalamares.utils.error(
                        "Setting vconsole keymap to {} will fail, using default".format(
                            gs.value("keyboardVConsoleKeymap")
                        )
                    )

    # Setup user
    if gs.value("username") is not None:
        fullname = gs.value("fullname")
        groups = ["networkmanager", "wheel"]

        cfg += cfgusers
        catenate(variables, "username", gs.value("username"))
        catenate(variables, "fullname", fullname)
        catenate(variables, "groups", (" ").join(['"' + s + '"' for s in groups]))
        if (
            gs.value("autoLoginUser") is not None
            and gs.value("packagechooser_packagechooser") is not None
            and gs.value("packagechooser_packagechooser") != ""
        ):
            cfg += cfgautologin
            if gs.value("packagechooser_packagechooser") == "gnome":
                cfg += cfgautologingdm
        elif gs.value("autoLoginUser") is not None:
            cfg += cfgautologintty

    # Set System version
    cfg += cfgtail
    version = ".".join(subprocess.getoutput(["nixos-version"]).split(".")[:2])[:5]
    catenate(variables, "nixosversion", version)

    # Check that all variables are used
    for key in variables.keys():
        pattern = "@@{key}@@".format(key=key)
        if pattern not in cfg:
            libcalamares.utils.warning("Variable '{key}' is not used.".format(key=key))

    # Check that all patterns exist
    variable_pattern = re.compile(r"@@\w+@@")
    for match in variable_pattern.finditer(cfg):
        variable_name = cfg[match.start() + 2 : match.end() - 2]
        if variable_name not in variables:
            libcalamares.utils.warning(
                "Variable '{key}' is used but not defined.".format(key=variable_name)
            )

    # Do the substitutions
    for key in variables.keys():
        pattern = "@@{key}@@".format(key=key)
        cfg = cfg.replace(pattern, str(variables[key]))

    status = _("Generating NixOS configuration")
    libcalamares.job.setprogress(0.25)

    try:
        # Generate hardware.nix with mounted swap device
        subprocess.check_output(
            ["pkexec", "nixos-generate-config", "--root", root_mount_point],
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as e:
        if e.output is not None:
            libcalamares.utils.error(e.output.decode("utf8"))
        return (_("nixos-generate-config failed"), _(e.output.decode("utf8")))
 
    # Write the configuration.nix file
    libcalamares.utils.host_env_process_output(["cp", "/dev/stdin", config], None, cfg)

    # ========================================================================================
    # GLF IMPORT
    # ========================================================================================

    dynamic_config = "/tmp/nix-cfg/configuration.nix" # Generated by calamares
    iso_config = "/iso/nix-cfg/configuration.nix"     # From GLF (used for condition)
    glf_module = "/iso/nix-cfg/glf"                   # GLF Module

    hw_cfg_dest = os.path.join(root_mount_point, "etc/nixos/hardware-configuration.nix")
    hw_modified = False

    tmpPath = os.path.join(root_mount_point, "tmp/")
    libcalamares.utils.host_env_process_output(["mkdir", "-p", tmpPath])
    libcalamares.utils.host_env_process_output(["chmod", "0755", tmpPath])
    libcalamares.utils.host_env_process_output(["sudo", "mount", "--bind", "/tmp", tmpPath])

    # ========================================================================================
    # Write and Install
    # ========================================================================================

    try:
        with open(hw_cfg_dest, "r") as hf:
            hw_cfg = hf.read()

        if os.path.exists(dynamic_config):
            src_dir = "/tmp/nix-cfg/"
            dest_dir = os.path.join(root_mount_point, "etc/nixos/")
            for file in os.listdir(src_dir):
                src_file = os.path.join(src_dir, file)
                dest_file = os.path.join(dest_dir, file)
                if os.path.isdir(src_file):
                    subprocess.run(["sudo", "cp", "-r", src_file, dest_file], check=True)
                else:
                    subprocess.run(["sudo", "cp", src_file, dest_file], check=True)
            hw_modified = True

        elif os.path.exists(iso_config):
            src_file = glf_module
            dest_file = os.path.join(root_mount_point, "etc/nixos/")
            subprocess.run(["sudo", "cp", "-r", src_file, dest_file], check=True)
            hw_modified = True
                
        temp_filepath = ""
        if hw_modified:
            # Restore generated hardware-configuration
            with tempfile.NamedTemporaryFile(mode="w", delete=False) as temp_file:
                temp_file.write(hw_cfg)
                temp_filepath = temp_file.name
            subprocess.run(["sudo", "mv", temp_filepath, hw_cfg_dest], check=True)

    except subprocess.CalledProcessError as e:
        return ("Installation failed to copy configuration files", str(e))

    finally:
        if os.path.exists(temp_filepath):
            os.remove(temp_filepath)

    status = _("Installing NixOS")
    libcalamares.job.setprogress(0.3)

    # build nixos-install command
    nixosInstallCmd = [ "pkexec" ]
    nixosInstallCmd.extend(generateProxyStrings())
    nixosInstallCmd.extend(
        [
            "nixos-install",
            "--no-root-passwd",
            "--root",
            root_mount_point
        ]
    )

    # Install customizations
    try:
        output = ""
        proc = subprocess.Popen(
            nixosInstallCmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
        )
        while True:
            line = proc.stdout.readline().decode("utf-8")
            output += line
            libcalamares.utils.debug("nixos-install: {}".format(line.strip()))
            if not line:
                break
        exit = proc.wait()
        if exit != 0:
            return (_("nixos-install failed"), _(output))
    except:
        return (_("nixos-install failed"), _("Installation failed to complete"))

    return None
