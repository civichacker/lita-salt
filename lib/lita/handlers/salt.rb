require 'json'
require 'time'
require 'lita/utils/payload'

module Lita
  module Handlers
    class Salt < Handler
      include Utils::Payload

      config :url, required: true
      config :username, required: true
      config :password, required: true




      class << self
        attr_accessor :token, :expires, :command_prefix
      end

      def self.default_config(config)
        self.token = nil
        self.expires = nil
        self.command_prefix = "^s(?:alt)?"
      end

      def self.abbreviate(term)
        "#{term[0]}(?:#{term[1,term.length]})?"
      end


      #on :connected, :greet

      route /^#{abbreviate("salt")} up$/i, :manage_up, command: true, help: {
         'salt up' => 'lists alive minions'
      }

      route /^#{abbreviate("salt")} down$/i, :manage_down, command: true, help: {
         'salt down' => 'lists dead minions'
      }

      route /^#{abbreviate("salt")} login$/i, :login, command: true, help: {
         'salt login' => 'renew auth token'
      }

      route /^#{abbreviate("salt")} pillar(?: #{abbreviate("help")})$/i, :pillar, command: true, help: {
        'salt pillar get "some_key"' => 'get a pillar value'
      }

      route /^#{abbreviate("salt")} pillar (get|show)$/i, :pillar, command: true, help: {
        'salt pillar get "some_key"' => 'get a pillar value',
        'salt pillar show "some_minion"' => 'show pillar for given minion'
      }

      def authenticate
        resp = http.post("#{config.url}/login") do |req|
          req.body = {}
          req.body['eauth'] = 'pam'
          req.body['username'] = config.username
          req.body['password'] = config.password
        end
        self.class.token = resp.headers['X-Auth-Token']
        self.class.expires = JSON.parse(resp.body)['return'][0]['expire']
        resp
      end

      def login(msg)
        http_resp = authenticate

        if http_resp.status == 200
          msg.reply "login successful\ntoken: #{self.class.token}"
        elsif http_resp.status == 500
          msg.reply "#{http_resp.status}: login failed!!"
        end

      end

      def headers
        headers = {}
        headers['Content-Type'] = 'application/json'
        headers['X-Auth-Token'] = self.class.token
        headers
      end

      def manage_up(msg)
        if expired
          authenticate
        end
        body = build_runner('manage.up')
        response = make_request('/', body)
        if response.status == 200
          msg.reply response.body
        else
          msg.reply "Failed to run command: #{body}\nError: #{response.body}"
        end
      end

      def manage_down(msg)
        if expired
          authenticate
        end
        body = build_runner('manage.down')
        response = make_request('/', body)
        if response.status == 200
          msg.reply response.body
        else
          msg.reply "Failed to run command: #{body}\nError: #{response.body}"
        end
      end

      def pillar(msg)
        if expired
          authenticate
        end
        body = case msg.match[0].to_s
        when /get/
          build_local('pillar.get',msg.match)
        when /show/
          build_local('pillar.show',msg.match)
        end
        response = make_request('/', body)

        msg.reply_privately "yep"
      end

      def expired
        self.class.token.nil? || Time.now >= Time.at(self.class.expires)
      end

      def make_request(path, body)
        resp = http.post("#{config.url}#{path}") do |req|
          req.body = {}
          req.headers = headers
          req.body = body
        end
        resp
      end

      def url
        config.url
      end

      def username
        config.username
      end

      def password
        config.password
      end

      #private
      #def abbreviate(term)
      #  "#{term[0]}(?:#{term[1,term.length]})?"
      #end
    end

    Lita.register_handler(Salt)
  end
end
