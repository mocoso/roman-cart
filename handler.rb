require 'json'
require 'rack'
require 'base64'
require_relative 'web'

def hello(event:, context:)
  # Check if the body is base64 encoded. If it is, try to decode it
  if event["isBase64Encoded"]
    body = Base64.decode64(event['body'])
  else
    body = event['body']
  end
  # Rack expects the querystring in plain text, not a hash
  querystring = Rack::Utils.build_query(event['queryStringParameters']) if event['queryStringParameters']
  # Environment required by Rack (http://www.rubydoc.info/github/rack/rack/file/SPEC)
  env = {
    "REQUEST_METHOD" => event['httpMethod'],
    "SCRIPT_NAME" => "",
    "PATH_INFO" => event['path'] || "",
    "QUERY_STRING" => querystring || "",
    "SERVER_NAME" => "localhost",
    "SERVER_PORT" => 443,
    "CONTENT_TYPE" => event['headers']['content-type'],

    "rack.version" => Rack::VERSION,
    "rack.url_scheme" => "https",
    "rack.input" => StringIO.new(body || ""),
    "rack.errors" => $stderr,
  }
  # Pass request headers to Rack if they are available
  unless event['headers'].nil?
    event['headers'].each{ |key, value| env["HTTP_#{key}"] = value }
  end

  begin
    # Response from Rack must have status, headers and body
    status, _, body = Sinatra::Application.call(env)

    # body is an array. We simply combine all the items to a single string
    body_content = ""
    body.each do |item|
      body_content += item.to_s
    end

    return { :body => body_content, :statusCode => status } 
  end
end
