# Usage:
#
# rake import:stack_overflow:users
# rake import:stack_overflow:posts
# rake import:stack_overflow:comments
# rake import:stack_overflow:votes

namespace :import do
  namespace :stack_exchange do
    desc "Import Stack Exchange users"
    task :users, [:url] => :environment do |_, args|
      processor = StackExchange::Processor::Users.new

      processor.process('tmp/data/android_dump/Users.xml')
    end

    desc "Import Stack Exchange posts"
    task :posts, [:url] => :environment do |_, args|
      processor = StackExchange::Processor::Posts.new

      processor.process('tmp/data/android_dump/Posts.xml')
    end

    desc "Import Stack Exchange comments"
    task :comments, [:url] => :environment do |_, args|
      processor = StackExchange::Processor::Comments.new

      processor.process('tmp/data/android_dump/Comments.xml')
    end

    desc "Import Stack Exchange votes"
    task :votes, [:url] => :environment do |_, args|
      processor = StackExchange::Processor::Votes.new

      processor.process('tmp/data/android_dump/Votes.xml')
    end

    desc "Import Stack Exchange votes"
    task :post_history, [:url] => :environment do |_, args|
      processor = StackExchange::Processor::PostHistory.new

      processor.process('tmp/data/android_dump/PostHistory.xml')
    end

    desc "Import Stack Exchange data"
    task :all, [:url] => :environment do |_, args|
      Rake::Task['import:stack_exchange:users'].invoke
      Rake::Task['import:stack_exchange:posts'].invoke
      Rake::Task['import:stack_exchange:comments'].invoke
      Rake::Task['import:stack_exchange:votes'].invoke
      Rake::Task['import:stack_exchange:post_history'].invoke
    end
  end
end



