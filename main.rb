require 'json'
require 'redis'
require_relative 'lib/yakitori'

REDIS_URL = (ENV['REDIS_URL'] || 'redis://127.0.0.1:6379').freeze
REDIS_KEY = (ENV['REDIS_KEY'] || 'esa_posts').freeze

yakitori = ::Yakitori::Client.new
result_posts = yakitori.burn

# Redisに保存
redis = Redis.new(url: REDIS_URL)
redis.set(REDIS_KEY, result_posts.to_json)
