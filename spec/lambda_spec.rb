require_relative '../lambda'

describe 'request' do
  let(:event) { {
    'headers' => {},
    'httpMethod' => 'GET',
    'path' => '/'
  } }

  specify 'returns hello response' do
    expect(request(event: event, context: {})).
      to eq ({
        :body => 'Reqests should be posted to export.csv',
        :statusCode => 200
      })
  end
end

