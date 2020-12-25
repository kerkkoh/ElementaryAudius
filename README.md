# ElementaryAudius 

Native elementaryOS player for Audius. Currently supports playing trending tracks and tracks from any of the artists on Audius.

![Screenshots](https://github.com/kerkkoh/ElementaryAudius/blob/main/screenshots/3_combined.png?raw=true)

This app is NOT yet available on the elementary OS AppCenter. It might be one day if I get around to it. This is still not really a music player, but rather like one of those old school mp3 players where you just pressed previous, pause/play, and next song. Hence, I believe introducing it to the appstore as is would be detrimental.

You can run this on Ubuntu as well, as long as you have all the dependencies installed.

# Install it from source

You can of course download and install this app from source.

## Dependencies

Ensure you have these dependencies installed

* granite
* gtk+-3.0
* switchboard-2.0
* libsoup2.4-dev
* json-glib-1.0 / libjson-glib-dev
* libgstreamer-plugins-base1.0-dev

## Install, build and run

The dependencies listed here differ in package names between distributions, but these seem to work fine with elementaryOS 5.1.7 Hera. The elementary-sdk package isn't necessary for installing this on Ubuntu etc.

Please report back to me if some package isn't working on a certain distro and we can take a look at an alternative name so you can get it from your package manager.

```bash
# install dependencies
sudo apt install libsoup2.4-dev json-glib-1.0 libgstreamer-plugins-base1.0-dev
# install elementary-sdk, meson and ninja 
sudo apt install elementary-sdk meson ninja
# clone repository
git clone https://github.com/kerkkoh/ElementaryAudius
# cd to dir
cd ElementaryAudius
# run meson
meson build --prefix=/usr
# cd to build, build and test
cd build
sudo ninja install && ElementaryAudius
```

## Generating pot file

```bash
# after setting up meson build
cd build

# generates pot file
sudo ninja ElementaryAudius-pot

# to regenerate and propagate changes to every po file
sudo ninja ElementaryAudius-update-po
```
