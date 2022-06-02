# https://ryanboland.com/blog/creating-a-database-diagram-with-rails-erd
namespace :db do
  desc 'Generate Entity Relationship Diagram'
  task :erd do
    system %Q| erd --filetype=dot --orientation=horizontal |
    system %Q| sed -i -r 's/^  m_/rankdir = "LR";\\0/' erd.dot | # fix orientation
    system %Q| dot -Tpdf erd.dot > docs/db-schema.pdf |
    system %Q| ls -lh --color docs/db-schema.pdf |
    File.unlink 'erd.dot'
    system %Q| xpdf docs/db-schema.pdf & |
  end
end
