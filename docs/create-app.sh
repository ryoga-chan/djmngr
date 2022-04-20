#!/bin/bash
rm -rf djmngr
bin/rails new djmngr --rc=railsrc

bin/rails g scaffold author name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text
bin/rails g scaffold circle name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text
bin/rails g scaffold theme  name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text parent_id:integer
bin/rails g migration create_authors_circles author:references circle:references
bin/rails g migration create_authors_themes  author:references theme:references
bin/rails g migration create_circles_themes  circle:references theme:references

bin/rails g scaffold doujin name:string name_romaji:string name_kakasi:string \
  size:integer checksum:string num_images:integer num_files:integer score:integer \
  path:text name_orig:text string:category
bin/rails g migration create_authors_doujinshi author:references doujin:references
bin/rails g migration create_circles_doujinshi circle:references doujin:references

bin/rails db:migrate
