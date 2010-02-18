require 'super_migration'
include SM

SuperMigration.setup do |config|
  # same options as in database.yml
  config.from_database :database => "sm1",
                       :adapter  => "mysql",
                       :host     => "localhost",
                       :username => "root",
                       :password => ""
  
  config.to_database   :database => "sm2",
                       :adapter  => "mysql",
                       :host     => "localhost",
                       :username => "root",
                       :password => ""
end

SuperMigration.migrate do 
  table :from => :books, :to => :livres do

    field :from => :author, :to => :autheur
    field :from => :title,  :to => :titre
    
    # apply a transformation to dob field
    #field :from => :dob, :to => :smth do |dob|
    #  (Date.today - dob)/60/60/24/365
    #end

  end
end