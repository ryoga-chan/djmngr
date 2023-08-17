# Doujinshi manager

This software is made for comics/manga/doujin/novel readers and photographers for
managing their collection of zipped image sets, easying their work with sorting
files, assigning metedata, searching, and reading online from any device.

Populate your collection and:

* browse by metadata with optional filters
* search by title and its translation
* search by **cover similarity**
* **visually compare** multiple sets
* view a **random sample** of images within a ZIP file
* view zipped images directly **in browser**, or in you preferred application,
  or by downloading the ZIP/CBZ file
* create and download a **custom resolution EPUB** for each of your devices
* check ZIP **file integrity** and verify its checksum
* create and manage **shelves** of ZIP files
* assign a **score** and set **favorite** ZIP files
* simple **alternative interface** available for less powerful devices like
  e-readers or old browsers

Screenshots and further instructions are available in the
[homepage](https://ryoga-chan.github.io/djmngr-hp/).

## Collection folders organization of processed ZIP files

- `/circles/<name_romaji>/[subfolder/]file`
- `/authors/<name_romaji>/[subfolder/]file`
- `/magz/<name>/[subfolder/]file`
- `/artbooks/[collection name/][subfolder/]file`

## Notes

- Runs on Rails 7 via Ruby 3
- `docs/create-app.sh` contains the history of some cli commands executed to build the app
- restore a DB dump: `7za x -so db.sql.7z | sqlite3 db/production.sqlite3`

## Local installation

1. install ruby 3.2.x
1. clone the repository and open a terminal within its folder
1. install gems: `bundle install`
1. run database migrations: `./bin/rails db:migrate`
1. run standalone server: `RAILS_SERVE_STATIC_FILES=true ./bin/server p`
1. open a browser to <http://localhost:39102/>
1. configure the app by visiting `/home/settings` page

It is *reccommended* to run the server as `./bin/server p`
behind a reverse proxy like *nginx* or *apache*.

## Requirements

### Required system tools

- [libvips-dev](https://packages.debian.org/stable/libvips-dev)
- [libkakasi2-dev](https://packages.debian.org/stable/libkakasi2-dev)
- [libjpeg-dev](https://packages.debian.org/stable/libjpeg-dev)
- [libpng-dev](https://packages.debian.org/stable/libpng-dev)
- [img2webp](https://packages.debian.org/stable/webp)
- [zip](https://packages.debian.org/stable/zip),
  [unzip](https://packages.debian.org/stable/unzip)
- [find](https://packages.debian.org/stable/findutils)
- [grep](https://packages.debian.org/stable/grep)
- [sort](https://packages.debian.org/stable/coreutils)
- [sha512sum](https://packages.debian.org/stable/coreutils)

Install all on debian with:

~~~shell
apt install libvips-dev libkakasi2-dev libjpeg-dev libpng-dev \
            webp zip unzip findutils grep coreutils
~~~

### Optional tools

- [mcomix](https://packages.debian.org/stable/mcomix) (CBZ/comic book viewer)
- [thunar](https://packages.debian.org/stable/thunar) (file manager)
- [graphviz](https://packages.debian.org/stable/graphviz), [sed](https://packages.debian.org/stable/sed) (ER diagram generation)
- [sqlite3](https://packages.debian.org/stable/sqlite3) (DB dump)
- [p7zip-full](https://packages.debian.org/stable/p7zip-full) (DB dump decompression)

Install all on debian with:

~~~shell
apt install mcomix thunar graphviz sqlite3 p7zip-full
~~~
