require 'json'
require 'time'

module Lita
  module Handlers
    class Salt < Handler
      config :url, required: true
      config :username, required: true
      config :password, required: true

      class << self
        attr_accessor :token, :expires
      end

      def self.config(config)
        self.token = nil
        self.expires = nil
      end


      #on :connected, :greet

      route /^s(?:alt)? up$/i, :manage_up, command: true, help: {
         'salt up' => 'lists alive minions'
      }

      route /^s(?:alt)? down$/i, :manage_down, command: true, help: {
         'salt down' => 'lists dead minions'
      }

      route /^s(?:alt)? login$/i, :login, command: true, help: {
         'salt login' => 'renew auth token'
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
        body = JSON.dump({client: :runner, fun: 'manage.up'})
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
        body = JSON.dump({client: :runner, fun: 'manage.down'})
        response = make_request('/', body)
        if response.status == 200
          msg.reply response.body
        else
          msg.reply "Failed to run command: #{body}\nError: #{response.body}"
        end
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
    end

    Lita.register_handler(Salt)
  end
end
