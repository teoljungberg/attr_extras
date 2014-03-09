require "attr_extras/version"

module AttrExtras
  module ClassMethods
    def attr_initialize(*names)
      min_arity = names.count { |n| not n.is_a?(Array) }
      max_arity = names.length

      define_method(:initialize) do |*values|
        provided_arity = values.length

        unless (min_arity..max_arity).include?(provided_arity)
          arity_range = [min_arity, max_arity].uniq.join("..")
          raise ArgumentError, "wrong number of arguments (#{provided_arity} for #{arity_range})"
        end

        names.zip(values).each do |name_or_names, value|
          if name_or_names.is_a?(Array)
            value ||= {}

            name_or_names.each do |name|
              if name.to_s.end_with?("!")
                actual_name = name.to_s.chop.to_sym
                actual_value = value.fetch(actual_name)
              else
                actual_name = name
                actual_value = value[name]
              end

              instance_variable_set("@#{actual_name}", actual_value)
            end
          else
            name = name_or_names
            instance_variable_set("@#{name}", value)
          end
        end
      end
    end

    def attr_private(*names)
      attr_reader(*names)
      private(*names)
    end

    def pattr_initialize(*names)
      attr_initialize(*names)

      flat_names = names.flatten.map { |x| x.to_s.sub(/!\z/, "") }
      attr_private(*flat_names)
    end

    def attr_value(*names)
      attr_initialize(*names)
      attr_reader(*names.flatten)
    end

    def method_object(method_name, *names)
      singleton_class.send(:define_method, method_name) do |*values|
        new(*values).send(method_name)
      end

      pattr_initialize(*names)
    end

    def attr_query(*names)
      attr_query_with_suffix(*names, "")
    end

    def attr_id_query(*names)
      attr_query_with_suffix(*names, "_id")
    end

    private

    def attr_query_with_suffix(*names, suffix)
      names.each do |name|
        name = name.to_s

        raise "#{__method__} wants `#{name}?`, not `#{name}`." unless name.end_with?("?")

        define_method(name) do             # def foo?
          !!send("#{name.chop}#{suffix}")  #   !!send("foo_id")
        end                                # end
      end
    end
  end
end

class Class
  include AttrExtras::ClassMethods
end
