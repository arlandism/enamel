module Enamel

  class Cache

    @@store = {}

    def self.response(env)
      if @@store.include?(env["REQUEST_URI"]) && !expired?(env["REQUEST_URI"])
        response = @@store[env["REQUEST_URI"]][:resp]
        response[1].merge!("X-Enamel" => "hit")
      else
        be_response = Backend.response(env)
        response = be_response[:resp]
        response[1].merge!("X-Enamel" => "miss")
        record(env["REQUEST_URI"], be_response[:ttl], be_response)
      end
      response
    end

    def self.record(req, ttl, resp)
      @@store[req] = {
        :resource => req,
        :ttl => ttl,
        :recorded_at => Time.now,
        :resp => resp[:resp]
      }
    end

    def self.purge
      @@store.clear
    end

    def self.expired?(resource)
      ttl = @@store[resource][:ttl] || 0
      recorded_at = @@store[resource][:recorded_at]
      ttl < Time.now - recorded_at
    end
  end

end
