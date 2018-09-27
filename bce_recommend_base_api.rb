require 'openssl';
require 'httparty'

module Baidu
  class BceRecommendBaseApi
    include HTTParty
    attr_accessor :access_key_id, :secret_access_key

    ESCAPE_MAP = {
            '+': '%20',
            '!': '%21',
            '\'': '%27',
            '(': '%28',
            ')': '%29',
            '*': '%2A'
        }


    JSON_FORMAT = 'application/json; charset=utf-8'
    debug_output $stdout

    def get_http_method
      raise 'implemented get_http_method in sub-class'
    end

    def get_host
      raise 'implemented get_host in sub-class'
    end

    def initialize(access_key_id = nil, secret_access_key = nil)
      @access_key_id = access_key_id||BaiduSetting.brs_id
      @secret_access_key = secret_access_key||BaiduSetting.brs_key
      # @access_key_id = 'my_ak'
      # @secret_access_key = 'my_sk'
    end

    def signature(authStringPref, canonicalRequestStr)
      key = signing_key(authStringPref)
      hmac_sha256_hex(key, canonicalRequestStr)
    end

    def authStringPrefix(timestamp, expirationPeriodInSeconds)
      authStringPrefix = "bce-auth-v1/#{@access_key_id}/#{timestamp}/#{expirationPeriodInSeconds}"
    end

    def signing_key(authStringPref)
      hmac_sha256_hex(@secret_access_key, authStringPref)
    end


    def uriencode(uri)
      uri = uri.gsub(/[^a-zA-A0-9\-\._~]/i) { |c| URI.encode_www_form_component(c) }
      
      if uri.present?
        uri = uri.gsub(/[!'\(\)\*\+]/i) { |c| ESCAPE_MAP[c.to_sym]}
      end
      uri
    end

    def hmac_sha256_hex(key, data)
      OpenSSL::HMAC.hexdigest("SHA256", key, data)
    end

    def canonicalRequest(httpMethod, canonicalPath, queryParams, canonicalQueryHeaders)
    canonicalURI = uriencode(canonicalPath).gsub("%2F", "\/")
    canonicalURI = "/#{canonicalURI}" unless canonicalURI.start_with?("/")
    canonicalQueryString = queryParams.map{|k, v| "#{uriencode(k.to_s)}=#{uriencode(v.to_s)}"}.sort.join("&")
    Rails.logger.info "#{httpMethod}\n#{canonicalURI}\n#{canonicalQueryString}\n#{canonicalQueryHeaders}"
    "#{httpMethod.upcase}\n#{canonicalURI}\n#{canonicalQueryString}\n#{canonicalQueryHeaders}"
  end

    
    def send_request(method_path, queryParams = {}, meta_data = {}, headers = nil)
      timestamp = Time.now.utc.iso8601
      expirationPeriodInSeconds = 1800
      body = meta_data.to_json

      if headers.blank?
        headers = {
          "Host" => get_host().strip,
          "Content-Type" => JSON_FORMAT.strip,
          "x-bce-date": timestamp,
          "User-Agent": "bce-sdk-python//2.7.14 (default, Sep 25 2017, 09:53:22) [GCC 4.2.1 Compatible Apple LLVM 9.0.0 (clang-900.0.37)]/darwin"
        }
      end

      canonicalHeaders = headers.select do |k, v| 
        v.present? && (['host', 'content-length', 'content-type', 'content-md5'].include?(k.to_s.downcase) || k.to_s.downcase.start_with?('x-bce-'))
      end

      canonicalQueryHeaders = canonicalHeaders.map{|k, v| "#{uriencode(k.to_s.downcase)}:#{uriencode(v.to_s.strip)}"}.sort.join("\n")
      canonicalRequestStr = canonicalRequest(get_http_method, method_path, queryParams, canonicalQueryHeaders)
      authStringPref = authStringPrefix(timestamp, expirationPeriodInSeconds)
      sig = signature(authStringPref, canonicalRequestStr)
      signedHeaders = canonicalHeaders.map{|k, v| k.to_s.downcase}.sort.join(";")
      
      # Rails.logger.info options

      response = self.class.send(get_http_method, method_path, :body => body,
        :headers => headers.merge({
          "Authorization" => "#{authStringPref}/#{signedHeaders}/#{sig}"
        }))

      
      Rails.logger.info response.inspect
      result = response.parsed_response
      # if result[:status] == 200
      #   result[:result]
      # else
      #   raise "send request failed, #{result.inspect}"
      # end
    end
  end
end