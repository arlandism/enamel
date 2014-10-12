require "rspec"
require_relative "../../enamel/lib/cache"
require_relative "../../enamel/lib/backend"

describe Enamel::Cache do

  before do
    Enamel::Cache.purge
  end

  it "caches by request" do
    test_env = { "REQUEST_URI" => "/foo" }
    backend_response = [200, {}, "OK"]
    allow(Enamel::Backend).to receive(:response).with(test_env).and_return({ttl: 20, resp: backend_response})
    expect(Enamel::Cache.response(test_env)).to eq([200, {"X-Enamel" => "miss"}, "OK"])
  end

  it "keeps responses in the cache" do
    now = Time.now
    test_env = { "REQUEST_URI" => "/foo" }
    backend_response = [200, {}, "OK"]
    allow(Time).to receive(:now).and_return(now)
    allow(Enamel::Backend).to receive(:response).with(test_env).and_return({ttl: 20, resp: backend_response})
    Enamel::Cache.response(test_env)
    response_age = 5
    allow(Time).to receive(:now).and_return(now + response_age)
    expect(Enamel::Cache.response(test_env)).to eq([200, {"X-Enamel" => "hit"}, "OK"])
  end

  it "doesn't hit the backend if it has cached responses" do
    now = Time.now
    test_env = { "REQUEST_URI" => "/foo" }
    backend_response = [200, {}, "OK"]
    ttl = 5
    allow(Enamel::Backend).to receive(:response).with(test_env).and_return(
      {ttl: ttl, resp: backend_response}
    )
    Enamel::Cache.response(test_env)
    allow(Time).to receive(:now).and_return(now + ttl)
    expect(Enamel::Backend).not_to receive(:response)
    Enamel::Cache.response(test_env)
  end

  it "expires responses" do
    now = Time.now
    test_env = { "REQUEST_URI" => "/foo" }
    backend_response = [200, {}, "New stuff"]
    ttl = 5
    allow(Time).to receive(:now).and_return(now)
    allow(Enamel::Backend).to receive(:response).with(test_env).and_return({ttl: ttl, resp: backend_response})
    Enamel::Cache.response(test_env)
    allow(Time).to receive(:now).and_return(now + ttl + 1)
    expect(Enamel::Cache.response(test_env)).to eq([200, {"X-Enamel" => "miss"}, "New stuff"])
  end

end
