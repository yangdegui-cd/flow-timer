pkill -f resque
bundle exec rake resque:workers QUEUE='*'  COUNT=3 ENV=development  BACKGROUND=yes
bundle exec rake resque:scheduler BACKGROUND=yes
