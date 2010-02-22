require 'rubygems'
require 'active_record'
require 'active_support'

Dir["#{File.dirname(__FILE__)}/entities/*.rb"].each { |file| require file }

module SM
  class SuperMigration
    @@from_db_options = nil
    @@to_db_options   = nil
    
    # I have a feeling this may not be quite good
    @@current_table_from = nil
    @@current_table_to   = nil
    
    @@current_record = Record.new
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
    
    def self.current_record
      @@current_record
    end
    
    def self.current_record=(record_hash)
      @@current_record = record_hash
    end
  end
  
  def define_init_classes(from, to)
    # create a class with the name table[:from] in the SM module
    # which inherits from ActiveRecord::Base
    # call the establish_connection method for this class
    
    SuperMigration.current_table_from = from.to_s.singularize.capitalize
    SM.class_eval("class #{SuperMigration.current_table_from} < ActiveRecord::Base ; establish_connection(SuperMigration.from_db_options) ; end")
    
    # create a class with the name table[:from] in the SM module
    # which inherits from ActiveRecord::Base
    # call the establish_connection nethod for this class
    
    SuperMigration.current_table_to = to.to_s.singularize.capitalize
    SM.class_eval("class #{SuperMigration.current_table_to} < ActiveRecord::Base ; establish_connection(SuperMigration.to_db_options); end")
  end
  
  def table(table = {}, &block)
    return unless block_given?
    
    define_init_classes(table[:from], table[:to])
    
    puts "Migrating data from table #{table[:from]} to table #{table[:to]}"
    puts "-----------------------------------------------------------------"
    
    yield
    
    from_table = SuperMigration.current_table_from
    to_table   = SuperMigration.current_table_to
    
    Kernel.const_get(from_table).all.collect do |record| 
      rc = SuperMigration.current_record.dup
      new_record_hash = Hash.new
      
      rc.fields_maps.each do |field_map|
        unless record.respond_to?(field_map.from)
          raise "Undefined attribute name \"#{field_map.from}\" for Model #{from_table}."
        end
        
        if field_map.block
          new_record_hash[field_map.to] = field_map.block.call(record.send(field_map.from))
        else
          new_record_hash[field_map.to] = record.send(field_map.from)
        end
      end
      new_record = Kernel.const_get(to_table).new(new_record_hash)
      new_record.save!
    end
    
    # reinitialize current_record
    SuperMigration.current_record = Hash.new
  end

  def field(options = {}, &block)
    return if options.size < 2
    if block_given?
      raise "Arity for block is not good." if block.arity != 1
    end
    
    fields_map = FieldsMap.new(options[:from], options[:to], block)
    SuperMigration.current_record.fields_maps << fields_map
  end
end
