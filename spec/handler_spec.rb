require_relative '../handler'

describe 'hello' do
  specify 'returns hello response' do
    expect(hello(event: {}, context: {})).
      to eq ({
        :body => '"Go Serverless v1.0! Your function executed successfully!"',
        :statusCode => 200
      })
  end
end

