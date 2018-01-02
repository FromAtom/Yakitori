module Yakitori
  # Esa に問い合わせた全記事に重み付け計算結果を付与する
  class Client
    LOAD_PER_PAGE = ENV['LOAD_PER_PAGE'] || 100

    def initialize
      @esa_client =
        ::Esa::Client.new(
          access_token: ENV['ESA_ACCESS_TOKEN'],
          current_team: ENV['ESA_TEAM_NAME']
        )
    end

    def burn(upto = 30)
      # Note: スコア算出・比較のために1度すべてのポストを取得する必要がある
      posts =
        all_posts.flatten(1).map do |post|
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
        score: score,
        created_at: post['created_at']
      }
    end

    def all_posts(posts = [], current_page_count = 1, next_page = 0)
      return posts unless next_page

      # ページ移動単位で配列に包まれたハッシュが返ってくる
      response =
        @esa_client.posts(page: current_page_count, per_page: LOAD_PER_PAGE).body
      if response['error']
        puts "[ERROR] #{response['error']} : #{response['message']}"
        raise 'Esa Posts Client: Response Error'
      end

      posts << response['posts'] || []

      next_page = response['next_page']

      all_posts(posts, current_page_count + 1, next_page)
    end
  end
end
