require 'sinatra'
require 'haml'
require 'sass'
require 'couchrest'
require 'fighter'

configure do
  server = CouchRest::Server.new 'manko.qubes.org:5984'
  set :db, CouchRest::Database.new(server, 'mma-stats-dev')
end

helpers do

  def scrape_sherdog id
    f = Fighter.new "http://www.sherdog.com/fighter/#{id}"
    db = settings.db

    response = db.save_doc({
      "_id" => f.id,
      "sherdog_url" => f.url,
      "profile" => f.profile,
      "record" => f.record,
      "type" => "fighter"
    })

    f_doc = db.get response['id']
    db.put_attachment f_doc, 'picture', f.picture, :content_type => 'image/jpeg'
    f_doc
  end

end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/' do
  haml :index
end

get '/fighter/?' do
  @fighters = settings.db.view("fighter/names")["rows"]
  haml :fighter_index
end

get '/fighter/:id/?' do |id|

  f = begin
        settings.db.get id
      rescue RestClient::ResourceNotFound => e
        scrape_sherdog id
      end

  @title = f['profile']['name']
  locals = f.inject({}) { |acc, (k,v)| acc[k.to_sym] = v; acc }
  locals[:picture_url] = "http://#{f.uri}/picture"
  haml :fighter, :locals => locals
end

get '/event/?' do
  not_found
end
