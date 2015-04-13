class Powerschool::District < Powerschool::Client

  domain ENDPOINT
  get :all, "/district" do |request|
    puts request.inspect
  end
end

