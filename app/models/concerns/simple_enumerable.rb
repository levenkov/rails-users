module SimpleEnumerable
  extend ActiveSupport::Concern

  class_methods do
    def simple_enum(attribute_name, *values, **options)
      if options[:default] && !values.include?(options[:default])
        values.unshift(options[:default])
      end

      enum_hash = values.index_with(&:to_s)

      options[:default] = options[:default].to_s if options[:default]

      enum(attribute_name, enum_hash, **options)
    end
  end
end
