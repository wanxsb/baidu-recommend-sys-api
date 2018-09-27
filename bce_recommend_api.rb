module Baidu
  class BceRecommendApi < BceRecommendBaseApi
    HOST = 'recapi.bj.baidubce.com'
    base_uri  "https://#{HOST}"
    HTTP_METHOD = :post

    def get_http_method
      HTTP_METHOD
    end

    def get_host
      HOST
    end

    def personal(base_user, channel, device_info, ip, options = {})
        url = options[:url]
        referrer = options[:referrer]
        user_agent = options[:user_agent]
        trace_id = options[:trace_id]
        count = options[:count]

            # site: self.site_obj(channel.station, url, referrer),
        device_info.deep_symbolize_keys!
        body = {
            id: self.request_id,
            user: self.user_obj(base_user),
            app: self.app_obj(base_user.station, device_info),
            device: self.device_obj(device_info, ip, user_agent),
            trace_id: trace_id,
            candidate_channels: self.candidate_channels_obj(channel),
            blocked_items: self.blocked_items_obj(base_user)
        }.delete_if { |k, v| v.nil? }

        send_request("/v2/rec/personal", {}, body)
    end

    def relevant(station, device_info, base_article_id, ip, options = {})
        url = options[:url]
        referrer = options[:referrer]
        user_agent = options[:user_agent]
        trace_id = options[:trace_id]
        count = options[:count]
        base_user = options[:base_user]
        if device_info.present? 
            body = {
                id: self.request_id,
                user: self.user_obj(base_user),
                app: self.app_obj(base_user.station, device_info),
                device: self.device_obj(device_info, ip, user_agent),
                trace_id: trace_id,
                base_item: "#{base_article_id}",
                candidate_channels: [],
                count: options[:count],
                blocked_items: self.blocked_items_obj(base_user)
            }.delete_if { |k, v| v.nil? }
        else
            body = {
                id: self.request_id,
                user: {id: options[:web_user_uniq_id]},
                site: self.site_obj(station, url, referrer),
                device: self.device_obj(device_info, ip, user_agent),
                trace_id: trace_id,
                base_item: "#{base_article_id}",
                candidate_channels: [],
                count: options[:count],
                blocked_items: self.blocked_items_obj(base_user)
            }.delete_if { |k, v| v.nil? }
        end
        send_request("/v2/rec/relevant", {}, body)
    end

    def top
        send_request("/v2/rec/top", {}, body)
    end

    
    def request_id
        (DateTime.now.to_f*1000000).round.to_s
    end

    def user_obj(base_user)
        {
            id: base_user.uniq_id,
            yob: base_user.birthday.present? ?  base_user.birthday.year : nil,
            gender: base_user.gender.present? ? nil : (base_user.is_male? ? 'M' : 'F')
        }.delete_if { |k, v| v.nil? }
    end

    def site_obj(station, url, referrer)
        {
            name: station.name,
            domain: station.share_domain,
            page: url,
            ref: referrer,
            keywords: []
        }.delete_if { |k, v| v.nil? }
    end

    def app_obj(station, device_info)
       {
            name: station.name,
            bundle: device_info[:bundle_id],
            domain: station.share_domain,
            ver: device_info[:version],
            keywords: []
        }.delete_if { |k, v| v.nil? }
    end

    def device_obj(device_info, ip, user_agent=nil)
        device_type = ((device_info && device_info[:bundle_id])||(user_agent.present? && user_agent.downcase.include?('mobile'))) ? :phone : :unknown
        device_type_code = {
            :unknown => 0,
            :pc => 1,
            :phone => 2,
            :tablet => 3
        }[device_type]

        os = :unknown
        if device_info && device_info[:os].present?
            os = device_info[:os].downcase.to_sym
        elsif user_agent.present? && user_agent.downcase.include?('mac')
            os = :macos
        elsif user_agent.present? && user_agent.downcase.include?('linux')
            os = :linux
        elsif user_agent.present? && user_agent.downcase.include?('windows')
            os = :windows
        end
        os_code = {
            :unknown => 0,
            :windows => 1,
            :macos => 2,
            :linux => 3,
            :ios => 4,
            :android => 5
        }[os]

        network = :unknown
        if device_info && device_info[:network].present?
            network = device_info[:network].downcase.to_sym
        end
        network_code = {
            :unknown => 0,
            :wifi => 1,
            :'2g' => 2,
            :'3g' => 3,
            :'4g' => 4,
            :earthnet => 5
        }[network]
        {
            ua: user_agent||device_info[:user_agent],
            ip: ip,
            device_type: device_type_code,
            make: device_info.present? ? device_info[:manufacturer] : nil,
            model: device_info.present? ? device_info[:model] : nil,
            os: os_code,
            osv: (device_info.present? && device_info[:os].present?) ? device_info[:system_version] : nil,
            h: (device_info && device_info[:height].present?) ? device_info[:height] : nil,
            w: (device_info && device_info[:width].present?) ? device_info[:width] : nil,
            carrier: nil,
            connection_type: network_code,
            imei: device_info && device_info[:imei].present? ? device_info[:imei] : nil,
            idfa: device_info && device_info[:idfa].present? ? device_info[:idfa] : nil,
            android_id: device_info && device_info[:android_id].present? ? device_info[:android_id] : nil,
            mac: device_info && device_info[:mac].present? ? device_info[:mac] : nil,
        }.delete_if { |k, v| v.nil? }
    end

    def candidate_channels_obj(channel)
        channel.meta_data
    end

    def blocked_items_obj(base_user)
        #TODO: 过滤用户不喜欢的文章和话题
        []
    end
  end
end