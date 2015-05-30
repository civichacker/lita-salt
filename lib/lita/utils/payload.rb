require 'json'

module Utils
  module Payload

    def build_runner(function)
      JSON.dump({
        client: :runner,
        fun: function
      })
    end

    def build_local(target, function, arg=nil)
      s = {
        client: :local,
        tgt: target,
        fun: function,
      }
      s['args'] = [arg] unless arg.nil?

      JSON.dump(s)
    end
  end
end
