module SM
  # map @from to @to aditionally applying a block @block to @to
  # e.g.
  #
  # for the following fields
  #
  #    {:profile_name    => :name, :block => BLOCK},      # => applies the BLOCK on the :name field and put it in profile_name
  #    {:profile_email   => :email, :block => BLOCK},
  #    {:profile_website => :website}                 # => put the :profile_website data on the corresponding :website field 
  class FieldsMap
    attr_accessor :from, :to, :block
    def initialize(from, to, block = nil)
      @from = from
      @to   = to
      @block= block
    end
  end
end