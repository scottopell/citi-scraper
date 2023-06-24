until ruby scrape.rb; do
  echo "Scraper crashed with exit code $?.  Respawning.." >&2
  sleep 1
done
