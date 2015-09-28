# lita-salt [![Gem Version](https://badge.fury.io/rb/lita-salt.svg)](http://badge.fury.io/rb/lita-salt)

**lita-salt** is an adapter for [Lita](https://www.lita.io) that allows your bot to interact with your saltstack installation via salt-api.

## Installation

Add lita-salt to your Lita instance's Gemfile:

``` ruby
gem "lita-salt"
```

## Configuration

### Required

* `url` (String) – The location of the running salt-api service.
* `username` (String) – The username used to authenticate with salt-api.
* `password` (String) – The password used to authenticate with salt-api.

### Optional

* `returner` (String) – A [Saltstack returner](http://docs.saltstack.com/en/2014.7/ref/returners/all/) you'd like to use. (uses default if unset)

### Example

``` ruby
Lita.configure do |config|
    config.handlers.salt.url = "https://api.example.com"
    config.handlers.salt.username = ENV["SALT_USERNAME"]
    config.handlers.salt.password = ENV["SALT_PASSWORD"]
end
```

## Usage

Commands are called in the with the `salt` prefix what can be optionally with the `s` abbreviation.

```shell
lita: salt minion service.restart nginx
@lita s minion schedule.run_job apt
```

### Example

`lita: salt up` executes the `manage.up` runner and returns a list of up minions.

## License

[MIT](http://opensource.org/licenses/MIT)
