# README

# Collection folders organization

- `/circles/<name_romaji>/[subfolde/]file`
- `/authors/<name_romaji>/[subfolde/]file`
- `/magz/<name>/[subfolde/]file`
- `/artbooks/[collection name]/[subfolde/]file`

# Requirements

- Runs on Rails 7 via Ruby 3
- `docs/create-app.sh` contains the history of cli commands executed to build the app
- restore DBs: `7za x -so db/db+metadata.sql.7z | sqlite3 db/production.sqlite3`
- boot the app then configure it by visiting `/home/settings` page

## Required system tools

- [libvips](https://packages.debian.org/stable/libvips-dev)
- [libkakasi2-dev](https://packages.debian.org/stable/libkakasi2-dev)
- [img2webp](https://packages.debian.org/stable/webp)
- [zip](https://packages.debian.org/stable/zip), [unzip](https://packages.debian.org/stable/unzip)
- [find](https://packages.debian.org/stable/findutils)
- [grep](https://packages.debian.org/stable/grep)
- [sort](https://packages.debian.org/stable/coreutils), [sha512sum](https://packages.debian.org/stable/coreutils)

~~~shell
apt install libvips-dev libkakasi2-dev webp zip unzip findutils grep coreutils
~~~

## Optional tools

- [mcomix](https://packages.debian.org/stable/mcomix)
- [thunar](https://packages.debian.org/stable/thunar)
- [graphviz](https://packages.debian.org/stable/graphviz) (ER diagram generation)
- [p7zip-full](https://packages.debian.org/stable/p7zip-full) (db+metadata.sql.7z decompression)

~~~shell
apt install mcomix thunar graphviz p7zip-full
~~~
