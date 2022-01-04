# frozen_string_literal: true

RSpec.describe 'connector' do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('connector.rb', settings) }

  describe 'server TLS certificates' do
    around(:each) do |example|
      start_https_localhost(example)
    end

    subject(:output) { connector.actions.posts.execute(settings) }

    let(:settings) { {} }

    # enable and run example to leave fake server running and test connection from workato exec
    # workato exec 'actions.posts' --connection=correct
    xit 'leaves fake server running' do
      sleep(600)
    end

    describe 'client not disabling TLS server certificate verification' do
      it 'should not trust server certificate without proper chain' do
        expect { output }.to raise_error(/certificate verify failed/)
      end
    end

    context 'when server custom CA certificate is provided' do
      let(:settings) do
        { custom_server_cert: File.read('spec/certs/root_correct_ca/ca_cert.pem') }
      end

      it 'trusts server certificate with self-signed certificate' do
        expect(output['posts']).not_to be_empty
      end

      context 'when connect to servers not included in custom CA' do
        before(:each) do
          allow_any_instance_of(OpenSSL::X509::Store).to receive(:set_default_paths) do |instance|
            instance.add_file('spec/certs/root_common_ca/ca_cert.pem')
          end
        end

        let(:settings) do
          { custom_server_cert: File.read('spec/certs/root_wrong_ca/ca_cert.pem') }
        end

        it 'does not trust other servers' do
          expect { output }.to raise_error(/certificate verify failed/)
        end

        context 'when connections to other servers allowed' do
          it 'trusts server with common CA certificate' do
            output = connector.actions.posts_weak.execute(settings)

            expect(output['posts']).not_to be_empty
          end
        end
      end
    end
  end

  private

  def start_https_localhost(example, additional_server_options = {})
    default_server_options = {
      ssl: {
        cert: File.read('spec/certs/localhost_server_cert.pem'),
        key: File.read('spec/certs/localhost_server_key.pem')
      },
      webrick: {
        SSLExtraChainCert: [
          OpenSSL::X509::Certificate.new(File.read('spec/certs/intermediate_servers_ca/ca_cert.pem'))
        ]
      },
      json: true
    }
    replies = { '/posts' => [200, {}, { name: 'James', created_at: Time.zone.now }] }
    server_options = default_server_options.deep_merge(additional_server_options)

    StubServer.open(9123, replies, **server_options) do |server|
      server.wait
      example.run
    end
  end
end
