# Configuration
# https://github.com/elasticsearch/elasticsearch-ruby/tree/5dc6bc61b85cb681b2453e4b9a6afb9a35e1be98/elasticsearch-transport#configuration
Elasticsearch::Model.client = Elasticsearch::Client.new url: DATABASE['elasticsearch']['url'],
                                                        log: DATABASE['elasticsearch']['log'],
                                                        trace: DATABASE['elasticsearch']['trace']

# pagination
# https://github.com/elasticsearch/elasticsearch-rails/tree/master/elasticsearch-model#pagination
Kaminari::Hooks.init
Elasticsearch::Model::Response::Response.__send__ :include, Elasticsearch::Model::Response::Pagination::Kaminari
