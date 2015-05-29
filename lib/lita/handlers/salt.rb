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


      route /^s(?:alt)? up$/i, :manage_up, command: true, help: {
         'salt up' => 'lists alive minions'
      }

      route /^s(?:alt)? down$/i, :manage_down, command: true, help: {
         'salt down' => 'lists dead minions'
      }

      route /^s(?:alt)? login$/i, :login, command: true, help: {
         'salt login' => 'renew auth token'
      }

      route /^s(?:alt)?\s(.+)\sservice\.(restart|start|stop)\s(.+)$/i, :service, command: true, help: {
        'salt minion service.(restart|start|stop)' => 'Performs defined action on service'
      }

      route /^s(?:alt)?\s(.+)\sschedule\.(run_job|enable_job|disable_job|list)\s(.+)$/i, :schedule, command: true, help: {
        'salt minion schedule.(run_job|enable_job|disable_job|list)' => 'Interacts with schduling system'
      }

      route /^s(?:alt)?\s(.+)\ssupervisord\.(status|start|stop|restart|add|remove)\s(.+)$/i, :supervisord, command: true, help: {
        'salt minion supervisord.(status|start|stop|restart|add|remove)' => 'Execute supervisor action'
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
          body = JSON.dump({client: :local, tgt: where, fun: "service.#{task}", arg: [what]})
          response = make_request('/', body)
          process_response(response)
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
          body = JSON.dump({client: :local, tgt: where, fun: "schedule.#{task}", arg: [what]})
          response = make_request('/', body)
          process_response(response)
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
          body = JSON.dump({client: :local, tgt: where, fun: "supervisord.#{task}", arg: [what]})
          response = make_request('/', body)
          process_response(response)
        end
      end

      def process_response(response)
        case response.status
          when 200
            msg.reply response.body
          when 400..405
            msg.reply "You lack the permissions to perform this action"
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
