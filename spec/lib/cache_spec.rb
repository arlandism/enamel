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
    Enamel::Backend.stub(:response).with(test_env).and_return({ttl: 20, resp: backend_response})
    expect(Enamel::Cache.response(test_env)).to eq([200, {"X-Enamel" => "miss"}, "OK"])
  end

  it "keeps responses in the cache" do
    now = Time.now
    test_env = { "REQUEST_URI" => "/foo" }
    backend_response = [200, {}, "OK"]
    Time.stub(:now).and_return(now)
    Enamel::Backend.stub(:response).with(test_env).and_return({ttl: 20, resp: backend_response})
    Enamel::Cache.response(test_env)
    response_age = 5
    Time.stub(:now).and_return(now + response_age)
    expect(Enamel::Cache.response(test_env)).to eq([200, {"X-Enamel" => "hit", "X-Enamel-Age" => response_age.to_s}, "OK"])
  end

  xit "doesn't hit the backend if it has cached responses" do
    now = Time.now
    test_env = { "REQUEST_URI" => "/foo" }
    backend_response = [200, {}, "OK"]
    ttl = 5
    expect(Enamel::Backend).to receive(:response).with(test_env).and_return({ttl: ttl, resp: backend_response})
    Enamel::Cache.response(test_env)
    Time.stub(:now).and_return(now + ttl)
    expect(Enamel::Backend).to receive(:response).exactly(0).times
    Enamel::Cache.response(test_env)
  end

  xit "expires responses" do
    now = Time.now
    test_env = { "REQUEST_URI" => "/foo" }
    backend_response = [200, {}, "New stuff"]
    Time.stub(:now).and_return(now)
    Enamel::Backend.stub(:response).with(test_env).and_return({ttl: 5, resp: backend_response})
    Enamel::Cache.response(test_env)
    response_age = 5
    Time.stub(:now).and_return(now + response_age)
    expect(Enamel::Cache.response(test_env)).to eq([200, {"X-Enamel" => "miss"}, "New stuff"])
  end

end
