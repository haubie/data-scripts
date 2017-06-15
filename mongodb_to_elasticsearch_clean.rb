require "mongo"
require "elasticsearch"
require "json"
require "ruby-progressbar"
require "paint"

# == Configuration =====================================================

MONGO_SERVER 			= "mongodb://127.0.0.1:27017"
MONGO_DATABASE_NAME 	= ""
MONGO_COLLECTION_NAME 	= ""

ELASTICSEARCH_INDEX 	= ""
ELASTICSEARCH_TYPE		= ""

# ======================================================================

puts "\nSimple MongoDB to Elasticsearch migrator\n"

# Database (Mongo)
mongo_client = Mongo::Client.new(MONGO_SERVER, :database => MONGO_DATABASE_NAME)
mongo_collection = mongo_client[MONGO_COLLECTION_NAME]

# Search index (Elasticsearch)
elasticsearch_client = Elasticsearch::Client.new log: true, reload_on_failure: true

# User notice
puts "Simple MongoDB to Elasticsearch migrator"

total_documents = mongo_collection.find.count

puts Paint['Migrating #{total_documents} documents from MongoDB.', :green, :bright]
 
progressbar = ProgressBar.create( :title => "Documents",
					:format         => "%a %b\u{15E7}%i %p%% %t",
                    :progress_mark  => ' ',
                    :remainder_mark => "\u{FF65}",
                    :starting_at    => 0,
                    :total => total_documents)


# Iterate through MongoDB database, and add to elasticsearch
mongo_collection.find.each do |document|

	# _id is a reserved metadata field in Elasticsearch. This renames the Mongodb _id field to mongo_id
	document['mongo_id'] = document.delete('_id')
	processed_document = document.to_json

	#puts processed_document
	elasticsearch_client.index  index: ELASTICSEARCH_INDEX, type: ELASTICSEARCH_TYPE, body: processed_document

	progressbar.increment

end

puts "Migration script complete."
