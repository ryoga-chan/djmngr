# Doujinshi manager

This software is made for doujin/manga/comics/novel readers and photographers to
manage a collection of zipped image sets, easying their work with sorting
files, assigning metedata, searching, and reading online from any device.

Populate your collection and:

* browse it on desktop or mobile devices
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

## Running the application with docker

**Note:** When running the app via docker all external commands will fail to run
(examples: file manager, terminal, ...), for the advanced/full experience consider
the *Local installation*.

### Via docker

~~~shell
# download image
docker pull ryogachan/djmngr

# run image
docker run --rm -ti --name trash \
  -p 3000:3000 \
  -v /path/to/library:/app/dj-library     \
  -v /path/to/epub:/app/public/epub       \
  -v /path/to/thumbs:/app/public/thumbs   \
  -v /path/to/samples:/app/public/samples \
  ryogachan/djmngr
~~~

### Via docker-compose

~~~shell
# download image
docker pull ryogachan/djmngr

# download docker-compose file
wget https://github.com/ryoga-chan/djmngr/raw/main/docker/compose.yml

# edit port/folders in compose.yml, then:
docker compose up -d  # start app in background
docker compose down   # stop app
~~~
