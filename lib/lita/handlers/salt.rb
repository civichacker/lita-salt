require 'json'
require 'time'
require 'lita/utils/payload'
require 'lita/utils/decorate'



module Lita
  module Handlers
    class Salt < Handler
      include Utils::Payload
      include Utils::Decorate

      config :url, required: true
      config :username, required: true
      config :password, required: true
      config :returner, required: false



      class << self
        attr_accessor :token, :expires, :command_prefix
      end

      def self.config(config)
        self.token = nil
        self.expires = nil
        self.command_prefix = "^s(?:alt)?"
      end

      def self.abbreviate(term)
        "#{term[0]}(?:#{term[1,term.length]})?"
      end


      route /^#{abbreviate("salt")}\s(.+)\sevent\.(send|fire)\s(.+)$/i, :event, command: true, help: {
        'salt minion event.(fire|send)' => 'Injects an event into the Salt even system'
      }

      route /^#{abbreviate("salt")} up$/i, :manage_up, command: true, help: {
         'salt up' => 'lists alive minions'
      }

      route /^#{abbreviate("salt")} down$/i, :manage_down, command: true, help: {
         'salt down' => 'lists dead minions'
      }

      route /^#{abbreviate("salt")} login$/i, :login, command: true, help: {
         'salt login' => 'renew auth token'
      }

      route /^#{abbreviate("salt")}\s(.+)\sservice\.(restart|start|stop)\s(.+)$/i, :service, command: true, help: {
        'salt minion service.(restart|start|stop)' => 'Performs defined action on service'
      }

      route /^#{abbreviate("salt")}\s(.+)\sschedule\.(run_job|enable_job|disable_job|list)(?:\s(.+))?$/i, :schedule, command: true, help: {
        'salt minion schedule.(run_job|enable_job|disable_job|list)' => 'Interacts with schduling system'
      }

      route /^#{abbreviate("salt")}\s(.+)\ssupervisord\.(status|start|stop|restart|add|remove)\s(.+)$/i, :supervisord, command: true, help: {
        'salt minion supervisord.(status|start|stop|restart|add|remove)' => 'Execute supervisor action'
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

      def event(msg)
        if expired
          authenticate
        end
        where = msg.matches.flatten.first
        task = msg.matches.flatten[1]
        what = msg.matches.flatten[2]
        if what.nil?
          msg.reply "Missing data"
        else
          body = build_local(where, "#{__callee__}.#{task}", what, returner)
          response = make_request('/', body)
          msg.reply process_response(response)
        end
      end


      def manage_up(msg)
        if expired
          authenticate
        end
        body = build_runner('manage.up', returner)
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
        body = build_runner('manage.down', returner)
        response = make_request('/', body)
        if response.status == 200
          msg.reply response.body
        else
          msg.reply "Failed to run command: #{body}\nError: #{response.body}"
        end
      end

      def service(msg)
        if expired
          authenticate
        end
        where = msg.matches.flatten.first
        task = msg.matches.flatten[1]
        what = msg.matches.flatten[2]
        if what.nil?
          msg.reply "Missing service name"
        else
          body = build_local(where, "#{__callee__}.#{task}", what, returner)
          response = make_request('/', body)
          msg.reply process_response(response)
        end
      end

      def schedule(msg)
        if expired
          authenticate
        end
        where = msg.matches.flatten.first
        task = msg.matches.flatten[1]
        what = msg.matches.flatten[2]
        if what.nil?
          msg.reply "Missing job name"
        else
          body = build_local(where, "#{__callee__}.#{task}", what, returner)
          response = make_request('/', body)
          msg.reply process_response(response)
        end
      end

      def supervisord(msg)
        if expired
          authenticate
        end
        where = msg.matches.flatten.first
        task = msg.matches.flatten[1]
        what = msg.matches.flatten[2]
        if what.nil?
          msg.reply "Missing job name"
        else
          body = build_local(where, "#{__callee__}.#{task}", what, returner)
          response = make_request('/', body)
          msg.reply process_response(response)
        end
      end

      def process_response(response)
        out = nil
        case response.status
          when 200
            out = response.body
          when 400..405
            out = "You lack the permissions to perform this action"
          else
            out = "Failed to run command: #{body}\nError: #{response.body}"
        end
        out
      end

      def pillar(msg)
        if expired
          authenticate
        end
        where = msg.matches.flatten.first
        task = msg.matches.flatten[1]
        what = msg.matches.flatten[2]
        if what.nil?
          msg.reply "Missing job name"
        else
          body = build_local(where, "#{__callee__}.#{task}", what, returner)
          response = make_request('/', body)
          msg.reply_privately process_response(response)
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

      def returner
        config.returner
      end

    end

    Lita.register_handler(Salt)
  end
end
