module Yakitori
  # 重み付け定数による計算でホットエントリ度合いを算出
  module WeightingCalculator
    STAR_GRAVITY = 1.0
    COMMENT_GRAVITY = 1.2
    WATCHERS_GRAVITY = 0.2
    GRAVITY = 1.5

    class << self
      def calc(post)
        created_at = post['created_at']
        watchers_count = post['watchers_count']
        star_count = post['stargazers_count']
        comments_count = post['comments_count']

        # スコア計算
        time_diff = Time.now - Time.parse(created_at)
        duration_hour = time_diff / (60 * 60) # 1 min. * 60

        point =
          [
            COMMENT_GRAVITY * comments_count,
            STAR_GRAVITY * star_count,
            WATCHERS_GRAVITY * watchers_count
          ].reduce(:+)

        (point - 1.0) / ((duration_hour + 2.0)**GRAVITY) # score
      end
    end
  end
end
