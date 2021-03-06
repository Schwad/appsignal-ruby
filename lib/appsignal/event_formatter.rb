module Appsignal
  # Keeps track of formatters for types event that we can use to get
  # the title and body of an event. Formatters should inherit from this class
  # and implement a format(payload) method which returns an array with the title
  # and body.
  #
  # When implementing a formatter remember that it cannot keep separate state per
  # event, the same object will be called intermittently in a threaded environment.
  # So only keep global configuration as state and pass the payload around as an
  # argument if you need to use helper methods.
  #
  # @api private
  class EventFormatter
    class << self
      def formatters
        @@formatters ||= {}
      end

      def formatter_classes
        @@formatter_classes ||= {}
      end

      def register(name, formatter = self)
        formatter_classes[name] = formatter
      end

      def unregister(name, formatter = self)
        return unless formatter_classes[name] == formatter

        formatter_classes.delete(name)
        formatters.delete(name)
      end

      def registered?(name, klass = nil)
        if klass
          formatter_classes[name] == klass
        else
          formatter_classes.include?(name)
        end
      end

      def initialize_formatters
        formatter_classes.each do |name, formatter|
          begin
            format_method = formatter.instance_method(:format)
            if format_method && format_method.arity == 1
              formatters[name] = formatter.new
            else
              raise "#{f} does not have a format(payload) method"
            end
          rescue => ex
            formatter_classes.delete(name)
            formatters.delete(name)
            Appsignal.logger.debug("'#{ex.message}' when initializing #{name} event formatter")
          end
        end
      end

      def format(name, payload)
        formatter = formatters[name]
        formatter.format(payload) unless formatter.nil?
      end
    end

    # @api public
    DEFAULT = 0
    # @api public
    SQL_BODY_FORMAT = 1
  end
end

Dir.glob(File.expand_path("../event_formatter/**/*.rb", __FILE__)).each do |file|
  require file
end
