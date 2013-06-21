require 'mongo'
require 'yaml'
include Mongo

mongo_client = MongoClient.new("localhost", 27017)
db = mongo_client.db("mydb")

clients = db["clients"]
tmp_coll = db["tmp"] # we need this simply to get a BSON id, when we insert to it, it'll return the object id

entries = YAML.load_file('data.yml')

p entries

client_ids = entries.map{|p| p['client_id']}.uniq # to make sure we only pass through each client once
client_ids.each do |client_id|
  client_arr = entries.select{|e| e['client_id'] == client_id} # all clients with the same client_id, put them in an array

  client = { # get client info
    "name" => client_arr[0]["client_name"]
  }

  plans = []

  plan_ids = client_arr.map{|p| p['plan_id']}.uniq.compact # get the unique ids of this client's plans, remove nil
  plan_ids.each do |plan_id| # loop through these ids
    plan_arr = client_arr.select{|p| p['plan_id'] == plan_id} # pick the plans with the same id
    plan = { 
      "_id" => tmp_coll.insert("tmp"=>1),
      "name" => plan_arr[0]['plan_name'],
      "product" => {
        "_id" => tmp_coll.insert("tmp"=>1),
        "name" => plan_arr[0]['product_name']
      }
    }

    payments = []
    plan_arr.each do |e|
      if e['amount_paid'] # if there is a payment (otherwise it'd be nil)
        payments << {
          "_id" => tmp_coll.insert("tmp"=>1),
          "amount_paid"=>e['amount_paid']
        }
      end
    end
    plan["payments"] = payments

    plans << plan
  end
  client["plans"] = plans
  clients.insert(client) # insert the record
end
tmp_coll.drop