module Enamel

  class Cache

    STORE = []

    def self.response(env)
      backend_response = Backend.response(env)[:resp]
      if STORE.include?(env["REQUEST_URI"])
        backend_response[1].merge!("X-Enamel" => "hit", "X-Enamel-Age" => "5")
      else
        backend_response[1].merge!("X-Enamel" => "miss")
      end
      record(env["REQUEST_URI"])
      backend_response
    end

    def self.record(req)
      STORE << req
    end

    def self.purge
      STORE.clear
    end
  end

end
