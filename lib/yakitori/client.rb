module Yakitori
  # Esa に問い合わせた全記事に重み付け計算結果を付与する
  class Client
    LOAD_PER_PAGE = ENV['LOAD_PER_PAGE'] || 100
    ESA_ACCESS_TOKEN = ENV['ESA_ACCESS_TOKEN']
    ESA_TEAM_NAME = ENV['ESA_TEAM_NAME']

    def initialize
      @esa_client =
        ::Esa::Client.new(
          access_token: ESA_ACCESS_TOKEN,
          current_team: ESA_TEAM_NAME
        )
    end

    def burn(upto = 30)
      # Note: スコア算出・比較のために1度すべてのポストを取得する必要がある
      posts =
        all_posts.map do |post|
          score =
            ::Yakitori::WeightingCalculator.calc(post)

          composition_to_hash(post, score)
        end

      posts.max_by(upto) { |post| post[:score] }
    end

    private

    # Yakitori で使いたいデータ内容に再構成
    def composition_to_hash(post, score)
      {
        full_title: post['full_name'],
        user: post['created_by'],
        comments_count: post['comments_count'],
        star_count: post['stargazers_count'],
        watchers_count: post['watchers_count'],
        url: post['url'],
        wip: post['wip'],
        score: score,
        created_at: post['created_at']
      }
    end

    def all_posts(posts = [], current_page_count = 1, next_page = 0)
      return posts unless next_page

      # esaのAPIで10,000件を超えるページネーションが制限されている
      if posts.count >= 10000
        return posts
      elsif (posts.count + LOAD_PER_PAGE) >= 10000
        per_page = 10000 - posts.count
      else
        per_page = LOAD_PER_PAGE
      end

      # ページ移動単位で配列に包まれたハッシュが返ってくる
      response =
        @esa_client.posts(page: current_page_count, per_page: per_page).body
      if response['error']
        puts "[ERROR] #{response['error']} : #{response['message']}"
        raise 'Esa Posts Client: Response Error'
      end

      posts.concat(response['posts'] || [])

      all_posts(posts, current_page_count + 1, response['next_page'])
    end
  end
end
