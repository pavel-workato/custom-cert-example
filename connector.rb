# frozen_string_literal: true

{
  title: 'Custom SSL',

  # HTTP basic auth example.
  connection: {
    fields: [
      {
        name: 'custom_server_cert'
      }
    ],

    authorization: {
      apply: lambda do |connection|
        tls_server_certs(certificates: connection['custom_server_cert'])
      end
    }
  },

  test: lambda { |_connection|
    true
  },

  actions: {
    posts: {
      execute: lambda {
        {
          posts: get('https://localhost:9123/posts')
        }
      }
    },
    posts_weak: {
      execute: lambda { |connection|
        {
          posts: get('https://localhost:9123/posts').tls_server_certs(
            certificates: connection['custom_server_cert'],
            strict: false
          )
        }
      }
    }
  }
}
