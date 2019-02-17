module Routes
  class Disks < Sinatra::Base
    before do
      content_type :json
    end

    # List a disk
    get '/disks/:guid' do
      #TODO
    end

    # Create a disk
    post '/disks' do
      #TODO
    end

    # Delete a disk
    delete '/disks/:uuid' do
      #TODO
    end

    private

    def data
      @data ||= JSON.parse(request.body.read, symbolize_names: true)
    end
  end
end
