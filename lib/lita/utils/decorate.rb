module Utils
  module Decorate
    @@auth ||= []
  
    def self.included(base)
      base.extend(ClassMethods)
      base
    end
    #def initialize(route)
    #  @route = route
    #end

    module ClassMethods
      def check_auth(*methods)
        methods.each do |method|
          old = "_#{method}".to_sym
          alias_method old, method
          define_method method do |*args|
            send(old, *args)
          end
          #if self.class_eval("expired")
          #  authenticate
          #end
          #unless self.respond_to?(arg)
          #  self.class.send(:define_method,arg,Proc.new {})
          #self.class_eval(self.methods[arg])
        end
      end
    end

      def check_auth(*args)
        args.each do |arg|
          #if self.class_eval("expired")
          #  authenticate
          #end
          self.class_eval(arg.to_s)
        end
      end

=begin
    def manage_up(msg)
      if expired
        authenticate
      end
      @route.manage_up(msg)
    end

    def manage_down
      @route.manage_up(msg)
=end
  end
end
