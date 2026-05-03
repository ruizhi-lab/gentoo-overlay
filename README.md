# ruizhi-overlay

Personal Gentoo ebuild repository maintained by Ruizhi Zhong.

The overlay is intended for packages I use and test locally. Most packages are
tested on amd64 with systemd unless noted otherwise.

## Usage

```sh
eselect repository enable guru
eselect repository add ruizhi-overlay git https://github.com/ruizhi-lab/gentoo-overlay.git
emaint sync -r ruizhi-overlay
```

This overlay uses `guru` as an additional master repository for packages that
are not available in the main Gentoo repository, such as `app-arch/libzim`.
