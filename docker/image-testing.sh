# pull and run server
docker pull ryogachan/djmngr:latest

docker run --rm -ti --name djmngr \                                                                                                                                      Tue 13 Feb 2024 09:45:58 PM CET
  -p "3000:3000" \
  -v ./db:/app/storage \
  -v ./lib:/app/dj-library \
  ryogachan/djmngr

# connect to container, open console, run commands
docker exec -u rails -ti (docker container ls|grep djmngr|cut -f 1 -d ' ') bash -il

bin/console p

ProcessIndexRefreshJob.perform_now
ProcessIndexPreviewJob.perform_now
ProcessIndexGroupJob  .perform_now
ProcessableDoujin.last.cover_fingerprint
