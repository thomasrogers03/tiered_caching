module TieredCaching
  class Logging
    #noinspection RubyClassVariableUsageInspection
    @@logger = Logger.new(STDOUT).tap { |logger| logger.level = Logger::WARN }

    class << self
      def logger=(value)
        @@logger = value
      end

      def logger
        @@logger
      end
    end

  end
end