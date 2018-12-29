require_relative '../handler'

describe 'hello' do
  let(:event) { {
    'headers' => {},
    'httpMethod' => 'GET',
    'path' => '/'
  } }

  specify 'returns hello response' do
    expect(hello(event: event, context: {})).
      to eq ({
        :body => 'Reqests should be posted to export.csv',
        :statusCode => 200
      })
  end
end

