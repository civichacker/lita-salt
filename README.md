# lita-salt (beta)

**lita-salt** is an adapter for Lita that gives your bot the power to interact with your saltstack installation via salt-api.

## Installation

Add lita-salt to your Lita instance's Gemfile:

``` ruby
gem "lita-salt"
```

## Configuration

### Required attributes

* `url` (String) – The location of the running salt-api service.
* `username` (String) – The username used to authenticate with salt-api.
* `password` (String) – The password used to authenticate with salt-api.

### Example

``` ruby
Lita.configure do |config|
    config.handlers.salt.url = "https://api.example.com"
    config.handlers.salt.username = ENV["SALT_USERNAME"]
    config.handlers.salt.password = ENV["SALT_PASSWORD"]
end
```

## Usage

TODO: Describe the plugin's features and how to use them.

## License

[MIT](http://opensource.org/licenses/MIT)
