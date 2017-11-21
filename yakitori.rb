require 'net/http'
require 'time'
require 'esa'
require 'redis'
require 'json'

REDIS_URL = ENV['REDISTOGO_URL'] || 'redis://127.0.0.1:6379'
REDIS_KEY = ENV['REDIS_KEY'] || 'esa_posts'
LOAD_PER_PAGE = ENV['LOAD_PER_PAGE'] || 100

ESA_ACCESS_TOKEN = ENV['ESA_ACCESS_TOKEN']
TEAM = ENV['ESA_TEAM_NAME']
SLACK_ENDPOINT = ENV['SLACK_ENDPOINT']

# 重み付け定数
STAR_GRAVITY = 1.0
COMMENT_GRAVITY = 1.2
WATCHERS_GRAVITY = 0.2
GRAVITY = 1.5

client = Esa::Client.new(access_token: ESA_ACCESS_TOKEN, current_team: TEAM)

page = 1
posts_buffer = []

while true do
  puts "[LOG] Page #{page} start."
  response = client.posts({:page => page, :per_page => LOAD_PER_PAGE}).body
  if response['error']
    puts "[ERROR] #{response['error']} : #{response['message']}"
    exit
  end

  posts = response['posts'] || []
  posts.each do |post|
    number = post['number']
    full_title = post['full_name']
    created_at = post['created_at']
    comments_count = post['comments_count']
    star_count = post['stargazers_count']
    watchers_count = post['watchers_count']
    user = post['created_by']
    url = post['url']

    # スコア計算
    time_diff = Time.now - Time.parse(created_at)
    duration_hour = time_diff / (60 * 60)
    point = COMMENT_GRAVITY * comments_count + STAR_GRAVITY * star_count + WATCHERS_GRAVITY * watchers_count
    score = (point - 1.0) / ((duration_hour + 2.0) ** GRAVITY)

    posts_buffer << {
      :full_title => full_title,
      :user => user,
      :comments_count => comments_count,
      :star_count => star_count,
      :watchers_count => watchers_count,
      :url => url,
      :score => score,
      :created_at => created_at
    }
  end

  puts "[LOG] Page #{page} end."

  next_page = response['next_page']
  unless next_page
    break
  end

  page += 1
end

result_posts = posts_buffer.sort_by { |v| -v[:score] }

## Redisに保存
puts "[LOG] Start save to redist"
redis = Redis.new(:url => REDIS_URL)
redis.set(REDIS_KEY, result_posts.take(30).to_json)
puts "[LOG] End save to redist"
