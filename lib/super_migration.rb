require 'rubygems'
require 'active_record'
require 'active_support'

module SM

  class SuperMigration
    @@from_db_options = nil
    @@to_db_options   = nil
    
    # I have a feeling this may not be quite good
    @@current_table_from = nil
    @@current_table_to   = nil
    
    @@current_record_hash = Hash.new
    # ---
    
    def self.setup(&block)
      block.call(self)
    end
    
    def self.migrate(&block)
      yield
    end
    
    def self.from_database(options = {})
      return if options.size < 4
      @@from_db_options = options.dup
    end
    
    def self.to_database(options = {})
      return if options.size < 4
      @@to_db_options = options.dup
    end
    
    def self.from_db_options
      @@from_db_options
    end
    
    def self.to_db_options
      @@to_db_options
    end
    
    def self.current_table_from
      @@current_table_from
    end
    
    def self.current_table_from=(table_from)
      @@current_table_from = table_from
    end
    
    def self.current_table_to
      @@current_table_to
    end
    
    def self.current_table_to=(table_to)
      @@current_table_to = table_to
    end
    
    def self.current_record_hash
      @@current_record_hash
    end
    
    def self.current_record_hash=(record_hash)
      @@current_record_hash = record_hash
    end
  end
  
  def table(table = {}, &block)
    return unless block_given?
    
    # create a class with the name table[:from] in the SM module
    # which inherits from ActiveRecord::Base
    # call the establish_connection method for this class
    
    SuperMigration.current_table_from = table[:from].to_s.singularize.capitalize
    SM.class_eval("class #{SuperMigration.current_table_from} < ActiveRecord::Base ; establish_connection(SuperMigration.from_db_options) ; end")
    
    # create a class with the name table[:from] in the SM module
    # which inherits from ActiveRecord::Base
    # call the establish_connection nethod for this class
    
    SuperMigration.current_table_to = table[:to].to_s.singularize.capitalize
    SM.class_eval("class #{SuperMigration.current_table_to} < ActiveRecord::Base ; establish_connection(SuperMigration.to_db_options); end")
    
    puts "Migrating data from table #{table[:from]} to table #{table[:to]}"
    puts "-----------------------------------------------------------------"
    
    yield
    
    from_table = SuperMigration.current_table_from
    to_table   = SuperMigration.current_table_to
    
    Kernel.const_get(from_table).all.collect do |record| 
      rc = SuperMigration.current_record_hash.dup
      rc.each do |k, v|
        rc[k] = record.send(v)
      end
      new_record = Kernel.const_get(to_table).new(rc)
      new_record.save!
    end
    SuperMigration.current_record_hash = Hash.new
    
    # puts SuperMigration.current_record_hash.inspect
  end

  def field(options = {})
    return if options.size < 2
    
    SuperMigration.current_record_hash[options[:to]] = options[:from]
  end
  
end
