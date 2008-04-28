module VersionFu
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def version_fu
      return if self.included_modules.include? VersionFu::InstanceMethods
      __send__ :include, VersionFu::InstanceMethods

      cattr_accessor :versioned_class_name, :versioned_foreign_key, :versioned_table_name, :versioned_inheritance_column, 
        :version_column, :non_versioned_columns
        
      send :attr_accessor, :aav_changed_attributes

      self.versioned_class_name         = "Version"
      self.versioned_foreign_key        = self.to_s.foreign_key
      self.versioned_table_name         = "#{table_name_prefix}#{base_class.name.demodulize.underscore}_versions#{table_name_suffix}"
      self.versioned_inheritance_column = "versioned_#{inheritance_column}"
      self.version_column               = 'version'
      self.non_versioned_columns        = [self.primary_key, inheritance_column, 'version', 'lock_version', versioned_inheritance_column]

      # Setup versions association
      class_eval do
        has_many :versions, :class_name  => "#{self.to_s}::#{versioned_class_name}",
                            :foreign_key => versioned_foreign_key,
                            :order       => 'version',
                            :dependent   => :delete_all
      end

      # Versioned Model
      const_set(versioned_class_name, Class.new(ActiveRecord::Base)).class_eval do
        def self.reloadable? ; false ; end
      end

      versioned_class.cattr_accessor :original_class
      versioned_class.original_class = self
      versioned_class.set_table_name versioned_table_name
      versioned_class.belongs_to self.to_s.demodulize.underscore.to_sym, 
        :class_name  => "::#{self.to_s}", 
        :foreign_key => versioned_foreign_key
    end
    
    def versioned_class
      const_get versioned_class_name
    end
    
  end


  module InstanceMethods
  end
  
end