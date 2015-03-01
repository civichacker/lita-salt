require "spec_helper"

describe Lita::Handlers::Salt, lita_handler: true do

  let(:response) {double("Faraday::Response")}
  let(:reply) {""}
  let(:vals) { {url: "https://example.com", username: "timmy", password: "12345"} }
  let(:token) {"122938u98j9r82u3r"}
  let(:salt) { described_class.new }

  describe "config" do
    before do
      Lita.config.handlers.salt.url = vals[:url]
      Lita.config.handlers.salt.username = vals[:username]
      Lita.config.handlers.salt.password = vals[:password]
      described_class.any_instance.stub(:default_config).and_return(vals)
    end

    it "should wrap url config vars" do
      expect(salt).to respond_to(:url)
      expect(salt.url).to eql(vals[:url])
    end
    it "should wrap username config vars" do
      expect(salt).to respond_to(:username)
      expect(salt.username).to eql(vals[:username])
    end
    it "should wrap password config vars" do
      expect(salt).to respond_to(:password)
      expect(salt.password).to eql(vals[:password])
    end

  end

  describe "#login" do
    before do
      stub_request(:post, "#{vals[:url]}/login").
        to_return(status: 200,
                  body: JSON.dump(return: [{token: token, expire: 1424352200.50011}]),
                  headers: {'X-Auth-Token' => token}
        )
    end

    it { is_expected.to route_command('salt login').to(:login) }
    it "should greet user at successful login" do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(reply)
      allow(response).to receive(:headers).and_return(token)
      send_command('s login')
      expect(replies.last).to eq("login successful\ntoken: #{token}")
    end
  end

  describe "#manage_up" do
    before do
      stub_request(:post, "#{vals[:url]}/login").
        with(body: {eauth: "pam", password: vals[:password], username: vals[:username]}).
        to_return(status: 200,
                  body: JSON.dump(return: [{token: token, expire: 1424352200.50011}]),
                  headers: {'X-Auth-Token' => token}
        )
      stub_request(:post, vals[:url]).
        to_return(status: 200,
                  body: JSON.dump(return: [[:main, :silly]])
        )
    end

    it { is_expected.to route_command('salt up').to(:manage_up) }
    it { is_expected.to route_command('s up').to(:manage_up) }
    it "should return a list of alive minions" do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(reply)
      allow(response).to receive(:headers).and_return(token)
      send_command('s up')
      expect(replies.last).to eq(JSON.dump(return: [['main','silly']]))
    end
  end

  describe "#manage_down" do
    before do
      stub_request(:post, "#{vals[:url]}/login").
        with(body: {eauth: "pam", password: vals[:password], username: vals[:username]}).
        to_return(status: 200,
                  body: JSON.dump(return: [{token: token, expire: 1424352200.50011}]),
                  headers: {'X-Auth-Token' => token}
        )
      stub_request(:post, vals[:url]).
        to_return(status: 200,
                  body: JSON.dump(return: [[:main, :silly]])
        )
    end

    it { is_expected.to route_command('salt down').to(:manage_down) }
    it { is_expected.to route_command('s down').to(:manage_down) }
    it "should return a list of dead minions" do
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:body).and_return(reply)
      allow(response).to receive(:headers).and_return(token)
      send_command('s down')
      expect(replies.last).to eq(JSON.dump(return: [['main','silly']]))
    end
  end

  describe "#pillar_get" do
    before do
      stub_request(:post, "#{vals[:url]}/login").
        with(body: {eauth: "pam", password: vals[:password], username: vals[:username]}).
        to_return(status: 200,
                  body: JSON.dump(return: [{token: token, expire: 1424352200.50011}]),
                  headers: {'X-Auth-Token' => token}
        )
      stub_request(:post, vals[:url]).
        to_return(status: 200,
                  body: JSON.dump(return: [[:main, :silly]])
        )
    end

    #it { is_expected.to route_command('salt pillar').to(:pillar) }
    it { is_expected.to route_command('salt pillar help').to(:pillar) }
    it { is_expected.to route_command('salt pillar h').to(:pillar) }
    it { is_expected.to route_command('s pillar help').to(:pillar) }
    it { is_expected.to route_command('s pillar h').to(:pillar) }
    it "should " do
    end
    
  end

end
