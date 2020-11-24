# ElementaryAudius 

Native Elementary player for Audius. Currently supports only playing trending tracks and doesn't support automatically playing the next track etc.

This app is NOT yet available on the elementary OS AppCenter. It might be one day if I get around to it.

# Install it from source

You can of course download and install this app from source.

## Dependencies

Ensure you have these dependencies installed

* granite
* gtk+-3.0
* switchboard-2.0
* libsoup2.4-dev
* json-glib-1.0
* libgstreamer-plugins-base1.0-dev

## Install, build and run

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
