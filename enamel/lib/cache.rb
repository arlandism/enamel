module Enamel

  class Cache

    STORE = {}
    HIT_HEADER =  {"X-Enamel" => "hit"}
    MISS_HEADER = {"X-Enamel" => "miss"}

    def self.response(env)
      request_uri = env["REQUEST_URI"]
      if STORE.include?(request_uri) && !expired?(request_uri)
        response = STORE[request_uri]
        response[:resp][1].merge!(HIT_HEADER)
      else
        response = Backend.response(env)
        response[:resp][1].merge!(MISS_HEADER)
        record(request_uri, response[:ttl], response)
      end
      response[:resp]
    end

    def self.record(req, ttl, resp)
      STORE[req] = {
        :ttl => ttl,
        :recorded_at => Time.now,
        :resp => resp[:resp]
      }
    end

    def self.purge
      STORE.clear
    end

    def self.expired?(resource)
      ttl = STORE[resource][:ttl] || 0
      recorded_at = STORE[resource][:recorded_at]
      ttl < Time.now - recorded_at
    end
  end
end
