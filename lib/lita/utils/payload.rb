require 'json'

module Utils
  module Payload

    def build_runner(function)
      JSON.dump({
        client: :runner,
        fun: function
      })
    end

    def build_local(function, matches)
      JSON.dump({
        client: :local,
        tgt: march[0],
        fun: function,
        args: [match[1]]
      })
    end
  end
end
