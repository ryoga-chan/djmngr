#!/bin/bash
rm -rf djmngr
bin/rails new djmngr --rc=railsrc

bin/rails g scaffold author name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text
bin/rails g scaffold circle name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text
bin/rails g scaffold theme name:string name_romaji:string name_kana:string name_kakasi:string url:string info:text aliases:text links:text parent_id:integer
bin/rails g migration create_authors_circles author:references circle:references
bin/rails g migration create_authors_themes  author:references theme:references
bin/rails g migration create_circles_themes  circle:references theme:references
bin/rails db:migrate
