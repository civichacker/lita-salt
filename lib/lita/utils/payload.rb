require 'json'

module Utils
  module Payload

    def build_runner(function, returner=nil)
      s = {
        client: :runner,
        fun: function
      }
      s['ret'] = returner unless returner.nil?
      JSON.dump(s)
    end

    def build_local(target, function, arg=nil, returner=nil)
      s = {
        client: :local,
        tgt: target,
        fun: function
      }
      s['ret'] = returner unless returner.nil?
      s['arg'] = [arg] unless arg.nil?
      JSON.dump(s)
    end
  end
end
