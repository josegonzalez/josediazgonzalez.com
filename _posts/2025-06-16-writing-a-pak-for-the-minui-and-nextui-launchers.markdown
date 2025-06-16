---
  title:       "Writing a Pak for the MinUI and NextUI launchers"
  date:        2025-06-16 00:46
  description: ""
  category:    gaming
  tags:
    - minui
    - nextui
    - paks
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: false
---

This post is a collection of notes on how to create Paks for the MinUI libretro frontend and it's forks, such as NextUI. Some of this material may be useful for other platforms, such as OnionOS. I'll be adding to this document from time to time.

## Some background

MinUI is a custom launcher for a variety of handhelds - notably the Anbernic RGNNXX, Trimui, and Miyoo devices, amongst others. It provides a simple interface for launching emulators via [libretro](https://www.libretro.com/) cores, allowing for resuse of existing emulators with a (very) sparing interface. Support for various cores depends on the device, but generally speaking MinUI does not support any OpenGL cores, meaning emulators for more modern consoles such as N64, Dreamcast, or Nintendo DS often need to use standalone "paks" that do not integrate as well with MinUI.

> Note: MinUI has a variety of forks - MyMinUI, FinUI, Corak's MinUI, and NextUI - which all support the same general emulation functionality, though may add extra features on top such as other devices, button shortcuts, or enhanced emulation support. This post won't go into the vagaries of each project as that isn't super important for the topic.

A "pak" is a collection of files in a folder in a specific path on the SD Card which contains a MinUI installation. Paks are nominally device-specific in that the path where they are placed on the SD Card is a hint to MinUI to tell it whether the pak is loadable or not. Paks come in two varieties:

- `Emus`
  - Emu paks are either standalone emulators or wrappers for libretro cores
    - Standalone: A standalone emulator is _generally_ a compiled binary for a particular platform and contains everything needed to launch the emulator. These generally do not integrate well with MinUI functionality (such as sleep, save states, etc.) but maintainers may be able to wrap the standalone emulator in such a way as to support some of the built-in MinUI functionality.
    - Libretro wrappers: All emulators distributed with MinUI are wrappers for libretro cores, and are generally compiled for the device in question using a compatible SDK. Developers may also opt to use a libretro core in a custom emu, though this is usually only done in cases where a developer is not familiar with compiling the core and wishes to use a pre-compiled binary from a Retroarch installation for that device.
  - Community emu paks are stored at `/Emus/$PLATFORM/$EMU.pak`, where `$PLATFORM` is the device platform (such as `tg5040` for the Trimui Brick and TSP) and `$EMU` is the short name for the emu (such as `N64`).
- `Tools`
  - Tools are extra utilities that can be launched on a MinUI installation. These can be as mundane as a button testing tool or something more complex, like an artwork scraper.

A pak _always_ has a `launch.sh` file, which can be either an executable script or a compiled binary. If it is a compiled binary, developers will need to use a toolchain that supports the particular device in order to ensure the compiled binary supports the particular SDK for that device (such as certain sdl versions). The compiled binary can also be _launched by_ the `launch.sh`, which is most common. Due to the need for an SDK and understanding of more complex programming languages, this is generally not the path folks take to write paks.

The alternative to a compiled binary is to use a shell script for your `launch.sh` file. While common shell scripting uses `bash` for the execution environment, many devices do not have bash available, and thus it is recommended that users utilize regular `sh` for their scripts.

> For a shell scripting tutorial, see [this site](https://www.shellscript.sh/).

## Pak scaffolding

A `launch.sh` shell script starts with the following shebang:

```shell
#!/bin/sh

echo "logic goes here"
```

I usually start mine with the following (comments are inline to make it easier to understand):

```shell
#!/bin/sh
# get the pak directory and name
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"
# turn on debugging so that I know what my script is executing
set -x

# optional, but remove the existing log file for the pak
rm -f "$LOGS_PATH/$PAK_NAME.txt"
# redirect stdout to the log directory, /.userdata/$PLATFORM/logs/$PAK_NAME.txt folder on your SD card.
exec >>"$LOGS_PATH/$PAK_NAME.txt"
# also redirect stderr to the same file
exec 2>&1

# write the current pak execution to the logs
echo "$0" "$*"
# change directories to my pak or error out if not possible
# if it errors out, something is deeply wrong
cd "$PAK_DIR" || exit 1

# for paks that support arm and arm64, get the current path
architecture=arm
if uname -m | grep -q '64'; then
    architecture=arm64
fi

# set the HOME directory to the shared path folder
# /.userdata/$PLATFORM/$PAK_NAME
export HOME="$SHARED_USERDATA_PATH/$PAK_NAME"

# add $PAK_DIR/bin/$PLATFORM, $PAK_DIR/bin/$architecture, and $PAK_DIR/bin/shared directories to the PATH
# this lets us override binaries on a per-platform or per-architecture basis
# as well as have shared binaries that span all platforms and architectures
export PATH="$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin/$architecture:$PAK_DIR/bin/shared:$PATH"
```

Many of these devices run some form of Busybox, and thus the available utilities is pretty lacking. You _may_ have access to Python, but often you'll need to distribute other binaries with your pak. I place them in the appropriate path (platform/architecture specific or shared) and ensure they are executable via `chmod +x` on the terminal.

For any persistent data, I place it in the `$HOME` directory (as specified above) so that pak updates do not wipe out the data. This includes settings, which I can read and write in my pak like so:

```shell
# write a value to our key, usually as a default
write_setting() {
  key="$1"
  value="$2"
  echo "$value" > "$HOME/$key"
}

# read a setting out for later usage
# also add support for a default value
read_setting() {
  key="$1"
  default_value="$2"

  if [ -f "$HOME/$key" ]; then
    cat "$HOME/$key"
    return
  fi

  if [ -n "$default_value" ]; then
    echo "$default_value"
  fi
}
```

Since you are writing shell code, you'll probably want a way to either display a message, get input from a keyboard, or show a list of items on the screen. More complex packages will sometimes implement this in a single binary, but the following projects exist for interacting with _most_ platforms supported by MinUI and it's derivatives:

- [minui-btntest](https://github.com/josegonzalez/minui-btntest): Allows for listening for a specific button or button combination. This is useful for background processes that wait for gamepad shortcuts.
- [minui-keyboard](https://github.com/josegonzalez/minui-keyboard): Displays an onscreen keyboard, so that users may input data. Limited to the ASCII character set due to usage of the built-in font used by MinUI.
- [minui-list](https://github.com/josegonzalez/minui-list): Displays a scrollable list of items on screen, with support for displaying and interacting with the items in various ways.
- [minui-presenter](https://github.com/josegonzalez/minui-presenter): Displays a message on the screen, and can also be used in a slideshow-like manner, amongst other features.

Generally speaking, you could use the above projects to support a workflow like:

- Allowing someone to enable/disable background software
- Displaying the current state of the background software
- Showing error messages if the software cannot be launched
- Showing some input for password collection

The majority of existing community paks use shell scripting and the above binaries to provide their functionality, though users may use other projects as well.

## Starting services on MinUI boot

MinUI supports running a shared `auto.sh` file on MinUI start, and that can be abused to provide `init`-like behavior for starting services on device boot.

The following is a pattern I use to start/stop services on boot. I use the following helper functions in my `launch.sh`:

```shell
# removes the `bin/shared/on-boot` script from auto.sh
disable_start_on_boot() {
    sed -i "/${PAK_NAME}.pak-on-boot/d" "$SDCARD_PATH/.userdata/$PLATFORM/auto.sh"
    sync
    return 0
}

# enables running the `bin/shared/on-boot` script on boot
enable_start_on_boot() {
    if [ ! -f "$SDCARD_PATH/.userdata/$PLATFORM/auto.sh" ]; then
        echo '#!/bin/sh' >"$SDCARD_PATH/.userdata/$PLATFORM/auto.sh"
        echo '' >>"$SDCARD_PATH/.userdata/$PLATFORM/auto.sh"
    fi

    echo "test -f \"\$SDCARD_PATH/Tools/\$PLATFORM/$PAK_NAME.pak/bin/shared/on-boot\" && \"\$SDCARD_PATH/Tools/\$PLATFORM/$PAK_NAME.pak/bin/shared/on-boot\" # ${PAK_NAME}.pak-on-boot" >>"$SDCARD_PATH/.userdata/$PLATFORM/auto.sh"
    chmod +x "$SDCARD_PATH/.userdata/$PLATFORM/auto.sh"
    sync
    return 0
}

# check if the service is going to run on boot
# useful for displaying status in the ui
will_start_on_boot() {
    if grep -q "${PAK_NAME}.pak-on-boot" "$SDCARD_PATH/.userdata/$PLATFORM/auto.sh" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}
```

I'll then typically create a `bin/shared/on-boot` file in my pak with the following contents:

```shell
#!/bin/sh
# some general scaffolding to ensure variables are properly set
BIN_DIR="$(dirname "$0")"
# get the pak directory and name
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"
# turn on debugging so that I know what my script is executing
set -x

# optional, but remove the existing log file for the pak
rm -f "$LOGS_PATH/$PAK_NAME.txt"
# redirect stdout to the log directory, /.userdata/$PLATFORM/logs/$PAK_NAME.txt folder on your SD card.
exec >>"$LOGS_PATH/$PAK_NAME.txt"
# also redirect stderr to the same file
exec 2>&1

# write the current pak execution to the logs
echo "$0" "$*"
# change directories to my pak or error out if not possible
# if it errors out, something is deeply wrong
cd "$PAK_DIR" || exit 1

# the main script
main() {
  # run my bin/shared/service-on script in the background
  "$BIN_DIR/shared/service-on" &
}

main "$@"
```

The important part is the following:

```shell
"$BIN_DIR/shared/service-on" &
```

This executes my `bin/shared/service-on` script in the background - the `&` is used by shell to fork the process into the background and continue on. We do this so as to not potentially block MinUI from starting.
