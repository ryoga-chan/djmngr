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

## Folder organization of processed ZIP files

- `/circles/<name_romaji>/[subfolder/]file`
- `/authors/<name_romaji>/[subfolder/]file`
- `/magz/<name>/[subfolder/]file`
- `/artbooks/[collection name/][subfolder/]file`

## Notes

- This app is meant to be executed locally within your home network: no extra attention
  was paid to security regarding external attacks or access management.
  You can however put it behind basic auth and/or other restrictions via nginx/apache.
- Runs on Rails 7 via Ruby 3 using an sqlite3 database file.
- `docs/create-app.sh` contains the history of some cli commands executed to build the app
- restore a DB dump: `7za x -so db.sql.7z | sqlite3 db/production.sqlite3`

## Running the application

### Docker image

*A Docker image will be available in the near feature.*

### Local installation

~~~shell
# install ruby 3.2.x
curl -sSL https://get.rvm.io | bash -s stable
rvm install 3.2.0

# clone the repository
git clone https://github.com/ryoga-chan/djmngr.git

# install gems
cd djmngr && bundle install

# run database migrations
RAILS_ENV=production ./bin/rails db:migrate

# run standalone server
RAILS_SERVE_STATIC_FILES=true ./bin/server p

# wait for assets compilation to finish (done once)
# then open a browser to http://localhost:39102/
# and configure the app in Menu > Tools > Settings
~~~

It is *recommended* to run the server with `./bin/server p`
behind a **reverse proxy** like *nginx* or *apache* because they
are better at serving many static files.

## Requirements

### Required system tools

- images:
  [libvips-dev](https://packages.debian.org/stable/libvips-dev),
  [libkakasi2-dev](https://packages.debian.org/stable/libkakasi2-dev),
  [libjpeg-dev](https://packages.debian.org/stable/libjpeg-dev),
  [libpng-dev](https://packages.debian.org/stable/libpng-dev),
  [img2webp](https://packages.debian.org/stable/webp),
  [imagemagick](https://packages.debian.org/stable/imagemagick)
- compression:
  [zip](https://packages.debian.org/stable/zip),
  [unzip](https://packages.debian.org/stable/unzip)
- core tools:
  [find](https://packages.debian.org/stable/findutils),
  [grep](https://packages.debian.org/stable/grep),
  [sort](https://packages.debian.org/stable/coreutils),
  [sha512sum](https://packages.debian.org/stable/coreutils)
- other:
  [nodejs](https://packages.debian.org/stable/nodejs)

Install all on debian with:

~~~shell
apt install libvips-dev libkakasi2-dev libjpeg-dev libpng-dev \
            webp zip unzip findutils grep coreutils
~~~

### Optional tools

- comics viewer: [mcomix](https://packages.debian.org/stable/mcomix)
- file manager: [thunar](https://packages.debian.org/stable/thunar)
- DB ER diagram: [graphviz](https://packages.debian.org/stable/graphviz), [sed](https://packages.debian.org/stable/sed)
- DB dump/restore:
  [sqlite3](https://packages.debian.org/stable/sqlite3),
  [p7zip-full](https://packages.debian.org/stable/p7zip-full)

Install all on debian with:

~~~shell
apt install mcomix thunar graphviz sqlite3 p7zip-full
~~~
