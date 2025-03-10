# frozen_string_literal: true

class RequestFaker
  attr_reader :params, :content_length, :body, :remote_ip, :original_url, :user_agent, :cookies, :referer, :headers

  def initialize(**options) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    @params = options[:params] || {}
    @headers = options[:headers] || {}
    @content_length = options[:content_length] || 10
    @body = options[:body] || StringIO.new('fake')
    @remote_ip = options[:remote_ip] || '127.0.0.1'
    @original_url = options[:original_url] || '/'
    @user_agent = options[:user_agent] || 'Agent/Fake'
    @cookies = options[:cookies] || {}
    @referer = options[:referer] || 'example.com'

    @options = options
  end
end
